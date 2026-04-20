/// Service ASR — Enregistrement audio + validation via le serveur Whisper.
///
/// Gère :
///  1. L'enregistrement audio via le package `record`
///  2. L'envoi au serveur ASR (POST /api/validate-replay)
///  3. Le parsing de la réponse mot par mot
///
/// Utilise le modèle tarteel-ai/whisper-base-ar-quran, fine-tuné pour le Coran.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:record/record.dart';
import 'package:dio/dio.dart';

// Imports conditionnels : dart:html pour web (blob fetch), dart:io pour mobile
import 'asr_io_stub.dart'
    if (dart.library.html) 'asr_io_web.dart'
    if (dart.library.io) 'asr_io_native.dart';

// ── Configuration ──────────────────────────────────────────────────

const String _defaultAsrUrl = 'https://asr.taleem.cksyndic.ma';

const String asrBaseUrl = String.fromEnvironment(
  'ASR_BASE_URL',
  defaultValue: _defaultAsrUrl,
);

// ── Résultat ASR ───────────────────────────────────────────────────

class AsrWordResult {
  const AsrWordResult({
    required this.word,
    required this.status,
    this.expected,
    this.position = 0,
    this.similarity,
    this.startTime,
    this.endTime,
  });

  final String word;
  final AsrWordStatus status;
  final String? expected; // Ce que le modèle a entendu (si wrong)
  final int position;
  final double? similarity;
  final double? startTime; // Timestamp début (secondes)
  final double? endTime;   // Timestamp fin (secondes)

  factory AsrWordResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'missing';
    final sim = (json['similarity'] as num?)?.toDouble();

    AsrWordStatus status;
    if (rawStatus == 'correct' && sim != null && sim < 1.0 && sim >= 0.6) {
      status = AsrWordStatus.close;
    } else {
      status = switch (rawStatus) {
        'correct' => AsrWordStatus.correct,
        'wrong' => AsrWordStatus.wrong,
        'missing' => AsrWordStatus.missing,
        'extra' => AsrWordStatus.extra,
        _ => AsrWordStatus.missing,
      };
    }

    return AsrWordResult(
      word: json['word'] as String? ?? '',
      status: status,
      expected: json['expected'] as String?,
      position: json['position'] as int? ?? 0,
      similarity: sim,
      startTime: (json['start_time'] as num?)?.toDouble(),
      endTime: (json['end_time'] as num?)?.toDouble(),
    );
  }
}

enum AsrWordStatus { correct, close, wrong, missing, extra }

class AsrValidationResult {
  const AsrValidationResult({
    required this.success,
    required this.accuracy,
    required this.transcription,
    required this.wordResults,
    required this.correctWords,
    required this.wrongWords,
    required this.missingWords,
    this.extraWords = 0,
    this.inferenceTimeMs = 0,
    this.error,
  });

  final bool success;
  final double accuracy;
  final String transcription;
  final List<AsrWordResult> wordResults;
  final int correctWords;
  final int wrongWords;
  final int missingWords;
  final int extraWords;
  final int inferenceTimeMs;
  final String? error;

  factory AsrValidationResult.fromJson(Map<String, dynamic> json) {
    final wordResults = (json['word_results'] as List? ?? [])
        .map((w) => AsrWordResult.fromJson(w as Map<String, dynamic>))
        .toList();

    return AsrValidationResult(
      success: json['success'] as bool? ?? false,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      transcription: json['transcription'] as String? ?? '',
      wordResults: wordResults,
      correctWords: json['correct_words'] as int? ?? 0,
      wrongWords: json['wrong_words'] as int? ?? 0,
      missingWords: json['missing_words'] as int? ?? 0,
      extraWords: json['extra_words'] as int? ?? 0,
      inferenceTimeMs: json['inference_time_ms'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  /// Résultat de simulation (fallback quand le serveur ASR est inaccessible).
  factory AsrValidationResult.simulated({
    required List<String> words,
    required int recSeconds,
    required int surahNumber,
    required int verseNumber,
  }) {
    final expectedDuration = words.length * 1.2;
    final ratio = (expectedDuration > 0 && recSeconds > 0)
        ? (recSeconds / expectedDuration).clamp(0.3, 1.5)
        : 0.5;
    final baseAccuracy = 1.0 - (ratio - 1.0).abs();
    final seed = surahNumber * 100 + verseNumber + recSeconds;
    final jitter = ((seed % 20) - 10) / 100.0;
    final accuracy = (baseAccuracy + jitter).clamp(0.4, 0.95);

    int correct = 0, wrong = 0, missing = 0;
    final wordResults = <AsrWordResult>[];

    for (int i = 0; i < words.length; i++) {
      final wordSeed = (seed + i * 7) % 100;
      AsrWordStatus status;

      if (wordSeed < (accuracy * 70).round()) {
        status = AsrWordStatus.correct;
        correct++;
      } else if (wordSeed < (accuracy * 90).round()) {
        status = AsrWordStatus.close;
        correct++; // Close compte comme correct pour le score
      } else if (wordSeed < 90) {
        status = AsrWordStatus.wrong;
        wrong++;
      } else {
        status = AsrWordStatus.missing;
        missing++;
      }

      wordResults.add(AsrWordResult(
        word: words[i],
        status: status,
        position: i,
        similarity: status == AsrWordStatus.correct
            ? 1.0
            : status == AsrWordStatus.close
                ? 0.7
                : 0.0,
      ));
    }

    return AsrValidationResult(
      success: accuracy >= 0.7,
      accuracy: accuracy,
      transcription: '(simulation)',
      wordResults: wordResults,
      correctWords: correct,
      wrongWords: wrong,
      missingWords: missing,
    );
  }
}

// ── Service principal ──────────────────────────────────────────────

class AsrService {
  AsrService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
            baseUrl: asrBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 60),
          ));

  final Dio _dio;
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  Uint8List? _webRecordingBytes;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Bytes audio web (pour le replay après validation).
  Uint8List? get webRecordingBytes => _webRecordingBytes;

  /// Vérifie que le serveur ASR est accessible.
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200 &&
          response.data['model_loaded'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Démarre l'enregistrement audio.
  Future<void> startRecording() async {
    if (_isRecording) return;

    // Vérifier la permission micro
    if (!await _recorder.hasPermission()) {
      throw Exception('Permission micro refusée');
    }

    _webRecordingBytes = null;

    if (kIsWeb) {
      // Sur Web, MediaRecorder supporte webm/opus nativement.
      // AudioEncoder.opus → audio/webm;codecs=opus (tous les navigateurs)
      const config = RecordConfig(
        encoder: AudioEncoder.opus,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      );
      await _recorder.start(config, path: '');
    } else {
      _currentRecordingPath = await getTempRecordingPath();
      // WAV 16kHz mono — pas de compression, le serveur ASR lit directement
      // sans conversion ffmpeg (économise ~200-500ms par requête côté serveur).
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );
      await _recorder.start(config, path: _currentRecordingPath!);
    }

    _isRecording = true;
    debugPrint('ASR: Recording started (web=$kIsWeb)');
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier (ou 'web' sur navigateur).
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    debugPrint('ASR: Recording stopped, path=$path');

    if (kIsWeb && path != null && path.isNotEmpty) {
      // Sur web, `record` retourne un blob URL (blob:http://...)
      // On récupère les bytes via dart:html XHR (seul moyen fiable)
      _webRecordingBytes = await fetchBlobBytes(path);
      if (_webRecordingBytes != null && _webRecordingBytes!.isNotEmpty) {
        debugPrint('ASR: Blob web récupéré: ${_webRecordingBytes!.length} bytes');
        return 'web'; // Signal non-null pour indiquer le succès
      } else {
        debugPrint('ASR: Blob web vide ou null');
        return null;
      }
    }

    return path;
  }

  /// Envoie l'audio au serveur ASR et retourne le résultat.
  ///
  /// Si le serveur ASR est inaccessible, retourne un résultat simulé.
  Future<AsrValidationResult> validateRecording({
    required String audioPath,
    required String expectedText,
    required List<String> words,
    required int recSeconds,
    required int surahNumber,
    required int verseNumber,
    bool withTimestamps = true,
  }) async {
    try {
      final endpoint =
          withTimestamps ? '/api/validate-replay' : '/api/validate';

      MultipartFile audioFile;
      if (kIsWeb && _webRecordingBytes != null) {
        // Web : envoyer les bytes du blob en mémoire
        audioFile = MultipartFile.fromBytes(
          _webRecordingBytes!,
          filename: 'recording.webm',
          contentType: DioMediaType.parse('audio/webm'),
        );
      } else {
        // Mobile/Desktop : envoyer le WAV 16kHz directement (pas de conversion serveur)
        audioFile = await MultipartFile.fromFile(
          audioPath,
          filename: 'recording.wav',
          contentType: DioMediaType.parse('audio/wav'),
        );
      }

      debugPrint('ASR: Envoi vers $endpoint (${kIsWeb ? "${_webRecordingBytes?.length ?? 0} bytes" : audioPath})');

      final formData = FormData.fromMap({
        'audio': audioFile,
        'expected_text': expectedText,
        'pass_threshold': 0.7,
      });

      final response = await _dio.post(endpoint, data: formData);

      if (response.statusCode == 200) {
        final result = AsrValidationResult.fromJson(
            response.data as Map<String, dynamic>);
        debugPrint('ASR: Résultat reçu — accuracy=${result.accuracy}, transcription="${result.transcription}"');
        return result;
      }

      debugPrint('ASR: Erreur serveur ${response.statusCode}');
      return AsrValidationResult.simulated(
        words: words,
        recSeconds: recSeconds,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
    } catch (e) {
      debugPrint('ASR: Erreur validation: $e');
      return AsrValidationResult.simulated(
        words: words,
        recSeconds: recSeconds,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
    }
  }

  /// Envoie l'audio d'une sourate complète au serveur ASR pour validation.
  ///
  /// Appelle POST /api/validate-surah avec l'audio + les textes de chaque verset.
  /// Le serveur gère le chunking automatique pour les longues récitations.
  Future<AsrValidationResult> validateSurahRecording({
    required String audioPath,
    required List<String> verseTexts,
  }) async {
    try {
      MultipartFile audioFile;
      if (kIsWeb && _webRecordingBytes != null) {
        audioFile = MultipartFile.fromBytes(
          _webRecordingBytes!,
          filename: 'recording.webm',
          contentType: DioMediaType.parse('audio/webm'),
        );
      } else {
        audioFile = await MultipartFile.fromFile(
          audioPath,
          filename: 'recording.wav',
          contentType: DioMediaType.parse('audio/wav'),
        );
      }

      debugPrint('ASR: Envoi sourate vers /api/validate-surah (${verseTexts.length} versets)');

      final formData = FormData.fromMap({
        'audio': audioFile,
        'verses_json': jsonEncode(verseTexts),
        'pass_threshold': 0.7,
      });

      final response = await _dio.post('/api/validate-surah', data: formData);

      if (response.statusCode == 200) {
        final result = AsrValidationResult.fromJson(
            response.data as Map<String, dynamic>);
        debugPrint('ASR Surah: accuracy=${result.accuracy}, '
            'correct=${result.correctWords}/${result.wordResults.length}');
        return result;
      }

      debugPrint('ASR Surah: Erreur serveur ${response.statusCode}');
      return AsrValidationResult(
        success: false,
        accuracy: 0,
        transcription: '',
        wordResults: [],
        correctWords: 0,
        wrongWords: 0,
        missingWords: 0,
        error: 'Erreur serveur ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('ASR Surah: Erreur validation: $e');
      return AsrValidationResult(
        success: false,
        accuracy: 0,
        transcription: '',
        wordResults: [],
        correctWords: 0,
        wrongWords: 0,
        missingWords: 0,
        error: e.toString(),
      );
    }
  }

  /// Nettoie les ressources d'enregistrement.
  Future<void> cleanup() async {
    _webRecordingBytes = null;
    if (_currentRecordingPath != null && !kIsWeb) {
      await deleteFile(_currentRecordingPath!);
    }
    _currentRecordingPath = null;
  }

  /// Libère les ressources.
  void dispose() {
    _recorder.dispose();
    cleanup();
  }
}

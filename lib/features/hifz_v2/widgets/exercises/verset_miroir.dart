import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

/// Le Verset Miroir (المرآة) — Récitation + analyse ASR.
///
/// Intègre la mécanique du /replay développée dans le prototype ASR :
/// 1. L'élève récite le verset (enregistrement audio)
/// 2. L'audio est envoyé au serveur ASR pour validation
/// 3. Le résultat mot par mot s'affiche avec code couleur :
///    - Vert : correct (similarité 1.0)
///    - Orange : proche (similarité >= 0.6)
///    - Rouge souligné : erreur
///    - Gris barré : mot oublié
/// 4. L'élève peut réécouter son enregistrement synchronisé
///
/// Ce widget est inline dans le flux — pas de nouvel écran.
class VersetMiroir extends StatefulWidget {
  const VersetMiroir({
    super.key,
    required this.verse,
    required this.onComplete,
    this.asrServerUrl = _defaultAsrUrl,
  });

  final EnrichedVerse verse;
  final void Function(ExerciseResult result) onComplete;
  final String asrServerUrl;

  // URL de production par défaut
  static const String _defaultAsrUrl = 'https://asr.taleem.cksyndic.ma';

  @override
  State<VersetMiroir> createState() => _VersetMiroirState();
}

enum _MiroirPhase { ready, recording, analyzing, result }

class _VersetMiroirState extends State<VersetMiroir> {
  _MiroirPhase _phase = _MiroirPhase.ready;
  final _startTime = DateTime.now();

  // Résultat de l'analyse
  double _accuracy = 0;
  List<_WordAnalysis> _wordResults = [];
  int _correctWords = 0;
  int _closeWords = 0;
  int _wrongWords = 0;
  int _missingWords = 0;

  // Audio replay
  final AudioPlayer _replayPlayer = AudioPlayer();
  bool _isReplaying = false;
  int _activeWordIdx = -1;

  // Timer enregistrement
  Timer? _recTimer;
  int _recSeconds = 0;

  @override
  void dispose() {
    _recTimer?.cancel();
    _replayPlayer.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _phase = _MiroirPhase.recording;
      _recSeconds = 0;
    });
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recSeconds++);
    });
    // Note: l'enregistrement réel utilise record ou flutter_sound
    // Pour le prototype, on simule puis on appelle l'API ASR
  }

  void _stopRecording() {
    _recTimer?.cancel();
    setState(() => _phase = _MiroirPhase.analyzing);
    // Simuler l'envoi au serveur ASR et la réception du résultat
    _analyzeRecitation();
  }

  Future<void> _analyzeRecitation() async {
    // En production : envoyer l'audio au POST /api/validate-replay
    // Pour le prototype Flutter, on simule un résultat basé sur le verset
    //
    // TODO: Intégrer avec le serveur ASR réel :
    // final formData = FormData.fromMap({
    //   'audio': MultipartFile.fromBytes(audioBytes, filename: 'rec.webm'),
    //   'expected_text': widget.verse.textAr,
    // });
    // final response = await dio.post('${widget.asrServerUrl}/api/validate-replay', data: formData);

    await Future.delayed(const Duration(seconds: 2)); // Simule le temps d'inférence

    // Construire le résultat mot par mot
    final words = widget.verse.words;
    _wordResults = List.generate(words.length, (i) {
      // Placeholder : en production, vient de l'API
      return _WordAnalysis(
        word: words[i],
        status: _WordStatus.pending,
        similarity: null,
        heard: null,
        startTime: null,
        endTime: null,
      );
    });

    setState(() {
      _phase = _MiroirPhase.result;
      // Les vrais résultats viendront de l'API
      // Pour l'instant, afficher les mots en "pending" → l'utilisateur doit connecter le serveur ASR
    });
  }

  /// Mise à jour des résultats depuis la réponse API réelle.
  void _applyApiResults(Map<String, dynamic> apiResponse) {
    final wordResults = apiResponse['word_results'] as List;
    final expectedWords = widget.verse.textAr.split(RegExp(r'\s+'));

    _wordResults.clear();
    _correctWords = 0;
    _closeWords = 0;
    _wrongWords = 0;
    _missingWords = 0;

    for (final wr in wordResults) {
      final status = switch (wr['status']) {
        'correct' => _WordStatus.correct,
        'wrong' => _WordStatus.wrong,
        'missing' => _WordStatus.missing,
        'extra' => _WordStatus.extra,
        _ => _WordStatus.pending,
      };

      final sim = (wr['similarity'] as num?)?.toDouble();
      final effectiveStatus = status == _WordStatus.correct && sim != null && sim < 1.0
          ? _WordStatus.close
          : status;

      switch (effectiveStatus) {
        case _WordStatus.correct:
          _correctWords++;
        case _WordStatus.close:
          _closeWords++;
        case _WordStatus.wrong:
          _wrongWords++;
        case _WordStatus.missing:
          _missingWords++;
        default:
          break;
      }

      final pos = wr['position'] as int? ?? -1;
      _wordResults.add(_WordAnalysis(
        word: pos >= 0 && pos < expectedWords.length
            ? expectedWords[pos]
            : wr['word'] as String,
        status: effectiveStatus,
        similarity: sim,
        heard: wr['expected'] as String?,
        startTime: (wr['start_time'] as num?)?.toDouble(),
        endTime: (wr['end_time'] as num?)?.toDouble(),
      ));
    }

    _accuracy = apiResponse['accuracy'] as double;
    setState(() {});
  }

  void _completeExercise() {
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    final score = (_accuracy * 100).round();
    widget.onComplete(ExerciseResult(
      type: ExerciseType.versetMiroir,
      isCorrect: _accuracy >= 0.7,
      responseTimeMs: ms,
      score: score,
      details: '$_correctWords correct, $_wrongWords erreur(s), $_missingWords oublié(s)',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Titre ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_none, size: 16, color: HifzColors.emerald.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Le Verset Miroir',
                style: HifzTypo.sectionTitle(color: HifzColors.emeraldDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Récite puis découvre ton résultat',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 20),

          // ── Contenu selon la phase ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_phase) {
              _MiroirPhase.ready => _buildReady(),
              _MiroirPhase.recording => _buildRecording(),
              _MiroirPhase.analyzing => _buildAnalyzing(),
              _MiroirPhase.result => _buildResult(),
            },
          ),
        ],
      ),
    );
  }

  // ── Phase : Prêt ──
  Widget _buildReady() {
    return Column(
      key: const ValueKey('ready'),
      children: [
        // Verset affiché faiblement (rappel visuel)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: HifzDecor.card,
          child: Text(
            widget.verse.textAr,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: HifzTypo.verse(size: 22, color: HifzColors.textLight),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Récite le verset de mémoire',
          style: HifzTypo.body(color: HifzColors.textMedium),
        ),

        const SizedBox(height: 16),

        // Bouton enregistrement
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HifzColors.emeraldMuted,
              border: Border.all(color: HifzColors.emerald, width: 3),
            ),
            child: const Icon(Icons.mic, size: 36, color: HifzColors.emerald),
          ),
        ),
      ],
    );
  }

  // ── Phase : Enregistrement ──
  Widget _buildRecording() {
    final minutes = _recSeconds ~/ 60;
    final secs = _recSeconds % 60;

    return Column(
      key: const ValueKey('recording'),
      children: [
        // Timer
        Text(
          '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: HifzTypo.score(color: HifzColors.wrong),
        ),

        const SizedBox(height: 16),

        Text(
          'Récite maintenant...',
          style: HifzTypo.body(color: HifzColors.textMedium),
        ),

        const SizedBox(height: 24),

        // Bouton stop
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HifzColors.wrong.withOpacity(0.15),
              border: Border.all(color: HifzColors.wrong, width: 3),
            ),
            child: const Icon(Icons.stop, size: 36, color: HifzColors.wrong),
          ),
        ),
      ],
    );
  }

  // ── Phase : Analyse ──
  Widget _buildAnalyzing() {
    return Column(
      key: const ValueKey('analyzing'),
      children: [
        const SizedBox(height: 40),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(HifzColors.emerald),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Analyse en cours...',
          style: HifzTypo.body(color: HifzColors.textMedium),
        ),
      ],
    );
  }

  // ── Phase : Résultat ──
  Widget _buildResult() {
    return Column(
      key: const ValueKey('result'),
      children: [
        // Score
        Text(
          '${(_accuracy * 100).round()}%',
          style: HifzTypo.score(
            color: _accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _accuracy >= 0.7 ? 'Bien récité' : 'À retravailler',
          style: HifzTypo.body(
            color: _accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),

        const SizedBox(height: 16),

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip('$_correctWords', 'correct', HifzColors.correct),
            if (_closeWords > 0) _StatChip('$_closeWords', 'proche', HifzColors.close),
            _StatChip('$_wrongWords', 'erreur', HifzColors.wrong),
            _StatChip('$_missingWords', 'oublié', HifzColors.missing),
          ],
        ),

        const SizedBox(height: 20),

        // Verset mot par mot coloré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: HifzDecor.card,
          child: Wrap(
            alignment: WrapAlignment.center,
            textDirection: TextDirection.rtl,
            spacing: 4,
            runSpacing: 16,
            children: _wordResults.asMap().entries.map((entry) {
              final wa = entry.value;
              return _buildWordResult(wa);
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Bouton continuer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeExercise,
            style: HifzDecor.primaryButton,
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  Widget _buildWordResult(_WordAnalysis wa) {
    Color textColor;
    TextDecoration? decoration;

    switch (wa.status) {
      case _WordStatus.correct:
        textColor = HifzColors.correct;
        break;
      case _WordStatus.close:
        textColor = HifzColors.close;
        break;
      case _WordStatus.wrong:
        textColor = HifzColors.wrong;
        decoration = TextDecoration.underline;
        break;
      case _WordStatus.missing:
        textColor = HifzColors.missing;
        decoration = TextDecoration.lineThrough;
        break;
      default:
        textColor = HifzColors.textDark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          wa.word,
          style: HifzTypo.verse(size: 24, color: textColor).copyWith(
            decoration: decoration,
            decorationColor: textColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        // Mot entendu sous les erreurs
        if (wa.heard != null && (wa.status == _WordStatus.wrong || wa.status == _WordStatus.close))
          Text(
            wa.heard!,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11,
              color: HifzColors.textLight,
            ),
            textDirection: TextDirection.rtl,
          ),
      ],
    );
  }
}

// ── Helpers ──

class _StatChip extends StatelessWidget {
  const _StatChip(this.count, this.label, this.color);
  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

enum _WordStatus { correct, close, wrong, missing, extra, pending }

class _WordAnalysis {
  const _WordAnalysis({
    required this.word,
    required this.status,
    this.similarity,
    this.heard,
    this.startTime,
    this.endTime,
  });

  final String word;
  final _WordStatus status;
  final double? similarity;
  final String? heard;    // Ce que le modèle a entendu
  final double? startTime;
  final double? endTime;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';
import '../../providers/hifz_v2_provider.dart';
import '../../services/asr_service.dart';

/// Le Verset Miroir (المرآة) — Récitation + analyse ASR.
///
/// 1. L'élève récite le verset (enregistrement audio réel)
/// 2. L'audio est envoyé au serveur ASR pour validation
/// 3. Le résultat mot par mot s'affiche avec code couleur
/// 4. Fallback simulation si le serveur ASR est inaccessible
class VersetMiroir extends ConsumerStatefulWidget {
  const VersetMiroir({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(ExerciseResult result) onComplete;

  @override
  ConsumerState<VersetMiroir> createState() => _VersetMiroirState();
}

enum _MiroirPhase { ready, recording, analyzing, result }

class _VersetMiroirState extends ConsumerState<VersetMiroir> {
  _MiroirPhase _phase = _MiroirPhase.ready;
  final _startTime = DateTime.now();

  // Résultat de l'analyse
  AsrValidationResult? _asrResult;

  // Timer enregistrement
  Timer? _recTimer;
  int _recSeconds = 0;

  // Audio replay
  final AudioPlayer _replayPlayer = AudioPlayer();

  @override
  void dispose() {
    _recTimer?.cancel();
    _replayPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final asr = ref.read(asrServiceProvider);

    try {
      await asr.startRecording();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur micro : $e')),
      );
      return;
    }

    setState(() {
      _phase = _MiroirPhase.recording;
      _recSeconds = 0;
    });

    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recSeconds++);
      // Auto-stop après 30 secondes
      if (_recSeconds >= 30) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _recTimer?.cancel();
    if (_phase != _MiroirPhase.recording) return;

    setState(() => _phase = _MiroirPhase.analyzing);

    final asr = ref.read(asrServiceProvider);
    final audioPath = await asr.stopRecording();

    if (audioPath == null || audioPath.isEmpty) {
      // Pas de fichier → simulation
      _asrResult = AsrValidationResult.simulated(
        words: widget.verse.words,
        recSeconds: _recSeconds,
        surahNumber: widget.verse.surahNumber,
        verseNumber: widget.verse.verseNumber,
      );
      if (mounted) setState(() => _phase = _MiroirPhase.result);
      return;
    }

    // Envoyer au serveur ASR
    _asrResult = await asr.validateRecording(
      audioPath: audioPath,
      expectedText: widget.verse.textAr,
      words: widget.verse.words,
      recSeconds: _recSeconds,
      surahNumber: widget.verse.surahNumber,
      verseNumber: widget.verse.verseNumber,
    );

    // Nettoyer le fichier temporaire
    await asr.cleanup();

    if (mounted) setState(() => _phase = _MiroirPhase.result);
  }

  void _retry() {
    setState(() {
      _phase = _MiroirPhase.ready;
      _asrResult = null;
      _recSeconds = 0;
    });
  }

  void _completeExercise() {
    final result = _asrResult;
    if (result == null) return;

    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    final score = (result.accuracy * 100).round();

    widget.onComplete(ExerciseResult(
      type: ExerciseType.versetMiroir,
      isCorrect: result.accuracy >= 0.7,
      responseTimeMs: ms,
      score: score,
      details:
          '${result.correctWords} correct, ${result.wrongWords} erreur(s), ${result.missingWords} oublié(s)',
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
              Icon(Icons.mic_none,
                  size: 16, color: HifzColors.emerald.withOpacity(0.7)),
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
    final result = _asrResult;
    if (result == null) return const SizedBox.shrink();

    final accuracy = result.accuracy;
    final isSimulated = result.transcription == '(simulation)';

    return Column(
      key: const ValueKey('result'),
      children: [
        // Score
        Text(
          '${(accuracy * 100).round()}%',
          style: HifzTypo.score(
            color: accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          accuracy >= 0.7 ? 'Bien récité' : 'À retravailler',
          style: HifzTypo.body(
            color: accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),

        // Badge simulation
        if (isSimulated) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HifzColors.goldMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Mode hors-ligne (simulation)',
              style: HifzTypo.body(color: HifzColors.gold).copyWith(fontSize: 11),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip('${result.correctWords}', 'correct', HifzColors.correct),
            _StatChip('${result.wrongWords}', 'erreur', HifzColors.wrong),
            _StatChip('${result.missingWords}', 'oublié', HifzColors.missing),
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
            children: result.wordResults.map((wr) {
              return _buildWordResult(wr);
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Boutons : Réessayer + Continuer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HifzColors.emerald,
              side: const BorderSide(color: HifzColors.emerald),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
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

  Widget _buildWordResult(AsrWordResult wr) {
    Color textColor;
    TextDecoration? decoration;

    switch (wr.status) {
      case AsrWordStatus.correct:
        textColor = HifzColors.correct;
      case AsrWordStatus.close:
        textColor = HifzColors.close;
      case AsrWordStatus.wrong:
        textColor = HifzColors.wrong;
        decoration = TextDecoration.underline;
      case AsrWordStatus.missing:
        textColor = HifzColors.missing;
        decoration = TextDecoration.lineThrough;
      case AsrWordStatus.extra:
        textColor = HifzColors.textLight;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          wr.word,
          style: HifzTypo.verse(size: 24, color: textColor).copyWith(
            decoration: decoration,
            decorationColor: textColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        if (wr.expected != null &&
            (wr.status == AsrWordStatus.wrong ||
                wr.status == AsrWordStatus.close))
          Text(
            wr.expected!,
            style: const TextStyle(
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
          Text(count,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

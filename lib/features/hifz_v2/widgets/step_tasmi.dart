import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../services/asr_service.dart';

/// Étape 4 — TASMI' (تسميع) : Récitation intégrale.
///
/// - L'écran affiche uniquement la référence (pas le texte)
/// - L'élève récite de mémoire
/// - L'audio est envoyé au serveur ASR (validate-replay)
/// - Résultat mot par mot avec timestamps synchronisés
class StepTasmi extends ConsumerStatefulWidget {
  const StepTasmi({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(StepResult result) onComplete;

  @override
  ConsumerState<StepTasmi> createState() => _StepTasmiState();
}

enum _TasmiPhase { prompt, recording, analyzing, replay }

class _StepTasmiState extends ConsumerState<StepTasmi> {
  _TasmiPhase _phase = _TasmiPhase.prompt;
  final _startTime = DateTime.now();

  // Enregistrement
  Timer? _recTimer;
  int _recSeconds = 0;

  // Résultat ASR
  AsrValidationResult? _asrResult;

  // Replay audio
  final AudioPlayer _replayPlayer = AudioPlayer();
  bool _isReplaying = false;
  int _activeWordIdx = -1;
  Timer? _replayTimer;

  @override
  void dispose() {
    _recTimer?.cancel();
    _replayTimer?.cancel();
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
      _phase = _TasmiPhase.recording;
      _recSeconds = 0;
    });

    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recSeconds++);
      if (_recSeconds >= 30) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _recTimer?.cancel();
    if (_phase != _TasmiPhase.recording) return;

    setState(() => _phase = _TasmiPhase.analyzing);

    final asr = ref.read(asrServiceProvider);
    final audioPath = await asr.stopRecording();

    if (audioPath == null || audioPath.isEmpty) {
      _asrResult = AsrValidationResult.simulated(
        words: widget.verse.words,
        recSeconds: _recSeconds,
        surahNumber: widget.verse.surahNumber,
        verseNumber: widget.verse.verseNumber,
      );
      if (mounted) setState(() => _phase = _TasmiPhase.replay);
      return;
    }

    _asrResult = await asr.validateRecording(
      audioPath: audioPath,
      expectedText: widget.verse.textAr,
      words: widget.verse.words,
      recSeconds: _recSeconds,
      surahNumber: widget.verse.surahNumber,
      verseNumber: widget.verse.verseNumber,
      withTimestamps: true,
    );

    await asr.cleanup();
    if (mounted) setState(() => _phase = _TasmiPhase.replay);
  }

  void _retry() {
    setState(() {
      _phase = _TasmiPhase.prompt;
      _asrResult = null;
      _recSeconds = 0;
    });
  }

  void _finish() {
    final result = _asrResult;
    final duration = DateTime.now().difference(_startTime).inSeconds;
    final score = result != null ? (result.accuracy * 100).round() : 0;

    widget.onComplete(StepResult(
      step: WirdStep.tasmi,
      score: score,
      durationSeconds: duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Label ──
          Text('TASMI\'', style: HifzTypo.stepLabel()),
          const SizedBox(height: 4),
          Text(
            'Récitation de mémoire',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
          const SizedBox(height: 28),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_phase) {
              _TasmiPhase.prompt => _buildPrompt(),
              _TasmiPhase.recording => _buildRecording(),
              _TasmiPhase.analyzing => _buildAnalyzing(),
              _TasmiPhase.replay => _buildReplay(),
            },
          ),
        ],
      ),
    );
  }

  // ── Prompt : juste la référence ──
  Widget _buildPrompt() {
    return Column(
      key: const ValueKey('prompt'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: HifzColors.goldMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HifzColors.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.auto_stories, size: 36, color: HifzColors.gold),
              const SizedBox(height: 12),
              Text(
                'Verset ${widget.verse.verseNumber}',
                style: HifzTypo.sectionTitle(color: HifzColors.gold),
              ),
              if (widget.verse.textFr != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.verse.textFr!,
                  textAlign: TextAlign.center,
                  style: HifzTypo.translation(color: HifzColors.textLight),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Récite ce verset de mémoire',
          style: HifzTypo.body(color: HifzColors.textMedium),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HifzColors.emeraldMuted,
              border: Border.all(color: HifzColors.emerald, width: 3),
            ),
            child: const Icon(Icons.mic, size: 40, color: HifzColors.emerald),
          ),
        ),
      ],
    );
  }

  // ── Enregistrement ──
  Widget _buildRecording() {
    final m = _recSeconds ~/ 60;
    final s = _recSeconds % 60;
    return Column(
      key: const ValueKey('recording'),
      children: [
        Text(
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: HifzTypo.score(color: HifzColors.wrong),
        ),
        const SizedBox(height: 8),
        Text('Récite...', style: HifzTypo.body(color: HifzColors.textMedium)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HifzColors.wrong.withOpacity(0.12),
              border: Border.all(color: HifzColors.wrong, width: 3),
            ),
            child: const Icon(Icons.stop, size: 40, color: HifzColors.wrong),
          ),
        ),
      ],
    );
  }

  // ── Analyse ──
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
        Text('Analyse de ta récitation...',
            style: HifzTypo.body(color: HifzColors.textMedium)),
      ],
    );
  }

  // ── Replay avec résultat mot par mot ──
  Widget _buildReplay() {
    final result = _asrResult;
    if (result == null) return const SizedBox.shrink();

    final accuracy = result.accuracy;
    final isSimulated = result.transcription == '(simulation)';

    return Column(
      key: const ValueKey('replay'),
      children: [
        // Score
        Text(
          '${(accuracy * 100).round()}%',
          style: HifzTypo.score(
            color: accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),

        if (isSimulated) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HifzColors.goldMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Mode hors-ligne',
              style: HifzTypo.body(color: HifzColors.gold)
                  .copyWith(fontSize: 11),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Verset coloré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: HifzDecor.card,
          child: Wrap(
            alignment: WrapAlignment.center,
            textDirection: TextDirection.rtl,
            spacing: 6,
            runSpacing: 16,
            children: result.wordResults.asMap().entries.map((entry) {
              final idx = entry.key;
              final wr = entry.value;
              final isActive = idx == _activeWordIdx;

              Color color;
              switch (wr.status) {
                case AsrWordStatus.correct:
                  color = HifzColors.correct;
                case AsrWordStatus.close:
                  color = HifzColors.close;
                case AsrWordStatus.wrong:
                  color = HifzColors.wrong;
                case AsrWordStatus.missing:
                  color = HifzColors.missing;
                case AsrWordStatus.extra:
                  color = HifzColors.textLight;
              }

              return Text(
                wr.word,
                style: HifzTypo.verse(
                  size: isActive ? 28 : 24,
                  color: isActive ? HifzColors.karaokeActive : color,
                ),
                textDirection: TextDirection.rtl,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Légende
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(HifzColors.correct, 'Correct'),
            _LegendDot(HifzColors.wrong, 'Erreur'),
            _LegendDot(HifzColors.missing, 'Oublié'),
          ],
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
            onPressed: _finish,
            style: HifzDecor.primaryButton,
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: HifzTypo.body(color: HifzColors.textLight)),
        ],
      ),
    );
  }
}

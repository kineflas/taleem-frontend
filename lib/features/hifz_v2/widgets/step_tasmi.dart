import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';

/// Étape 4 — TASMI' (تسميع) : Récitation intégrale.
///
/// Intègre la mécanique du /replay :
/// - L'écran affiche uniquement la référence (pas le texte)
/// - L'élève récite de mémoire
/// - L'audio est analysé par le serveur ASR (validate-replay)
/// - Résultat mot par mot avec timestamps synchronisés
/// - Option de réécouter avec suivi karaoke coloré
class StepTasmi extends StatefulWidget {
  const StepTasmi({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(StepResult result) onComplete;

  @override
  State<StepTasmi> createState() => _StepTasmiState();
}

enum _TasmiPhase { prompt, recording, analyzing, replay }

class _StepTasmiState extends State<StepTasmi> {
  _TasmiPhase _phase = _TasmiPhase.prompt;
  final _startTime = DateTime.now();

  // Enregistrement
  Timer? _recTimer;
  int _recSeconds = 0;

  // Résultat
  double _accuracy = 0;
  List<_TasmiWord> _wordResults = [];
  int _correctCount = 0;
  int _wrongCount = 0;
  int _missingCount = 0;

  // Replay
  final AudioPlayer _replayPlayer = AudioPlayer();
  bool _isReplaying = false;
  int _activeWordIdx = -1;

  @override
  void dispose() {
    _recTimer?.cancel();
    _replayPlayer.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _phase = _TasmiPhase.recording;
      _recSeconds = 0;
    });
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recSeconds++);
    });
  }

  void _stopRecording() {
    _recTimer?.cancel();
    setState(() => _phase = _TasmiPhase.analyzing);
    _analyze();
  }

  Future<void> _analyze() async {
    // TODO: En production, envoyer l'audio enregistré au POST /api/validate-replay
    // et récupérer le résultat mot par mot avec timestamps.
    //
    // Pour le prototype, simuler un résultat.
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _phase = _TasmiPhase.replay;
      _wordResults = widget.verse.words.asMap().entries.map((e) {
        return _TasmiWord(
          word: e.value,
          status: _TasmiStatus.pending,
        );
      }).toList();
    });
  }

  void _finish() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    final total = widget.verse.words.length;
    final score = total > 0 ? (_correctCount / total * 100).round() : 0;

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
        // Référence seule — pas de texte !
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
          width: 48, height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(HifzColors.emerald),
          ),
        ),
        const SizedBox(height: 16),
        Text('Analyse de ta récitation...', style: HifzTypo.body(color: HifzColors.textMedium)),
      ],
    );
  }

  // ── Replay avec résultat mot par mot ──
  Widget _buildReplay() {
    return Column(
      key: const ValueKey('replay'),
      children: [
        // Score
        Text(
          '${(_accuracy * 100).round()}%',
          style: HifzTypo.score(
            color: _accuracy >= 0.7 ? HifzColors.correct : HifzColors.wrong,
          ),
        ),

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
            children: _wordResults.asMap().entries.map((entry) {
              final idx = entry.key;
              final tw = entry.value;
              final isActive = idx == _activeWordIdx;

              Color color;
              switch (tw.status) {
                case _TasmiStatus.correct:
                  color = HifzColors.correct;
                case _TasmiStatus.wrong:
                  color = HifzColors.wrong;
                case _TasmiStatus.missing:
                  color = HifzColors.missing;
                default:
                  color = HifzColors.textDark;
              }

              return Text(
                tw.word,
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
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: HifzTypo.body(color: HifzColors.textLight)),
        ],
      ),
    );
  }
}

enum _TasmiStatus { correct, wrong, missing, pending }

class _TasmiWord {
  _TasmiWord({required this.word, required this.status, this.startTime, this.endTime});
  final String word;
  final _TasmiStatus status;
  final double? startTime;
  final double? endTime;
}

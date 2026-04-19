import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../services/audio_orchestrator.dart';

/// Étape 2 — TIKRAR (تكرار) : Répétition guidée 6446.
///
/// - Phase Écoute (6×) : texte visible, karaoke synchronisé
/// - Phase Rappel (4×) : masquage progressif 30% → 50% → 70% → initiales
/// - Phase Consolidation (4×) : texte visible à nouveau
/// - Phase Autonomie (6×) : texte masqué, étoiles gagnées à chaque succès
class StepTikrar extends StatefulWidget {
  const StepTikrar({
    super.key,
    required this.verse,
    required this.orchestrator,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final AudioOrchestrator orchestrator;
  final void Function(StepResult result) onComplete;

  @override
  State<StepTikrar> createState() => _StepTikrarState();
}

class _StepTikrarState extends State<StepTikrar> {
  final _startTime = DateTime.now();
  int _autonomieStars = 0;
  bool _tikrarComplete = false;

  // Masquage : indices des mots masqués pour chaque répétition de la phase Rappel
  late List<Set<int>> _maskingSets;
  Set<int> _currentMask = {};
  Set<int> _revealedWords = {}; // Mots révélés via Safe Fail

  @override
  void initState() {
    super.initState();
    _buildMaskingSets();
    _setupOrchestrator();
  }

  void _buildMaskingSets() {
    final wordCount = widget.verse.words.length;
    final rng = Random(widget.verse.surahNumber * 1000 + widget.verse.verseNumber);
    final indices = List.generate(wordCount, (i) => i)..shuffle(rng);

    _maskingSets = [
      indices.take((wordCount * 0.3).ceil()).toSet(),                   // 30%
      indices.take((wordCount * 0.5).ceil()).toSet(),                   // 50%
      indices.take((wordCount * 0.7).ceil()).toSet(),                   // 70%
      List.generate(wordCount, (i) => i).toSet(),  // 100% (initiales seules)
    ];
  }

  void _setupOrchestrator() {
    widget.orchestrator.onPhaseChanged = () {
      setState(() {
        _revealedWords.clear();
        if (widget.orchestrator.currentPhase == TikrarPhase.rappel4) {
          _currentMask = _maskingSets[0];
        } else {
          _currentMask = {};
        }
      });
    };

    widget.orchestrator.onRepetitionComplete = () {
      setState(() {
        // Mettre à jour le masquage pendant la phase Rappel
        if (widget.orchestrator.currentPhase == TikrarPhase.rappel4) {
          final rep = widget.orchestrator.currentRepetition;
          if (rep < _maskingSets.length) {
            _currentMask = _maskingSets[rep];
          }
          _revealedWords.clear();
        }
        // Compter les étoiles pendant la phase Autonomie
        if (widget.orchestrator.currentPhase == TikrarPhase.autonomie6) {
          if (_revealedWords.isEmpty) {
            _autonomieStars++;
          }
          _revealedWords.clear();
        }
      });
    };

    widget.orchestrator.onAllComplete = () {
      setState(() => _tikrarComplete = true);
    };

    // Démarrer la boucle
    widget.orchestrator.startTikrar();
  }

  void _onSafeFail(int wordIndex) {
    setState(() => _revealedWords.add(wordIndex));
    // Masquer à nouveau après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _revealedWords.remove(wordIndex));
    });
  }

  void _finish() {
    widget.orchestrator.stop();
    final duration = DateTime.now().difference(_startTime).inSeconds;
    // Score basé sur les étoiles d'autonomie (max 6)
    final score = (_autonomieStars / 6 * 100).round().clamp(0, 100);

    widget.onComplete(StepResult(
      step: WirdStep.tikrar,
      score: score,
      durationSeconds: duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final orch = widget.orchestrator;

    return ListenableBuilder(
      listenable: orch,
      builder: (context, _) {
        return Column(
          children: [
            // ── Label ──
            Text('TIKRAR', style: HifzTypo.stepLabel()),
            const SizedBox(height: 4),
            Text(
              '${orch.currentPhase.label} — ${orch.currentRepetition + 1}/${orch.totalRepetitions}',
              style: HifzTypo.body(color: HifzColors.textLight),
            ),

            const SizedBox(height: 8),

            // ── Barre de progression globale ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: orch.globalProgress,
                  backgroundColor: HifzColors.ivoryDark,
                  valueColor: const AlwaysStoppedAnimation(HifzColors.emerald),
                  minHeight: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Verset avec masquage/karaoke ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                      decoration: HifzDecor.card,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        textDirection: TextDirection.rtl,
                        spacing: 6,
                        runSpacing: 16,
                        children: _buildWords(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Étoiles d'autonomie ──
                    if (orch.currentPhase == TikrarPhase.autonomie6)
                      _buildAutonomieStars(),

                    // ── Volume ducking indicator ──
                    if (!orch.currentPhase.isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic, size: 14, color: HifzColors.emerald.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Récite à voix haute',
                              style: HifzTypo.body(color: HifzColors.emerald),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Contrôles ──
            _buildControls(orch),
          ],
        );
      },
    );
  }

  List<Widget> _buildWords() {
    final words = widget.verse.words;
    final isListening = widget.orchestrator.currentPhase.isListening;
    final isFullMask = widget.orchestrator.currentPhase == TikrarPhase.autonomie6;

    return List.generate(words.length, (i) {
      final word = words[i];
      final isMasked = isFullMask || _currentMask.contains(i);
      final isRevealed = _revealedWords.contains(i);

      // Karaoke : déterminer si ce mot est actif
      bool isKaraokeActive = false;
      if (isListening && widget.verse.audioTimings != null) {
        final timings = widget.verse.audioTimings!;
        if (i < timings.length - 1) {
          final pos = widget.orchestrator.position.inMilliseconds / 1000.0;
          isKaraokeActive = pos >= timings[i] && pos < timings[i + 1];
        }
      }

      String displayText;
      if (isMasked && !isRevealed) {
        if (isFullMask) {
          // Autonomie : seule la première lettre
          displayText = '${word.characters.first}...';
        } else {
          displayText = '━' * (word.length ~/ 2 + 1);
        }
      } else {
        displayText = word;
      }

      return GestureDetector(
        onLongPress: isMasked && !isRevealed ? () => _onSafeFail(i) : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: HifzTypo.verse(
            size: isKaraokeActive ? 32 : 28,
            color: isKaraokeActive
                ? HifzColors.karaokeActive
                : isMasked && !isRevealed
                    ? HifzColors.textLight
                    : HifzColors.textDark,
          ),
          child: Text(
            displayText,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    });
  }

  Widget _buildAutonomieStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            i < _autonomieStars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < _autonomieStars ? HifzColors.gold : HifzColors.ivoryDark,
            size: 28,
          ),
        );
      }),
    );
  }

  Widget _buildControls(AudioOrchestrator orch) {
    if (_tikrarComplete) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _finish,
          style: HifzDecor.primaryButton,
          child: const Text('Continuer'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Vitesse
          TextButton(
            onPressed: () {
              final rates = [0.75, 1.0, 1.25];
              final cur = rates.indexOf(orch.playbackRate);
              final next = rates[(cur + 1) % rates.length];
              orch.setPlaybackRate(next);
            },
            child: Text(
              '${orch.playbackRate}x',
              style: HifzTypo.body(color: HifzColors.textLight),
            ),
          ),

          const SizedBox(width: 16),

          // Pause / Play
          IconButton(
            onPressed: () => orch.togglePause(),
            icon: Icon(
              orch.isPaused ? Icons.play_circle_filled : Icons.pause_circle_filled,
              size: 48,
              color: HifzColors.emerald,
            ),
          ),

          const SizedBox(width: 16),

          // Passer la répétition
          TextButton(
            onPressed: () => orch.skipRepetition(),
            child: Text(
              'Passer',
              style: HifzTypo.body(color: HifzColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';

/// Étape 5 — NATIJA (نتيجة) : Résultat & étoiles.
///
/// Affiche le score combiné de toutes les étapes, les étoiles gagnées,
/// les XP, et la prochaine date de révision.
class StepNatija extends StatefulWidget {
  const StepNatija({
    super.key,
    required this.verse,
    required this.stepResults,
    required this.onFinish,
  });

  final EnrichedVerse verse;
  final List<StepResult> stepResults;
  final VoidCallback onFinish;

  @override
  State<StepNatija> createState() => _StepNatijaState();
}

class _StepNatijaState extends State<StepNatija>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  late int _finalScore;
  late int _stars;
  late int _xp;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Calculer le score
    final scores = widget.stepResults
        .where((r) => r.score > 0)
        .map((r) => r.score)
        .toList();

    _finalScore = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) ~/ scores.length;

    _stars = _finalScore >= 90 ? 3 : _finalScore >= 70 ? 2 : _finalScore >= 50 ? 1 : 0;
    _xp = _stars * 15 + _finalScore ~/ 5;

    // Animer les étoiles
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starController.forward();
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = SrsTier.fromScore(_finalScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Label ──
          Text('NATIJA', style: HifzTypo.stepLabel()),

          const SizedBox(height: 24),

          // ── Étoiles animées ──
          AnimatedBuilder(
            animation: _starController,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final delay = i * 0.25;
                  final progress = (_starController.value - delay).clamp(0.0, 0.5) / 0.5;
                  final isEarned = i < _stars;
                  final scale = isEarned ? Curves.elasticOut.transform(progress) : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: i == 1 ? 56 : 44, // Étoile centrale plus grande
                        color: isEarned ? HifzColors.goldLight : HifzColors.ivoryDark,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Score ──
          Text(
            '$_finalScore%',
            style: HifzTypo.score(
              color: _finalScore >= 70 ? HifzColors.correct : HifzColors.wrong,
            ),
          ),
          Text(
            _finalScore >= 90
                ? 'Excellent !'
                : _finalScore >= 70
                    ? 'Bien récité'
                    : _finalScore >= 50
                        ? 'Encourageant'
                        : 'À retravailler',
            style: HifzTypo.sectionTitle(
              color: _finalScore >= 70 ? HifzColors.correct : HifzColors.textMedium,
            ),
          ),

          const SizedBox(height: 24),

          // ── Détails par étape ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: HifzDecor.card,
            child: Column(
              children: [
                ...widget.stepResults.map((r) {
                  final label = switch (r.step) {
                    WirdStep.tikrar => 'Tikrar (Répétition)',
                    WirdStep.tamrin => 'Tamrin (Exercices)',
                    WirdStep.tasmi => 'Tasmi\' (Récitation)',
                    _ => r.step.name,
                  };

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(label, style: HifzTypo.body()),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: r.score >= 70
                                ? HifzColors.correct.withOpacity(0.1)
                                : HifzColors.close.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${r.score}%',
                            style: HifzTypo.body(
                              color: r.score >= 70 ? HifzColors.correct : HifzColors.close,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(color: HifzColors.ivoryDark, height: 24),

                // XP gagné
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: HifzColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      '+$_xp XP',
                      style: HifzTypo.sectionTitle(color: HifzColors.gold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Prochaine révision ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HifzColors.emeraldMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: HifzColors.emerald),
                const SizedBox(width: 8),
                Text(
                  'Prochaine révision : dans ${tier.intervalDays} jour${tier.intervalDays > 1 ? 's' : ''}',
                  style: HifzTypo.body(color: HifzColors.emerald),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Bouton ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onFinish,
              style: HifzDecor.primaryButton,
              child: const Text('Verset suivant'),
            ),
          ),
        ],
      ),
    );
  }
}

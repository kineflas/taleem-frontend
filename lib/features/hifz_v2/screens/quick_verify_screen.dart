/// QuickVerifyScreen — Mode Rapide pour vérifier une sourate connue.
///
/// 4 étapes express :
///   ① Tartib Express — 5-10 versets aléatoires à réordonner
///   ② Takamul Express — 1 trou tous les ~5 versets
///   ③ Tasmi' Complet — Récitation de la sourate (auto-éval)
///   ④ Natija Express — Score + mise à jour SRS en batch
///
/// Critère d'accès : ≥80% des versets au Tier 4+ (Acquis).
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hifz_v2_service.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../widgets/exercises/exercise_tartib.dart';
import '../widgets/exercises/exercise_takamul.dart';

/// Étapes du Mode Rapide.
enum QuickStep { tartib, takamul, tasmi, natija }

class QuickVerifyScreen extends ConsumerStatefulWidget {
  const QuickVerifyScreen({
    super.key,
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahNameFr,
    required this.allVerses,
  });

  final int surahNumber;
  final String surahNameAr;
  final String surahNameFr;
  final List<EnrichedVerse> allVerses;

  @override
  ConsumerState<QuickVerifyScreen> createState() => _QuickVerifyScreenState();
}

class _QuickVerifyScreenState extends ConsumerState<QuickVerifyScreen> {
  QuickStep _currentStep = QuickStep.tartib;
  final _startTime = DateTime.now();

  // Sous-ensembles de versets pour les exercices express
  late List<EnrichedVerse> _tartibSubset;
  late List<EnrichedVerse> _takamulSubset;

  // Scores
  int _tartibScore = 0;
  int _takamulScore = 0;
  int _tasmiScore = 0;

  // Pour Natija
  bool _submitting = false;
  int? _globalScore;
  int? _stars;
  int? _xpEarned;
  int? _versesUpdated;
  int? _tierUps;

  static const _steps = QuickStep.values;

  @override
  void initState() {
    super.initState();
    _prepareSubsets();
  }

  void _prepareSubsets() {
    final rng = Random();
    final all = widget.allVerses;

    // Tartib Express : 5-10 versets aléatoires
    final tartibCount = min(max(5, all.length ~/ 3), min(10, all.length));
    _tartibSubset = List.of(all)..shuffle(rng);
    _tartibSubset = _tartibSubset.take(tartibCount).toList()
      ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

    // Takamul Express : 1 trou tous les ~5 versets → selection régulière
    final takamulIndices = <int>[];
    for (var i = 0; i < all.length; i += 5) {
      takamulIndices.add(i);
      // Aussi ajouter les voisins pour le contexte
      if (i + 1 < all.length) takamulIndices.add(i + 1);
      if (i - 1 >= 0 && !takamulIndices.contains(i - 1)) {
        takamulIndices.add(i - 1);
      }
    }
    takamulIndices.sort();
    final uniqueIndices = takamulIndices.toSet().toList()..sort();
    _takamulSubset = uniqueIndices
        .where((i) => i < all.length)
        .map((i) => all[i])
        .toList();
    // Au minimum 3 versets pour Takamul
    if (_takamulSubset.length < 3) _takamulSubset = all;
  }

  void _advanceStep() {
    final idx = _steps.indexOf(_currentStep);
    if (idx + 1 < _steps.length) {
      setState(() => _currentStep = _steps[idx + 1]);
    }
  }

  Future<void> _submitResults() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final duration = DateTime.now().difference(_startTime).inSeconds;

    try {
      final service = ref.read(hifzV2ServiceProvider);
      final result = await service.quickVerifySurah(
        surahNumber: widget.surahNumber,
        tartibScore: _tartibScore,
        takamulScore: _takamulScore,
        tasmiScore: _tasmiScore,
        durationSeconds: duration,
      );

      if (!mounted) return;
      setState(() {
        _globalScore = result.globalScore;
        _stars = result.stars;
        _xpEarned = result.xpEarned;
        _versesUpdated = result.versesUpdated;
        _tierUps = result.tierUps;
        _submitting = false;
      });
    } catch (e) {
      // Fallback: calcul local
      final gs = (_tartibScore * 0.25 + _takamulScore * 0.35 + _tasmiScore * 0.40)
          .round()
          .clamp(0, 100);
      if (!mounted) return;
      setState(() {
        _globalScore = gs;
        _stars = gs >= 90 ? 3 : gs >= 70 ? 2 : gs >= 50 ? 1 : 0;
        _xpEarned = 30 + (gs >= 90 ? 25 : gs >= 70 ? 15 : 0);
        _versesUpdated = widget.allVerses.length;
        _tierUps = 0;
        _submitting = false;
      });
    }

    // Rafraîchir les données
    ref.invalidate(journeyMapProvider);
    ref.invalidate(suggestedSurahsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: HifzColors.textLight),
            onPressed: () => _showExitConfirmation(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: HifzColors.emeraldMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 16, color: HifzColors.emerald),
                const SizedBox(width: 4),
                Text('RAPIDE', style: HifzTypo.stepLabel()),
              ],
            ),
          ),
          const Spacer(),
          Text(
            widget.surahNameAr,
            textDirection: TextDirection.rtl,
            style: HifzTypo.verse(size: 16, color: HifzColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final stepLabels = {
      QuickStep.tartib: 'Tartib',
      QuickStep.takamul: 'Takamul',
      QuickStep.tasmi: 'Tasmi\'',
      QuickStep.natija: 'Natija',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _steps.map((step) {
          final isActive = step == _currentStep;
          final isDone = step.index < _currentStep.index;

          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? HifzColors.emerald
                        : isActive
                            ? HifzColors.gold
                            : HifzColors.ivoryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepLabels[step] ?? '',
                  style: HifzTypo.body(
                    color: isActive
                        ? HifzColors.gold
                        : isDone
                            ? HifzColors.emerald
                            : HifzColors.textLight,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      QuickStep.tartib => ExerciseTartib(
          key: const ValueKey('quick-tartib'),
          verses: _tartibSubset,
          onComplete: (score) {
            _tartibScore = score;
            _advanceStep();
          },
        ),
      QuickStep.takamul => ExerciseTakamul(
          key: const ValueKey('quick-takamul'),
          verses: _takamulSubset,
          onComplete: (score) {
            _takamulScore = score;
            _advanceStep();
          },
        ),
      QuickStep.tasmi => _QuickTasmi(
          key: const ValueKey('quick-tasmi'),
          surahNameAr: widget.surahNameAr,
          totalVerses: widget.allVerses.length,
          firstVerse: widget.allVerses.first,
          lastVerse: widget.allVerses.last,
          onComplete: (score) {
            _tasmiScore = score;
            _advanceStep();
            _submitResults();
          },
        ),
      QuickStep.natija => _QuickNatija(
          key: const ValueKey('quick-natija'),
          surahNameAr: widget.surahNameAr,
          surahNameFr: widget.surahNameFr,
          tartibScore: _tartibScore,
          takamulScore: _takamulScore,
          tasmiScore: _tasmiScore,
          globalScore: _globalScore,
          stars: _stars,
          xpEarned: _xpEarned,
          versesUpdated: _versesUpdated,
          tierUps: _tierUps,
          isLoading: _submitting,
          onFinish: () => Navigator.of(context).pop(),
        ),
    };
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HifzColors.ivoryWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Quitter la vérification ?', style: HifzTypo.sectionTitle()),
        content: Text(
          'Ta progression ne sera pas sauvegardée.',
          style: HifzTypo.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Continuer', style: HifzTypo.body(color: HifzColors.emerald)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Quitter', style: HifzTypo.body(color: HifzColors.wrong)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Tasmi' — Récitation de la sourate complète (auto-éval)
// ═══════════════════════════════════════════════════════════════════

class _QuickTasmi extends StatefulWidget {
  const _QuickTasmi({
    super.key,
    required this.surahNameAr,
    required this.totalVerses,
    required this.firstVerse,
    required this.lastVerse,
    required this.onComplete,
  });

  final String surahNameAr;
  final int totalVerses;
  final EnrichedVerse firstVerse;
  final EnrichedVerse lastVerse;
  final void Function(int score) onComplete;

  @override
  State<_QuickTasmi> createState() => _QuickTasmiState();
}

class _QuickTasmiState extends State<_QuickTasmi> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تسميع كامل',
            style: HifzTypo.verse(size: 26, color: HifzColors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            'Récite la sourate ${widget.surahNameAr} en entier',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.totalVerses} versets — ${widget.firstVerse.reference} → ${widget.lastVerse.reference}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 40),

          const Icon(Icons.mic_none_rounded,
              size: 80, color: HifzColors.emeraldMuted),

          const SizedBox(height: 40),

          Text('Comment as-tu récité ?',
              style: HifzTypo.body(color: HifzColors.textMedium)),
          const SizedBox(height: 16),

          // ── Auto-évaluation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickScoreBtn(
                label: 'Difficile',
                emoji: '😓',
                color: HifzColors.wrong,
                onTap: () => widget.onComplete(30),
              ),
              _QuickScoreBtn(
                label: 'Moyen',
                emoji: '😐',
                color: HifzColors.close,
                onTap: () => widget.onComplete(60),
              ),
              _QuickScoreBtn(
                label: 'Bien',
                emoji: '😊',
                color: HifzColors.emerald,
                onTap: () => widget.onComplete(80),
              ),
              _QuickScoreBtn(
                label: 'Parfait',
                emoji: '🌟',
                color: HifzColors.gold,
                onTap: () => widget.onComplete(100),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickScoreBtn extends StatelessWidget {
  const _QuickScoreBtn({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(label, style: HifzTypo.body(color: color).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Natija — Résultats express
// ═══════════════════════════════════════════════════════════════════

class _QuickNatija extends StatelessWidget {
  const _QuickNatija({
    super.key,
    required this.surahNameAr,
    required this.surahNameFr,
    required this.tartibScore,
    required this.takamulScore,
    required this.tasmiScore,
    this.globalScore,
    this.stars,
    this.xpEarned,
    this.versesUpdated,
    this.tierUps,
    this.isLoading = false,
    required this.onFinish,
  });

  final String surahNameAr;
  final String surahNameFr;
  final int tartibScore;
  final int takamulScore;
  final int tasmiScore;
  final int? globalScore;
  final int? stars;
  final int? xpEarned;
  final int? versesUpdated;
  final int? tierUps;
  final bool isLoading;
  final VoidCallback onFinish;

  int get _displayScore =>
      globalScore ??
      (tartibScore * 0.25 + takamulScore * 0.35 + tasmiScore * 0.40)
          .round()
          .clamp(0, 100);

  int get _displayStars =>
      stars ??
      (_displayScore >= 90 ? 3 : _displayScore >= 70 ? 2 : _displayScore >= 50 ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HifzColors.emerald),
            SizedBox(height: 16),
            Text('Mise à jour en cours...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sourate name
          Text(surahNameAr,
              textDirection: TextDirection.rtl,
              style: HifzTypo.verse(size: 24, color: HifzColors.gold)),
          Text(surahNameFr,
              style: HifzTypo.body(color: HifzColors.textMedium)),

          const SizedBox(height: 20),

          // Global score
          Text(
            '$_displayScore%',
            style: HifzTypo.score(
              color: _displayScore >= 70 ? HifzColors.emerald : HifzColors.wrong,
            ),
          ),
          const SizedBox(height: 8),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                i < _displayStars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: HifzColors.gold,
                size: 32,
              );
            }),
          ),

          const SizedBox(height: 20),

          // Step scores
          _QuickScoreRow('Tartib Express', tartibScore),
          const SizedBox(height: 6),
          _QuickScoreRow('Takamul Express', takamulScore),
          const SizedBox(height: 6),
          _QuickScoreRow('Tasmi\' Complet', tasmiScore),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                icon: Icons.check_circle,
                value: '${versesUpdated ?? 0}',
                label: 'versets',
              ),
              _StatChip(
                icon: Icons.trending_up,
                value: '${tierUps ?? 0}',
                label: 'tier ups',
              ),
              _StatChip(
                icon: Icons.auto_awesome,
                value: '+${xpEarned ?? 0}',
                label: 'XP',
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: HifzDecor.primaryButton,
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickScoreRow extends StatelessWidget {
  const _QuickScoreRow(this.label, this.score);

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 70 ? HifzColors.correct : score >= 50 ? HifzColors.close : HifzColors.wrong;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: HifzColors.ivoryWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: HifzTypo.body(color: HifzColors.textMedium)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score%',
              style: HifzTypo.body(color: color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: HifzColors.emerald, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: HifzTypo.body(color: HifzColors.textDark)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label,
            style: HifzTypo.body(color: HifzColors.textLight)
                .copyWith(fontSize: 10)),
      ],
    );
  }
}

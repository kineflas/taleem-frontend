import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Main entry point for Autonomous Learning module hub.
/// Shows all 5 modules as cards with progress, unlock status, and phase indicators.
class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleProgressAsync = ref.watch(moduleProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Apprentissage Autonome',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: moduleProgressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (moduleProgress) {
          // Calculate comprehension score (placeholder: based on avg mastery)
          final avgMastery = moduleProgress.isEmpty
              ? 0
              : moduleProgress.values
                      .fold<int>(0, (sum, m) => sum + (m['masteryLevel'] ?? 0)) ~/
                  moduleProgress.length;
          final comprehensionScore = (avgMastery / 3 * 100).toInt();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Comprehension banner
                _ComprehensionBanner(score: comprehensionScore),
                const SizedBox(height: 24),

                // Module cards
                ..._buildModuleCards(context, moduleProgress),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildModuleCards(
      BuildContext context, Map<int, dynamic> moduleProgress) {
    final modules = [
      {
        'number': 1,
        'titleAr': 'الكلمات المفتاحية',
        'titleFr': 'Les 50 mots-clés',
        'icon': '🔑',
      },
      {
        'number': 2,
        'titleAr': 'الحروف المكانية',
        'titleFr': 'Les particules spatiales',
        'icon': '📍',
      },
      {
        'number': 3,
        'titleAr': 'التعبيرات القرآنية',
        'titleFr': 'Les blocs de sens',
        'icon': '🧩',
      },
      {
        'number': 4,
        'titleAr': 'جذور الكلمات',
        'titleFr': "L'ADN des mots",
        'icon': '🌳',
      },
      {
        'number': 5,
        'titleAr': 'القراءة الموجهة',
        'titleFr': 'Lecture guidée',
        'icon': '📖',
      },
    ];

    return modules.map((module) {
      final moduleNum = module['number'] as int;
      final progress = moduleProgress[moduleNum];
      final isUnlocked = moduleNum == 1 || (moduleProgress[moduleNum - 1] != null);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ModuleCard(
          moduleNumber: moduleNum,
          titleAr: module['titleAr'] as String,
          titleFr: module['titleFr'] as String,
          icon: module['icon'] as String,
          progress: progress?['percentComplete'] ?? 0,
          isUnlocked: isUnlocked,
          phase: progress?['currentPhase'] ?? 0,
          onTap: isUnlocked
              ? () => context.push('/learning/module/$moduleNum')
              : null,
        ),
      );
    }).toList();
  }
}

class _ComprehensionBanner extends StatelessWidget {
  final int score;

  const _ComprehensionBanner({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre compréhension',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous comprenez $score% du vocabulaire du Coran',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int moduleNumber;
  final String titleAr;
  final String titleFr;
  final String icon;
  final int progress;
  final bool isUnlocked;
  final int phase;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.moduleNumber,
    required this.titleAr,
    required this.titleFr,
    required this.icon,
    required this.progress,
    required this.isUnlocked,
    required this.phase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon & Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Module $moduleNumber',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    titleFr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      titleAr,
                                      style: TextStyle(
                                        fontFamily:
                                            GoogleFonts.scheherazadeNew()
                                                .fontFamily,
                                        fontSize: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lock icon if locked
                    if (!isUnlocked)
                      Icon(
                        Icons.lock,
                        color: AppColors.textHint,
                        size: 24,
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.textHint.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Phase indicator
                    _PhaseIndicator(phase: phase),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final int phase;

  const _PhaseIndicator({required this.phase});

  String get phaseLabel {
    switch (phase) {
      case 1:
        return '👁️ Voir';
      case 2:
        return '✋ Faire';
      case 3:
        return '🎯 Appliquer';
      default:
        return 'Non commencé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        phaseLabel,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

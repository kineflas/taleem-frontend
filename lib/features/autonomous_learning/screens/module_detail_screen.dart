import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Module detail screen — shows module description, 3 phase tabs, and progress stats.
/// Route: /learning/module/:moduleNumber
class ModuleDetailScreen extends ConsumerStatefulWidget {
  final int moduleNumber;

  const ModuleDetailScreen({super.key, required this.moduleNumber});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  int _selectedPhaseTab = 1;

  @override
  Widget build(BuildContext context) {
    final moduleInfo = _getModuleInfo(widget.moduleNumber);
    final moduleProgressAsync = ref.watch(moduleProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          moduleInfo['titleFr'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: moduleProgressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (moduleProgress) {
          final progress = moduleProgress[widget.moduleNumber] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Module header
                _ModuleHeader(
                  titleAr: moduleInfo['titleAr'],
                  description: moduleInfo['description'],
                  icon: moduleInfo['icon'],
                ),
                const SizedBox(height: 24),

                // Phase tabs
                _PhaseTabBar(
                  selectedPhase: _selectedPhaseTab,
                  onPhaseSelected: (phase) =>
                      setState(() => _selectedPhaseTab = phase),
                ),
                const SizedBox(height: 16),

                // Phase content (Exercise screens will be rendered here)
                _PhaseContent(
                  moduleNumber: widget.moduleNumber,
                  phase: _selectedPhaseTab,
                ),

                const SizedBox(height: 24),

                // Progress stats
                _ProgressStats(
                  moduleNumber: widget.moduleNumber,
                  progress: progress,
                ),

                const SizedBox(height: 24),

                // Start session button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.push(
                      '/learning/module/${widget.moduleNumber}/phase/$_selectedPhaseTab/exercise',
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Commencer la session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getModuleInfo(int moduleNumber) {
    const modules = [
      {
        'number': 1,
        'titleAr': 'الكلمات المفتاحية',
        'titleFr': 'Les 50 mots-clés',
        'icon': '🔑',
        'description':
            'Maîtrisez les 50 mots les plus fréquents du Coran. Base essentielle pour la compréhension.',
      },
      {
        'number': 2,
        'titleAr': 'الحروف المكانية',
        'titleFr': 'Les particules spatiales',
        'icon': '📍',
        'description':
            'Comprenez les petits mots qui indiquent les relations spatiales dans le texte coranique.',
      },
      {
        'number': 3,
        'titleAr': 'التعبيرات القرآنية',
        'titleFr': 'Les blocs de sens',
        'icon': '🧩',
        'description':
            'Reconnaître les groupes de mots qui forment des unités de sens complètes.',
      },
      {
        'number': 4,
        'titleAr': 'جذور الكلمات',
        'titleFr': "L'ADN des mots",
        'icon': '🌳',
        'description':
            'Découvrez comment les racines génèrent des familles de mots et leurs variantes.',
      },
      {
        'number': 5,
        'titleAr': 'القراءة الموجهة',
        'titleFr': 'Lecture guidée',
        'icon': '📖',
        'description':
            'Appliquez tout ce que vous avez appris sur des versets complets.',
      },
    ];

    final module = modules.firstWhere(
      (m) => m['number'] == moduleNumber,
      orElse: () => modules[0],
    );

    return module;
  }
}

class _ModuleHeader extends StatelessWidget {
  final String titleAr;
  final String description;
  final String icon;

  const _ModuleHeader({
    required this.titleAr,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              titleAr,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 28,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PhaseTabBar extends StatelessWidget {
  final int selectedPhase;
  final ValueChanged<int> onPhaseSelected;

  const _PhaseTabBar({
    required this.selectedPhase,
    required this.onPhaseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final phases = [
      {'number': 1, 'label': '👁️ Voir'},
      {'number': 2, 'label': '✋ Faire'},
      {'number': 3, 'label': '🎯 Appliquer'},
    ];

    return Row(
      children: phases.map((phase) {
        final isSelected = selectedPhase == phase['number'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onPhaseSelected(phase['number'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                phase['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhaseContent extends StatelessWidget {
  final int moduleNumber;
  final int phase;

  const _PhaseContent({
    required this.moduleNumber,
    required this.phase,
  });

  String get phaseDescription {
    switch (phase) {
      case 1:
        return 'Regardez et mémorisez les éléments clés de ce module.';
      case 2:
        return 'Entraînez-vous avec des exercices pour renforcer votre compréhension.';
      case 3:
        return 'Appliquez ce que vous avez appris sur des textes réels.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            phaseDescription,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Phase $phase - Mode "${_getPhaseTitle(phase)}"',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseTitle(int phase) {
    switch (phase) {
      case 1:
        return 'Voir';
      case 2:
        return 'Faire';
      case 3:
        return 'Appliquer';
      default:
        return '';
    }
  }
}

class _ProgressStats extends ConsumerWidget {
  final int moduleNumber;
  final Map<String, dynamic> progress;

  const _ProgressStats({
    required this.moduleNumber,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteredCount = progress['masteredCount'] ?? 0;
    final totalCount = progress['totalCount'] ?? 50;
    final accuracy = progress['accuracy'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre progression',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Maîtrisé',
                value: '$masteredCount/$totalCount',
                icon: '✅',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Précision',
                value: '$accuracy%',
                icon: '🎯',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

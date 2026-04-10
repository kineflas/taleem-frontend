import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';
import '../widgets/alphabet_intro_card.dart';

/// Screen showing all units of an enrolled program + per-unit progress.
/// Route: /student/curriculum/:enrollmentId
class CurriculumProgramScreen extends ConsumerWidget {
  final String enrollmentId;

  const CurriculumProgramScreen({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(enrollmentProgressProvider(enrollmentId));

    return progressAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (progress) {
        final program = progress.enrollment.program;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Text(program.curriculumType.icon,
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          program.titleAr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  title: Text(program.titleFr,
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, size: 32),
                    onPressed: () => _continueLesson(context, ref),
                    tooltip: 'Continuer',
                  ),
                ],
              ),

              // Overall progress bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${progress.completedItems} / ${progress.totalItems} éléments',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${progress.completionPct.toStringAsFixed(0)} %',
                            style: TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.completionPct / 100,
                          backgroundColor: Colors.grey[200],
                          color: AppColors.primary,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Intro card (Alphabet only)
              if (program.curriculumType == CurriculumType.alphabetArabe)
                const SliverToBoxAdapter(child: AlphabetIntroCard()),

              // Units list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final unitProgress = progress.units[i];
                      return _UnitProgressTile(
                        unitProgress: unitProgress,
                        enrollmentId: enrollmentId,
                      );
                    },
                    childCount: progress.units.length,
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
    );
  }

  void _continueLesson(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(curriculumApiProvider);
      final next = await api.fetchNextItem(enrollmentId);
      if (context.mounted) {
        if (next['item'] != null) {
          final item = CurriculumItem.fromJson(next['item']);
          context.push('/student/curriculum/$enrollmentId/item/${item.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Programme complété ! 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}

class _UnitProgressTile extends StatelessWidget {
  final UnitProgress unitProgress;
  final String enrollmentId;

  const _UnitProgressTile({required this.unitProgress, required this.enrollmentId});

  @override
  Widget build(BuildContext context) {
    final unit = unitProgress.unit;
    final pct = unitProgress.completionPct;
    final isComplete = pct >= 100;
    final familyIdx = glyphToFamilyIndex[unit.titleAr];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/student/curriculum/$enrollmentId/unit/${unit.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Family color dot + number badge
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isComplete ? AppColors.success : AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isComplete
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : Text(
                              '${unit.number}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  if (familyIdx != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: letterFamilies[familyIdx].color,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.titleFr ?? unit.titleAr,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        unit.titleAr,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: Colors.grey[200],
                              color: isComplete ? AppColors.success : AppColors.accent,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${unitProgress.completedItems}/${unitProgress.totalItems}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

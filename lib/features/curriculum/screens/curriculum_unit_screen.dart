import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';

/// Screen listing all items in a unit with completion badges.
/// Route: /student/curriculum/:enrollmentId/unit/:unitId
class CurriculumUnitScreen extends ConsumerWidget {
  final String enrollmentId;
  final String unitId;

  const CurriculumUnitScreen({
    super.key,
    required this.enrollmentId,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(curriculumUnitDetailProvider(unitId));
    final progressAsync = ref.watch(enrollmentProgressProvider(enrollmentId));

    return unitAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (unit) {
        // Build a map of item_id → progress
        final progressMap = <String, ItemProgress>{};
        if (progressAsync.hasValue) {
          for (final unitProg in progressAsync.value!.units) {
            for (final ip in unitProg.itemsProgress) {
              progressMap[ip.curriculumItemId] = ip;
            }
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.titleFr ?? unit.titleAr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  unit.titleAr,
                  style: const TextStyle(
                      fontFamily: 'Scheherazade', fontSize: 14, color: Colors.white70),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Description card
              if (unit.descriptionFr != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    unit.descriptionFr!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),

              // Items list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: unit.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = unit.items[i];
                    final prog = progressMap[item.id];
                    final isCompleted = prog?.isCompleted ?? false;

                    return _ItemTile(
                      item: item,
                      isCompleted: isCompleted,
                      masteryLevel: prog?.masteryLevel,
                      teacherValidated: prog?.teacherValidated ?? false,
                      onTap: () => context.push(
                          '/student/curriculum/$enrollmentId/item/${item.id}'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final CurriculumItem item;
  final bool isCompleted;
  final int? masteryLevel;
  final bool teacherValidated;
  final VoidCallback onTap;

  const _ItemTile({
    required this.item,
    required this.isCompleted,
    required this.masteryLevel,
    required this.teacherValidated,
    required this.onTap,
  });

  Color get _statusColor {
    if (!isCompleted) return Colors.grey[300]!;
    if (masteryLevel == 3) return AppColors.success;
    if (masteryLevel == 2) return AppColors.accent;
    return AppColors.primary.withOpacity(0.5);
  }

  IconData get _typeIcon {
    switch (item.itemType) {
      case ItemType.letterForm: return Icons.translate;
      case ItemType.vocabulary: return Icons.menu_book;
      case ItemType.grammarPoint: return Icons.rule;
      case ItemType.rule: return Icons.lightbulb_outline;
      case ItemType.example: return Icons.format_quote;
      case ItemType.surahSegment: return Icons.auto_stories;
      case ItemType.combination: return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Completion circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _statusColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: _statusColor, size: 20)
                      : Icon(_typeIcon, color: Colors.grey[400], size: 18),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic title (RTL)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.titleAr,
                        style: const TextStyle(
                          fontFamily: 'Scheherazade',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.titleFr != null)
                      Text(
                        item.titleFr!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (item.transliteration != null)
                      Text(
                        '[${item.transliteration}]',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),

              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (teacherValidated)
                    const Icon(Icons.verified, color: AppColors.success, size: 18),
                  if (masteryLevel != null) ...[
                    const SizedBox(height: 4),
                    _MasteryDots(level: masteryLevel!),
                  ],
                ],
              ),

              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasteryDots extends StatelessWidget {
  final int level;
  const _MasteryDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < level ? AppColors.success : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

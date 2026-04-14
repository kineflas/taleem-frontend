import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/lesson_models.dart';
import '../providers/lesson_provider.dart';
import '../widgets/star_display.dart';

/// "La Caravane du Savoir" — visual lesson map showing all 23 lessons
/// grouped by Part with a scrollable path/map layout.
class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(medineLessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'La Caravane du Savoir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Erreur : $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(medineLessonsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (lessons) => _LessonMap(lessons: lessons),
      ),
    );
  }
}

class _LessonMap extends StatelessWidget {
  final List<LessonListItem> lessons;
  const _LessonMap({required this.lessons});

  @override
  Widget build(BuildContext context) {
    // Group lessons by part
    final grouped = <int, List<LessonListItem>>{};
    for (final lesson in lessons) {
      final part = lessonToPart[lesson.lessonNumber] ?? 1;
      grouped.putIfAbsent(part, () => []).add(lesson);
    }

    final parts = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final partNum = parts[index];
        final partLessons = grouped[partNum]!;
        final title = partTitles[partNum] ?? 'Partie $partNum';

        return _PartSection(
          partNumber: partNum,
          title: title,
          lessons: partLessons,
        );
      },
    );
  }
}

class _PartSection extends StatelessWidget {
  final int partNumber;
  final String title;
  final List<LessonListItem> lessons;

  const _PartSection({
    required this.partNumber,
    required this.title,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part header
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'P$partNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lesson nodes in a winding path
        ...List.generate(lessons.length, (i) {
          final lesson = lessons[i];
          final isEven = i.isEven;
          return _LessonNode(
            lesson: lesson,
            alignRight: !isEven,
            isLast: i == lessons.length - 1,
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _LessonNode extends StatelessWidget {
  final LessonListItem lesson;
  final bool alignRight;
  final bool isLast;

  const _LessonNode({
    required this.lesson,
    this.alignRight = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !lesson.isUnlocked;
    final isDone = lesson.isCompleted;

    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 60 : 0,
        right: alignRight ? 0 : 60,
        bottom: isLast ? 0 : 8,
      ),
      child: GestureDetector(
        onTap: isLocked
            ? null
            : () => context.push('/medine/lesson/${lesson.lessonNumber}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLocked
                ? AppColors.surfaceVariant
                : isDone
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLocked
                  ? AppColors.divider
                  : isDone
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3),
              width: isDone ? 2 : 1,
            ),
            boxShadow: isLocked
                ? []
                : const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Lesson number circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked
                      ? AppColors.textHint.withOpacity(0.2)
                      : isDone
                          ? AppColors.success
                          : AppColors.primary,
                ),
                alignment: Alignment.center,
                child: isLocked
                    ? const Icon(Icons.lock, size: 18, color: AppColors.textHint)
                    : Text(
                        '${lesson.lessonNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Titles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.titleFr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isLocked ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        lesson.titleAr,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Amiri',
                          color: isLocked ? AppColors.textHint : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stars
              if (!isLocked && lesson.stars > 0)
                StarDisplay(stars: lesson.stars, size: 18),

              if (isDone)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, color: AppColors.success, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

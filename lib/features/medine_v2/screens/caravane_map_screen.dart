import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Main map screen showing the 23 lessons as a scrollable journey path.
class CaravaneMapScreen extends ConsumerWidget {
  const CaravaneMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(medineV2LessonsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (lessons) => _MapBody(lessons: lessons),
      ),
    );
  }
}

class _MapBody extends StatelessWidget {
  final List<LessonListItemV2> lessons;
  const _MapBody({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar with stats HUD
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xFF1B4332),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'La Caravane du Savoir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // HUD bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2D6A4F),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HudItem(icon: '🔥', label: '0', subtitle: 'Streak'),
                _HudItem(icon: '⭐', label: '0', subtitle: 'XP'),
                _HudItem(icon: '💎', label: '3/3', subtitle: 'Jokers'),
              ],
            ),
          ),
        ),

        // Lessons path
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Group lessons by part
              if (index >= lessons.length) return null;
              final lesson = lessons[index];

              // Part separator
              final showPartHeader = index == 0 ||
                  lesson.partNumber != lessons[index - 1].partNumber;

              return Column(
                children: [
                  if (showPartHeader) _PartHeader(lesson: lesson),
                  _LessonNode(lesson: lesson, index: index),
                ],
              );
            },
            childCount: lessons.length,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _HudItem extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  const _HudItem({required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}

class _PartHeader extends StatelessWidget {
  final LessonListItemV2 lesson;
  const _PartHeader({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = partThemes[lesson.partNumber];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Color(theme?.color ?? 0xFF2D6A4F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(theme?.color ?? 0xFF2D6A4F).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(theme?.icon ?? '📖', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape ${lesson.partNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(theme?.color ?? 0xFF2D6A4F),
                  ),
                ),
                Text(
                  theme?.name ?? lesson.partName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final LessonListItemV2 lesson;
  final int index;
  const _LessonNode({required this.lesson, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = partThemes[lesson.partNumber];
    final baseColor = Color(theme?.color ?? 0xFF2D6A4F);
    final isLocked = !lesson.isUnlocked;
    final isCompleted = lesson.isCompleted;

    // Alternate left/right position
    final isLeft = index % 2 == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (!isLeft) const Spacer(flex: 2),
          if (isLeft) const SizedBox(width: 32),
          // Connecting line
          if (index > 0)
            Positioned(
              child: Container(width: 2, height: 20, color: baseColor.withOpacity(0.3)),
            ),
          // Node
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isLocked
                  ? null
                  : () => context.push('/medine-v2/lesson/${lesson.lessonNumber}'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.shade200
                      : isCompleted
                          ? baseColor.withOpacity(0.15)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLocked
                        ? Colors.grey.shade300
                        : baseColor,
                    width: isCompleted ? 2 : 1,
                  ),
                  boxShadow: isLocked
                      ? []
                      : [
                          BoxShadow(
                            color: baseColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Lesson number circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocked
                            ? Colors.grey.shade300
                            : isCompleted
                                ? baseColor
                                : baseColor.withOpacity(0.1),
                      ),
                      child: Center(
                        child: isLocked
                            ? Icon(Icons.lock, size: 20, color: Colors.grey.shade500)
                            : isCompleted
                                ? const Icon(Icons.check, size: 22, color: Colors.white)
                                : Text(
                                    '${lesson.lessonNumber}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: baseColor,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and stars
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leçon ${lesson.lessonNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLocked ? Colors.grey : baseColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lesson.titleFr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? Colors.grey.shade500
                                  : const Color(0xFF1A1A2E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCompleted && lesson.stars > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(3, (i) => Icon(
                                i < lesson.stars ? Icons.star : Icons.star_border,
                                size: 16,
                                color: i < lesson.stars
                                    ? const Color(0xFFE76F51)
                                    : Colors.grey.shade400,
                              )),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isLocked && !isCompleted)
                      Icon(Icons.play_circle_fill, color: baseColor, size: 32),
                  ],
                ),
              ),
            ),
          ),
          if (isLeft) const Spacer(flex: 2),
          if (!isLeft) const SizedBox(width: 32),
        ],
      ),
    );
  }
}

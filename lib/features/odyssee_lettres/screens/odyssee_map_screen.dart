import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/odyssee_models.dart';
import '../providers/odyssee_providers.dart';

/// Main lesson list/map for L'Odyssée des Lettres.
/// Displays lessons grouped by phase with unlock progression.
class OdysseeMapScreen extends ConsumerWidget {
  const OdysseeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(odysseeLessonsProvider);
    final statsAsync = ref.watch(odysseeStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF2A9D8F),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "L'Odyssée des Lettres",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF264653), Color(0xFF2A9D8F)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                    child: statsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBadge(
                            icon: Icons.star_rounded,
                            value: '${stats.totalStars}',
                            label: 'Étoiles',
                          ),
                          _StatBadge(
                            icon: Icons.bolt_rounded,
                            value: '${stats.totalXp}',
                            label: 'XP',
                          ),
                          _StatBadge(
                            icon: Icons.abc_rounded,
                            value: '${stats.lettersLearned}/29',
                            label: 'Lettres',
                          ),
                          _StatBadge(
                            icon: Icons.check_circle_rounded,
                            value: '${stats.completedLessons}/${stats.totalLessons}',
                            label: 'Leçons',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Lessons list grouped by phase
          lessonsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Erreur: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(odysseeLessonsProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (lessons) {
              // Group lessons by phase
              final phases = <int, List<OdysseeLessonListItem>>{};
              for (final lesson in lessons) {
                phases.putIfAbsent(lesson.phaseNumber, () => []).add(lesson);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final phaseNum = phases.keys.toList()[index];
                    final phaseLessons = phases[phaseNum]!;
                    final theme = phaseThemes[phaseNum];

                    return _PhaseSection(
                      phaseNumber: phaseNum,
                      theme: theme,
                      lessons: phaseLessons,
                      onLessonTap: (ln) {
                        context.push('/odyssee/lesson/$ln');
                      },
                    );
                  },
                  childCount: phases.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}

class _PhaseSection extends StatelessWidget {
  final int phaseNumber;
  final PhaseTheme? theme;
  final List<OdysseeLessonListItem> lessons;
  final void Function(int lessonNumber) onLessonTap;

  const _PhaseSection({
    required this.phaseNumber,
    required this.theme,
    required this.lessons,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = theme != null ? Color(theme!.color) : const Color(0xFF2A9D8F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(theme?.icon ?? '📖',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phase $phaseNumber — ${theme?.name ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (theme?.description != null)
                        Text(
                          theme!.description,
                          style: TextStyle(
                              fontSize: 13, color: color.withOpacity(0.7)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lesson cards
          ...lessons.map((lesson) => _LessonTile(
                lesson: lesson,
                phaseColor: color,
                onTap: () => onLessonTap(lesson.lessonNumber),
              )),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final OdysseeLessonListItem lesson;
  final Color phaseColor;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.phaseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !lesson.isUnlocked;
    final opacity = isLocked ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lesson.isCompleted
                  ? phaseColor.withOpacity(0.4)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              if (!isLocked)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Lesson number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lesson.isCompleted
                      ? phaseColor.withOpacity(0.15)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_rounded,
                          color: Colors.grey.shade400, size: 18)
                      : Text(
                          '${lesson.lessonNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: lesson.isCompleted
                                ? phaseColor
                                : const Color(0xFF666666),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.titleFr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (lesson.titleAr != null)
                      Text(
                        lesson.titleAr!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Amiri',
                          color: Color(0xFF666666),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                  ],
                ),
              ),

              // Stars
              if (lesson.isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < lesson.stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < lesson.stars
                          ? const Color(0xFFF4A261)
                          : Colors.grey.shade300,
                      size: 20,
                    );
                  }),
                )
              else if (!isLocked)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

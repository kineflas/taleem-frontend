import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Main map screen showing the 23 lessons as a scrollable journey path.
/// - Completed parts: shown fully (lessons visible)
/// - Current part: shown fully with lesson nodes
/// - Future parts: collapsed preview (title + lesson count + lock)
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

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Group lessons by part number, preserving order.
Map<int, List<LessonListItemV2>> _groupByPart(List<LessonListItemV2> lessons) {
  final map = <int, List<LessonListItemV2>>{};
  for (final l in lessons) {
    map.putIfAbsent(l.partNumber, () => []).add(l);
  }
  return map;
}

/// Determine the "active" part = the part containing the first unlocked-but-not-completed lesson.
/// If all lessons are completed, returns the last part.
int _activePart(List<LessonListItemV2> lessons) {
  for (final l in lessons) {
    if (l.isUnlocked && !l.isCompleted) return l.partNumber;
  }
  // All completed → last part
  return lessons.isNotEmpty ? lessons.last.partNumber : 1;
}

// ── Map Body ────────────────────────────────────────────────────────────────

class _MapBody extends StatelessWidget {
  final List<LessonListItemV2> lessons;
  const _MapBody({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByPart(lessons);
    final currentPart = _activePart(lessons);
    final partNumbers = grouped.keys.toList()..sort();

    // Calculate overall progress
    final completed = lessons.where((l) => l.isCompleted).length;
    final totalStars = lessons.fold<int>(0, (s, l) => s + l.stars);

    return CustomScrollView(
      slivers: [
        // ── App bar ─────────────────────────────────────────────────
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

        // ── Diagnostic banner ───────────────────────────────────────
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => context.push('/medine-v2/diagnostic'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF2A9D8F),
              ),
              child: const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Test de placement',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
        ),

        // ── HUD bar ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2D6A4F),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _HudItem(icon: '🔥', label: '0', subtitle: 'Streak'),
                _HudItem(icon: '⭐', label: '$totalStars', subtitle: 'Étoiles'),
                _HudItem(icon: '📖', label: '$completed/${lessons.length}', subtitle: 'Leçons'),
              ],
            ),
          ),
        ),

        // ── Overall progress bar ────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Progression',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(completed / lessons.length * 100).round()} %',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: lessons.isEmpty ? 0 : completed / lessons.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Parts ───────────────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final partNum = partNumbers[index];
              final partLessons = grouped[partNum]!;
              final theme = partThemes[partNum];
              final isFuturePart = partNum > currentPart;

              if (isFuturePart) {
                return _LockedPartCard(
                  partNumber: partNum,
                  lessonCount: partLessons.length,
                  theme: theme,
                );
              }

              // Current or completed part → show full lessons
              return _ExpandedPart(
                partNumber: partNum,
                lessons: partLessons,
                theme: theme,
                isCurrentPart: partNum == currentPart,
                globalLessons: lessons,
              );
            },
            childCount: partNumbers.length,
          ),
        ),

        // Final exam node (visible when all parts are done)
        SliverToBoxAdapter(
          child: _FinalExamNode(
            allCompleted: completed == lessons.length,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── HUD Item ────────────────────────────────────────────────────────────────

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

// ── Expanded Part (current or completed) ────────────────────────────────────

class _ExpandedPart extends StatelessWidget {
  final int partNumber;
  final List<LessonListItemV2> lessons;
  final PartTheme? theme;
  final bool isCurrentPart;
  final List<LessonListItemV2> globalLessons;

  const _ExpandedPart({
    required this.partNumber,
    required this.lessons,
    required this.theme,
    required this.isCurrentPart,
    required this.globalLessons,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(theme?.color ?? 0xFF2D6A4F);
    final completedInPart = lessons.where((l) => l.isCompleted).length;

    return Column(
      children: [
        // Part header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: baseColor.withOpacity(0.3)),
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
                      'Étape $partNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: baseColor,
                      ),
                    ),
                    Text(
                      theme?.name ?? 'Partie $partNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Mini progress for this part
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: lessons.isEmpty ? 0 : completedInPart / lessons.length,
                              minHeight: 4,
                              backgroundColor: baseColor.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completedInPart/${lessons.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: baseColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lesson nodes
        ...lessons.asMap().entries.map((entry) {
          final i = entry.key;
          final lesson = entry.value;
          // Global index for alternating layout
          final globalIdx = globalLessons.indexOf(lesson);
          return _LessonNode(
            lesson: lesson,
            index: globalIdx >= 0 ? globalIdx : i,
            partColor: baseColor,
          );
        }),

        // Boss quiz node at end of part
        _BossQuizNode(
          partNumber: partNumber,
          partColor: baseColor,
          allCompleted: completedInPart == lessons.length,
        ),
      ],
    );
  }
}

// ── Locked Part Card (future parts) ─────────────────────────────────────────

class _LockedPartCard extends StatelessWidget {
  final int partNumber;
  final int lessonCount;
  final PartTheme? theme;

  const _LockedPartCard({
    required this.partNumber,
    required this.lessonCount,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(theme?.color ?? 0xFF2D6A4F);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                // Icon in a faded circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Text(
                      theme?.icon ?? '📖',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Étape $partNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme?.name ?? 'Partie $partNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '$lessonCount leçons',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Subtle bottom hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Text(
              'Termine les étapes précédentes pour débloquer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Boss Quiz Node ──────────────────────────────────────────────────────────

class _BossQuizNode extends StatelessWidget {
  final int partNumber;
  final Color partColor;
  final bool allCompleted;

  const _BossQuizNode({
    required this.partNumber,
    required this.partColor,
    required this.allCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !allCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: GestureDetector(
        onTap: isLocked ? null : () => context.push('/medine-v2/boss-quiz/$partNumber'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey.shade100 : partColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLocked ? Colors.grey.shade300 : partColor,
              width: isLocked ? 1 : 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock_outline : Icons.emoji_events,
                color: isLocked ? Colors.grey.shade400 : partColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Boss Quiz — Étape $partNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? Colors.grey.shade500 : partColor,
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: partColor.withOpacity(0.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Final Exam Node ─────────────────────────────────────────────────────────

class _FinalExamNode extends StatelessWidget {
  final bool allCompleted;

  const _FinalExamNode({required this.allCompleted});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1B4332);
    final isLocked = !allCompleted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: GestureDetector(
        onTap: isLocked ? null : () => context.push('/medine-v2/exam'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isLocked
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  ),
            color: isLocked ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? Colors.grey.shade300 : color,
              width: isLocked ? 1 : 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock_outline : Icons.school,
                color: isLocked ? Colors.grey.shade400 : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examen Final — Tome 1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey.shade500 : Colors.white,
                    ),
                  ),
                  Text(
                    isLocked
                        ? 'Termine toutes les leçons pour débloquer'
                        : '10 questions • Synthèse complète',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLocked ? Colors.grey.shade400 : Colors.white70,
                    ),
                  ),
                ],
              ),
              if (!isLocked) ...[
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lesson Node ─────────────────────────────────────────────────────────────

class _LessonNode extends StatelessWidget {
  final LessonListItemV2 lesson;
  final int index;
  final Color partColor;

  const _LessonNode({
    required this.lesson,
    required this.index,
    required this.partColor,
  });

  @override
  Widget build(BuildContext context) {
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
                          ? partColor.withOpacity(0.15)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLocked
                        ? Colors.grey.shade300
                        : partColor,
                    width: isCompleted ? 2 : 1,
                  ),
                  boxShadow: isLocked
                      ? []
                      : [
                          BoxShadow(
                            color: partColor.withOpacity(0.15),
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
                                ? partColor
                                : partColor.withOpacity(0.1),
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
                                      color: partColor,
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
                              color: isLocked ? Colors.grey : partColor,
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
                      Icon(Icons.play_circle_fill, color: partColor, size: 32),
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

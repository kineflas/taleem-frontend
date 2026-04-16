import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson_models_v2.dart';
import '../../providers/lesson_provider_v2.dart';

/// Shown instead of ObjectiveStep when a lesson is already completed.
/// Offers 3 options: review lesson, take quiz directly, or review flashcards.
class CompletedLessonEntry extends StatelessWidget {
  final LessonContentV2 lesson;
  final int stars;
  final VoidCallback onReviewLesson;
  final VoidCallback onTakeQuiz;

  const CompletedLessonEntry({
    super.key,
    required this.lesson,
    required this.stars,
    required this.onReviewLesson,
    required this.onTakeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final theme = partThemes[lesson.partNumber];
    final color = Color(theme?.color ?? 0xFF2D6A4F);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: i < stars ? 44 : 36,
                  color: i < stars ? const Color(0xFFE76F51) : Colors.grey.shade300,
                ),
              )),
            ),
            const SizedBox(height: 16),

            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Leçon ${lesson.lessonNumber} — Complétée',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lesson.titleFr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            if (lesson.titleAr != null) ...[
              const SizedBox(height: 6),
              Text(
                lesson.titleAr!,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 20,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Option cards
            _OptionCard(
              icon: Icons.replay,
              title: 'Revoir la leçon',
              subtitle: 'Reprendre du début avec découverte, dialogue et exercices',
              color: color,
              onTap: onReviewLesson,
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.quiz_outlined,
              title: 'Faire le quiz',
              subtitle: stars < 3
                  ? 'Améliore ton score pour obtenir 3 étoiles !'
                  : 'Refais le quiz pour te tester',
              color: const Color(0xFFE76F51),
              onTap: onTakeQuiz,
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.style_outlined,
              title: 'Réviser les flashcards',
              subtitle: 'Révise le vocabulaire et la grammaire de cette leçon',
              color: const Color(0xFF264653),
              onTap: () => context.go('/medine-v2/flashcards'),
            ),

            const Spacer(),

            // Back to map
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Retour à la carte',
                style: TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

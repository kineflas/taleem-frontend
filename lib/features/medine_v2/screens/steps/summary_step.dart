import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/lesson_models_v2.dart';
import '../../providers/lesson_provider_v2.dart';

/// Step 6: Celebration and summary screen.
class SummaryStep extends StatelessWidget {
  final LessonContentV2 lesson;
  final int stars;
  final int xpEarned;

  const SummaryStep({
    super.key,
    required this.lesson,
    required this.stars,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = partThemes[lesson.partNumber];
    final color = Color(theme?.color ?? 0xFF2D6A4F);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: i < stars ? 52 : 44,
                  color: i < stars ? const Color(0xFFE76F51) : Colors.grey.shade300,
                ),
              )),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Leçon ${lesson.lessonNumber} terminée !',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.titleFr,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),

            // XP earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Motivation message
            Text(
              _motivationMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),

            const Spacer(),

            // Action buttons
            Row(
              children: [
                // Review flashcards
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/medine/flashcards');
                    },
                    icon: const Text('📇', style: TextStyle(fontSize: 18)),
                    label: const Text('Réviser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Next lesson
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (lesson.lessonNumber < 23) {
                        context.go('/medine-v2/lesson/${lesson.lessonNumber + 1}');
                      } else {
                        context.go('/student/medine-v2');
                      }
                    },
                    icon: Icon(
                      lesson.lessonNumber < 23
                          ? Icons.arrow_forward
                          : Icons.emoji_events,
                    ),
                    label: Text(
                      lesson.lessonNumber < 23 ? 'Suivante' : 'Terminer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Back to map
            TextButton(
              onPressed: () => context.go('/student/medine-v2'),
              child: const Text(
                'Retour à la carte',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _motivationMessage() {
    if (stars >= 3) {
      return 'Excellent ! Tu maîtrises parfaitement cette leçon. Continue sur cette lancée !';
    } else if (stars >= 2) {
      return 'Très bien ! Tu as compris l\'essentiel. Tu peux refaire la leçon pour obtenir 3 étoiles.';
    } else {
      return 'Bon début ! N\'hésite pas à refaire cette leçon pour consolider tes acquis.';
    }
  }
}

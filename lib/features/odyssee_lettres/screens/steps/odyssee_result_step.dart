import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/odyssee_models.dart';

/// Step 6: Result — Stars, XP summary, and navigation options.
class OdysseeResultStep extends StatelessWidget {
  final OdysseeLessonContent lesson;
  final int stars;
  final int xpEarned;

  const OdysseeResultStep({
    super.key,
    required this.lesson,
    required this.stars,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    final starLabels = ['', 'Bon début !', 'Bien joué !', 'Excellent !'];
    final label = starLabels[stars.clamp(0, 3)];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Leçon terminée !',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Leçon ${lesson.lessonNumber} — ${lesson.titleFr}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < stars
                        ? const Color(0xFFF4A261)
                        : Colors.grey.shade300,
                    size: 48,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF4A261)),
            ),
            const SizedBox(height: 24),

            // XP card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFF2A9D8F), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A9D8F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Letters learned summary
            if (lesson.letters.isNotEmpty) ...[
              Text(
                'Lettres apprises :',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: lesson.letters.map((l) {
                  return Chip(
                    label: Text(
                      '${l.glyph} ${l.nameFr}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    backgroundColor:
                        const Color(0xFF2A9D8F).withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

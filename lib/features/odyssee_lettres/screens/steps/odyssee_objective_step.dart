import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';
import '../../providers/odyssee_providers.dart';

/// Step 0: Shows the lesson objective, letters to learn, and phase info.
class OdysseeObjectiveStep extends StatelessWidget {
  final OdysseeLessonContent lesson;
  final VoidCallback onStart;

  const OdysseeObjectiveStep({
    super.key,
    required this.lesson,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final phase = phaseThemes[lesson.phaseNumber];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Phase badge
            if (phase != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(phase.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${phase.icon} ${phase.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(phase.color),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Leçon ${lesson.lessonNumber}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.titleFr,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            if (lesson.titleAr != null) ...[
              const SizedBox(height: 4),
              Text(
                lesson.titleAr!,
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  color: Color(0xFF2A9D8F),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
            const SizedBox(height: 24),
            // Objective
            if (lesson.objective != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag_rounded, color: Color(0xFF2A9D8F), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Objectif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.objective!,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Letters preview
            if (lesson.letters.isNotEmpty) ...[
              const Text(
                'Lettres de cette leçon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: lesson.letters.map((letter) {
                  return Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A9D8F).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          letter.glyph,
                          style: const TextStyle(
                            fontSize: 36,
                            fontFamily: 'Amiri',
                            color: Color(0xFF1A1A2E),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          letter.nameFr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Commencer',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

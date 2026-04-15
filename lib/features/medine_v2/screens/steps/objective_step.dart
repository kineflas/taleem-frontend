import 'package:flutter/material.dart';
import '../../models/lesson_models_v2.dart';
import '../../providers/lesson_provider_v2.dart';

/// Step 1: Lesson objective splash screen (10 seconds).
class ObjectiveStep extends StatelessWidget {
  final LessonContentV2 lesson;
  final VoidCallback onStart;

  const ObjectiveStep({super.key, required this.lesson, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = partThemes[lesson.partNumber];
    final color = Color(theme?.color ?? 0xFF2D6A4F);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Part icon
              Text(theme?.icon ?? '📖', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 24),

              // Lesson number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LEÇON ${lesson.lessonNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                lesson.titleFr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              if (lesson.titleAr != null && lesson.titleAr!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    lesson.titleAr!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 22,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Objective
              if (lesson.objective != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson.objective!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              const Spacer(),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Yalla ! يَلَّا',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

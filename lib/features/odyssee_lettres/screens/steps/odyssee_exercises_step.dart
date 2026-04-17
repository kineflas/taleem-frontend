import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';
import '../../widgets/exercise_widgets.dart';

/// Step 3: Exercises — Sequential exercises with progress tracking.
class OdysseeExercisesStep extends StatefulWidget {
  final OdysseeLessonContent lesson;
  final void Function({int xp}) onComplete;

  const OdysseeExercisesStep({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<OdysseeExercisesStep> createState() => _OdysseeExercisesStepState();
}

class _OdysseeExercisesStepState extends State<OdysseeExercisesStep> {
  int _currentExercise = 0;
  int _correctCount = 0;
  int _totalAttempts = 0;

  void _onExerciseComplete({bool correct = true}) {
    _totalAttempts++;
    if (correct) _correctCount++;

    if (_currentExercise < widget.lesson.exercises.length - 1) {
      setState(() => _currentExercise++);
    } else {
      // All exercises done — calculate XP
      final xp = _correctCount * 3;
      widget.onComplete(xp: xp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.lesson.exercises;
    if (exercises.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onComplete(xp: 0));
      return const SizedBox.shrink();
    }

    final ex = exercises[_currentExercise];

    return SafeArea(
      child: Column(
        children: [
          // Exercise progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Exercice ${_currentExercise + 1}/${exercises.length}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xFF666666)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A9D8F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ex.type.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A9D8F)),
                  ),
                ),
              ],
            ),
          ),

          // Exercise content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ExerciseRouter(
                key: ValueKey('${ex.type}_$_currentExercise'),
                exercise: ex,
                onComplete: _onExerciseComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/lesson_models.dart';

/// Tab 3: Exercises — interactive drills using a subset of quiz questions
/// in a practice-style format (no time pressure, instant feedback).
class ExercisesTab extends StatefulWidget {
  final int lessonNumber;
  final List<QuizQuestion> quizQuestions;
  final VoidCallback onComplete;

  const ExercisesTab({
    super.key,
    required this.lessonNumber,
    required this.quizQuestions,
    required this.onComplete,
  });

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  late List<QuizQuestion> _exercises;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    // Take up to 5 random questions as practice exercises
    final all = List<QuizQuestion>.from(widget.quizQuestions);
    all.shuffle(Random());
    _exercises = all.take(min(5, all.length)).toList();
  }

  bool get _isFinished => _currentIndex >= _exercises.length;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _exercises[_currentIndex].correct) {
        _correctCount++;
      }
    });
  }

  void _next() {
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
    if (_isFinished) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Pas d\'exercices disponibles pour cette lecon',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_isFinished) {
      return _ResultView(
        correct: _correctCount,
        total: _exercises.length,
        onRetry: () {
          setState(() {
            _currentIndex = 0;
            _selectedOption = null;
            _answered = false;
            _correctCount = 0;
            _exercises.shuffle(Random());
          });
        },
      );
    }

    final q = _exercises[_currentIndex];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'Exercice ${_currentIndex + 1}/${_exercises.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$_correctCount correcte(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _currentIndex / _exercises.length,
            backgroundColor: AppColors.heatmapEmpty,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 20),

          // Question
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Options
          Expanded(
            child: ListView.separated(
              itemCount: q.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final isSelected = _selectedOption == i;
                final isCorrect = i == q.correct;
                Color? borderColor;
                Color? bgColor;

                if (_answered) {
                  if (isCorrect) {
                    borderColor = AppColors.success;
                    bgColor = AppColors.success.withOpacity(0.08);
                  } else if (isSelected && !isCorrect) {
                    borderColor = AppColors.danger;
                    bgColor = AppColors.danger.withOpacity(0.08);
                  }
                } else if (isSelected) {
                  borderColor = AppColors.primary;
                  bgColor = AppColors.primary.withOpacity(0.06);
                }

                return GestureDetector(
                  onTap: () => _selectOption(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor ?? AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor ?? AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (borderColor ?? AppColors.textHint).withOpacity(0.15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + i), // A, B, C, D
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: borderColor ?? AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                        if (_answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: AppColors.danger, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Explanation + Next button
          if (_answered) ...[
            if (q.explanation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  q.explanation!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_currentIndex == _exercises.length - 1 ? 'Terminer' : 'Suivant'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _ResultView({
    required this.correct,
    required this.total,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100) : 0;
    final isGood = pct >= 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGood ? Icons.emoji_events : Icons.refresh,
              size: 56,
              color: isGood ? AppColors.accent : AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              '$correct / $total',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isGood ? 'Excellent travail !' : 'Continue tes efforts !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isGood ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: const Text('Refaire les exercices'),
            ),
          ],
        ),
      ),
    );
  }
}

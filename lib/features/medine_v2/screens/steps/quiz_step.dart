import 'package:flutter/material.dart';
import '../../models/lesson_models_v2.dart';

/// Step 5: Quiz with multiple-choice questions.
class QuizStep extends StatefulWidget {
  final LessonContentV2 lesson;
  final void Function({required int stars, required int xp}) onComplete;
  final void Function(String questionId, int selected)? onAnswer;

  const QuizStep({super.key, required this.lesson, required this.onComplete, this.onAnswer});

  @override
  State<QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<QuizStep> {
  int _currentQuestion = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;
  final Stopwatch _stopwatch = Stopwatch();

  List<QuizQuestionV2> get questions => widget.lesson.quizQuestions;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
    });

    final question = questions[_currentQuestion];
    if (index == question.correct) {
      _correctCount++;
    }

    // Record the answer for backend submission
    widget.onAnswer?.call(question.id, index);

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestion < questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedOption = null;
          _answered = false;
        });
      } else {
        _stopwatch.stop();
        final score = questions.isEmpty
            ? 0.0
            : (_correctCount / questions.length * 100);
        int stars;
        if (score >= 85) {
          stars = 3;
        } else if (score >= 60) {
          stars = 2;
        } else {
          stars = 1;
        }
        final xp = _correctCount * 5;
        widget.onComplete(stars: stars, xp: xp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Pas de quiz pour cette leçon',
              style: TextStyle(color: Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.onComplete(stars: 2, xp: 10),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    }

    final question = questions[_currentQuestion];
    final isCorrect = _selectedOption == question.correct;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question ${_currentQuestion + 1} / ${questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const Spacer(),
              Text(
                '$_correctCount correct${_correctCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D6A4F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestion + 1) / questions.length,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF6C3483),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 24),

          // Question
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
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1A1A2E),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(question.options.length, (i) {
            final isSelected = _selectedOption == i;
            final isCorrectOption = i == question.correct;

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade200;

            if (_answered) {
              if (isCorrectOption) {
                bgColor = const Color(0xFFD8F3DC);
                borderColor = const Color(0xFF2D6A4F);
              } else if (isSelected && !isCorrectOption) {
                bgColor = const Color(0xFFFDEDED);
                borderColor = const Color(0xFFC0392B);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFF2D6A4F);
            }

            return GestureDetector(
              onTap: () => _selectOption(i),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF2D6A4F).withOpacity(0.1)
                            : Colors.grey.shade100,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF2D6A4F)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options[i],
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                    if (_answered && isCorrectOption)
                      const Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 22),
                    if (_answered && isSelected && !isCorrectOption)
                      const Icon(Icons.cancel, color: Color(0xFFC0392B), size: 22),
                  ],
                ),
              ),
            );
          }),

          // Explanation
          if (_answered && question.explanation != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.explanation!,
                style: TextStyle(
                  fontSize: 13,
                  color: isCorrect
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

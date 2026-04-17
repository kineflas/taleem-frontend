import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';

/// Step 5: Quiz — Multiple-choice questions with immediate feedback.
class OdysseeQuizStep extends StatefulWidget {
  final OdysseeLessonContent lesson;
  final void Function(String questionId, int selected) onAnswer;
  final void Function({required int stars, required int xp}) onComplete;

  const OdysseeQuizStep({
    super.key,
    required this.lesson,
    required this.onAnswer,
    required this.onComplete,
  });

  @override
  State<OdysseeQuizStep> createState() => _OdysseeQuizStepState();
}

class _OdysseeQuizStepState extends State<OdysseeQuizStep> {
  int _currentQuestion = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _showFeedback = false;

  List<OdysseeQuizQuestion> get _questions => widget.lesson.quizQuestions;

  void _selectOption(int index) {
    if (_showFeedback) return;
    setState(() {
      _selectedOption = index;
      _showFeedback = true;
    });

    final q = _questions[_currentQuestion];
    final isCorrect = index == q.correct;
    if (isCorrect) _correctCount++;

    // Record answer for backend
    widget.onAnswer(q.id, index);

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedOption = null;
          _showFeedback = false;
        });
      } else {
        // Quiz complete
        final total = _questions.length;
        final score = total > 0 ? (_correctCount / total * 100) : 0.0;
        final stars = score >= 85 ? 3 : score >= 60 ? 2 : 1;
        final xp = _correctCount * 5;
        widget.onComplete(stars: stars, xp: xp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onComplete(stars: 1, xp: 0));
      return const SizedBox.shrink();
    }

    final q = _questions[_currentQuestion];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question counter
            Row(
              children: [
                Text(
                  'Question ${_currentQuestion + 1}/${_questions.length}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666)),
                ),
                const Spacer(),
                Text(
                  '$_correctCount correct',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2A9D8F),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // Question progress bar
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF2A9D8F),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 24),

            // Question text
            Text(
              q.question,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: q.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = _selectedOption == index;
                  final isCorrect = index == q.correct;
                  Color bgColor = Colors.white;
                  Color borderColor = Colors.grey.shade200;
                  Color textColor = const Color(0xFF1A1A2E);

                  if (_showFeedback) {
                    if (isCorrect) {
                      bgColor = const Color(0xFF2A9D8F).withOpacity(0.15);
                      borderColor = const Color(0xFF2A9D8F);
                      textColor = const Color(0xFF2A9D8F);
                    } else if (isSelected && !isCorrect) {
                      bgColor = const Color(0xFFC0392B).withOpacity(0.1);
                      borderColor = const Color(0xFFC0392B);
                      textColor = const Color(0xFFC0392B);
                    }
                  } else if (isSelected) {
                    borderColor = const Color(0xFF2A9D8F);
                  }

                  return GestureDetector(
                    onTap: () => _selectOption(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q.options[index],
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: q.options[index]
                                        .contains(RegExp(r'[\u0600-\u06FF]'))
                                    ? 'Amiri'
                                    : null,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textDirection: q.options[index]
                                      .contains(RegExp(r'[\u0600-\u06FF]'))
                                  ? TextDirection.rtl
                                  : null,
                            ),
                          ),
                          if (_showFeedback && isCorrect)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2A9D8F)),
                          if (_showFeedback && isSelected && !isCorrect)
                            const Icon(Icons.cancel_rounded,
                                color: Color(0xFFC0392B)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Explanation
            if (_showFeedback && q.explanation != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A261).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF4A261), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.explanation!,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF444444)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

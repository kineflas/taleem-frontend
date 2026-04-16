import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Boss Quiz screen — end-of-part quiz (10 questions).
class BossQuizScreen extends ConsumerStatefulWidget {
  final int partNumber;
  const BossQuizScreen({super.key, required this.partNumber});

  @override
  ConsumerState<BossQuizScreen> createState() => _BossQuizScreenState();
}

class _BossQuizScreenState extends ConsumerState<BossQuizScreen> {
  int _currentQ = 0;
  int? _selected;
  bool _answered = false;
  final List<Map<String, dynamic>> _answers = [];
  BossQuizResult? _result;
  bool _submitting = false;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selected = index);
  }

  void _confirmAnswer(List<QuizQuestionV2> questions) {
    if (_selected == null || _answered) return;
    final q = questions[_currentQ];
    _answers.add({'question_id': q.id, 'selected': _selected});
    setState(() => _answered = true);
  }

  void _nextQuestion(List<QuizQuestionV2> questions) {
    if (_currentQ < questions.length - 1) {
      setState(() {
        _currentQ++;
        _selected = null;
        _answered = false;
      });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(medineV2ApiProvider);
      final result = await api.submitBossQuiz(
        widget.partNumber,
        answers: _answers,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(medineV2BossQuizProvider(widget.partNumber));
    final theme = partThemes[widget.partNumber];
    final color = Color(theme?.color ?? 0xFF2D6A4F);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Boss Quiz — Étape ${widget.partNumber}'),
        centerTitle: true,
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (quiz) {
          if (_result != null) return _buildResult(quiz, color);
          if (_submitting) return const Center(child: CircularProgressIndicator());
          return _buildQuestion(quiz, color);
        },
      ),
    );
  }

  Widget _buildQuestion(BossQuizContent quiz, Color color) {
    final q = quiz.questions[_currentQ];
    final isCorrect = _answered && _selected == q.correct;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: [
                Text(
                  'Question ${_currentQ + 1}/${quiz.questions.length}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
                const Spacer(),
                Text(
                  '${quiz.title.split('(').last.replaceAll(')', '')}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQ + 1) / quiz.questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...q.options.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final isSelected = _selected == i;
              final isCorrectOption = q.correct == i;

              Color bgColor = Colors.white;
              Color borderColor = Colors.grey.shade300;
              if (_answered) {
                if (isCorrectOption) {
                  bgColor = const Color(0xFFD4EDDA);
                  borderColor = const Color(0xFF28A745);
                } else if (isSelected && !isCorrectOption) {
                  bgColor = const Color(0xFFF8D7DA);
                  borderColor = const Color(0xFFDC3545);
                }
              } else if (isSelected) {
                bgColor = color.withOpacity(0.1);
                borderColor = color;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _selectOption(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                    ),
                    child: Text(
                      option,
                      textDirection: _isArabicHeavy(option) ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF1A1A2E),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Explanation
            if (_answered && q.explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFD4EDDA)
                      : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.info_outline,
                      size: 20,
                      color: isCorrect ? const Color(0xFF28A745) : const Color(0xFFF4A261),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.explanation!,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF333333)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Confirm / Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answered
                    ? () => _nextQuestion(quiz.questions)
                    : (_selected != null ? () => _confirmAnswer(quiz.questions) : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _answered
                      ? (_currentQ < quiz.questions.length - 1 ? 'Suivante' : 'Voir les résultats')
                      : 'Confirmer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BossQuizContent quiz, Color color) {
    final result = _result!;
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
                  i < result.stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: i < result.stars ? 52 : 44,
                  color: i < result.stars ? const Color(0xFFE76F51) : Colors.grey.shade300,
                ),
              )),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              result.passed ? 'Boss Quiz réussi !' : 'Boss Quiz échoué',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: result.passed ? color : const Color(0xFFC0392B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${result.correct}/${result.total} — ${result.score.round()}%',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 12),

            // XP
            Text(
              '+${result.xpEarned} XP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 16),

            Text(
              result.passed
                  ? 'Excellent ! Tu maîtrises cette étape.'
                  : 'Continue à réviser les leçons de cette partie et réessaye !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.4),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.invalidate(medineV2LessonsProvider);
                  context.go('/student/medine-v2');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Retour à la carte', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isArabicHeavy(String text) {
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    return arabicChars > text.length * 0.3;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Final comprehensive exam screen covering all 23 lessons.
class FinalExamScreen extends ConsumerStatefulWidget {
  const FinalExamScreen({super.key});

  @override
  ConsumerState<FinalExamScreen> createState() => _FinalExamScreenState();
}

class _FinalExamScreenState extends ConsumerState<FinalExamScreen> {
  int _currentQ = 0;
  int? _selected;
  bool _answered = false;
  final List<Map<String, dynamic>> _answers = [];
  BossQuizResult? _result;
  bool _submitting = false;

  static const _color = Color(0xFF1B4332);

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
      _submitExam();
    }
  }

  Future<void> _submitExam() async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(medineV2ApiProvider);
      final result = await api.submitFinalExam(answers: _answers);
      if (mounted) setState(() { _result = result; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(medineV2FinalExamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Examen Final — Tome 1'),
        centerTitle: true,
      ),
      body: examAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (exam) {
          if (_result != null) return _buildResult(exam);
          if (_submitting) return const Center(child: CircularProgressIndicator());
          return _buildQuestion(exam);
        },
      ),
    );
  }

  Widget _buildQuestion(FinalExamContent exam) {
    final q = exam.questions[_currentQ];
    final isCorrect = _answered && _selected == q.correct;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${_currentQ + 1}/${exam.questions.length}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _color),
                ),
                const Spacer(),
                const Text('Examen Final', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQ + 1) / exam.questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(_color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              q.question,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), height: 1.4),
            ),
            const SizedBox(height: 20),

            ...q.options.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final isSelected = _selected == i;
              final isCorrectOpt = q.correct == i;

              Color bgColor = Colors.white;
              Color borderColor = Colors.grey.shade300;
              if (_answered) {
                if (isCorrectOpt) { bgColor = const Color(0xFFD4EDDA); borderColor = const Color(0xFF28A745); }
                else if (isSelected) { bgColor = const Color(0xFFF8D7DA); borderColor = const Color(0xFFDC3545); }
              } else if (isSelected) {
                bgColor = _color.withOpacity(0.1); borderColor = _color;
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
                      textDirection: _isArabic(option) ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                ),
              );
            }),

            if (_answered && q.explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? const Color(0xFFD4EDDA) : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(isCorrect ? Icons.check_circle : Icons.info_outline, size: 20,
                      color: isCorrect ? const Color(0xFF28A745) : const Color(0xFFF4A261)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q.explanation!, style: const TextStyle(fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answered
                    ? () => _nextQuestion(exam.questions)
                    : (_selected != null ? () => _confirmAnswer(exam.questions) : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _answered ? (_currentQ < exam.questions.length - 1 ? 'Suivante' : 'Voir les résultats') : 'Confirmer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(FinalExamContent exam) {
    final result = _result!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(result.passed ? '🏆' : '📖', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < result.stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: i < result.stars ? 48 : 40,
                  color: i < result.stars ? const Color(0xFFE76F51) : Colors.grey.shade300,
                ),
              )),
            ),
            const SizedBox(height: 16),
            Text(
              result.passed ? 'Tome 1 — Maîtrisé !' : 'Continue tes efforts !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: result.passed ? _color : const Color(0xFFC0392B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${result.correct}/${result.total} — ${result.score.round()}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            const SizedBox(height: 8),
            Text('+${result.xpEarned} XP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _color)),
            const SizedBox(height: 16),
            Text(
              result.passed
                  ? 'Félicitations ! Tu as maîtrisé le Tome 1 de Médine. Tu es prêt pour le Tome 2 !'
                  : 'Révise les leçons et les flashcards, puis réessaie l\'examen.',
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
                  backgroundColor: _color,
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

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').allMatches(text).length > text.length * 0.3;
  }
}

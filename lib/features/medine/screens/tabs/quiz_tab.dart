import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/star_display.dart';

/// Tab 4: Quiz — timed, scored quiz submitted to backend.
/// Sends answers to POST /api/lessons/{n}/quiz/submit.
class QuizTab extends ConsumerStatefulWidget {
  final int lessonNumber;
  final List<QuizQuestion> questions;
  final void Function(QuizResult result) onComplete;

  const QuizTab({
    super.key,
    required this.lessonNumber,
    required this.questions,
    required this.onComplete,
  });

  @override
  ConsumerState<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<QuizTab> {
  // Quiz state
  bool _started = false;
  int _currentIndex = 0;
  final Map<String, int> _answers = {};
  bool _submitting = false;
  QuizResult? _result;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTimer;
  String _elapsed = '0:00';

  @override
  void dispose() {
    _displayTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startQuiz() {
    setState(() => _started = true);
    _stopwatch.start();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = _stopwatch.elapsed.inSeconds;
      setState(() => _elapsed = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}');
    });
  }

  void _selectAnswer(String questionId, int selected) {
    setState(() => _answers[questionId] = selected);
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    _stopwatch.stop();
    _displayTimer?.cancel();
    setState(() => _submitting = true);

    final answers = _answers.entries
        .map((e) => {'question_id': e.key, 'selected': e.value})
        .toList();

    try {
      final result = await ref.read(medineLessonApiProvider).submitQuiz(
            widget.lessonNumber,
            answers: answers,
            timeMs: _stopwatch.elapsedMilliseconds,
          );
      setState(() {
        _result = result;
        _submitting = false;
      });
      widget.onComplete(result);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Pas de quiz disponible pour cette lecon',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_result != null) return _QuizResultView(result: _result!);
    if (!_started) return _QuizIntro(questionCount: widget.questions.length, onStart: _startQuiz);
    if (_submitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Envoi des reponses...'),
          ],
        ),
      );
    }

    final q = widget.questions[_currentIndex];
    final selectedAnswer = _answers[q.id];
    final allAnswered = _answers.length == widget.questions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: timer + progress
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _elapsed,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1} / ${widget.questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: AppColors.heatmapEmpty,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
          const SizedBox(height: 20),

          // Question dots (navigation)
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.questions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final isActive = i == _currentIndex;
                final isAnswered = _answers.containsKey(widget.questions[i].id);
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : isAnswered
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.surfaceVariant,
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Question text
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Options
          Expanded(
            child: ListView.separated(
              itemCount: q.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final isSelected = selectedAnswer == i;
                return GestureDetector(
                  onTap: () => _selectAnswer(q.id, i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
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
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textHint.withOpacity(0.15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation + Submit
          const SizedBox(height: 8),
          Row(
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: _prevQuestion,
                  child: const Text('Precedent'),
                ),
              const Spacer(),
              if (_currentIndex < widget.questions.length - 1)
                ElevatedButton(
                  onPressed: selectedAnswer != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Suivant'),
                )
              else if (allAnswered)
                ElevatedButton.icon(
                  onPressed: _submitQuiz,
                  icon: const Icon(Icons.send),
                  label: const Text('Soumettre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────

class _QuizIntro extends StatelessWidget {
  final int questionCount;
  final VoidCallback onStart;

  const _QuizIntro({required this.questionCount, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz, size: 56, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz Final',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$questionCount questions',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Repondez rapidement pour gagner des XP bonus !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final QuizResult result;
  const _QuizResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.score;
    Color scoreColor;
    String message;
    if (pct >= 85) {
      scoreColor = AppColors.success;
      message = 'Excellent ! Tu maitrises cette lecon !';
    } else if (pct >= 60) {
      scoreColor = AppColors.warning;
      message = 'Bon travail ! Continue tes efforts.';
    } else {
      scoreColor = AppColors.danger;
      message = 'Revise le cours et reessaie !';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars
            StarDisplay(stars: result.stars, size: 40),
            const SizedBox(height: 16),

            // Score
            Text(
              '${pct.round()}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              '${result.correct} / ${result.total} correctes',
              style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 16),

            // XP earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.accent, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '+${result.xpEarned} XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

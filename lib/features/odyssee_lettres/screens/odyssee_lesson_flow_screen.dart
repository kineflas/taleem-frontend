import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/odyssee_models.dart';
import '../providers/odyssee_providers.dart';
import 'steps/odyssee_objective_step.dart';
import 'steps/odyssee_ecoute_step.dart';
import 'steps/odyssee_discovery_step.dart';
import 'steps/odyssee_exercises_step.dart';
import 'steps/odyssee_mini_lecture_step.dart';
import 'steps/odyssee_quiz_step.dart';
import 'steps/odyssee_result_step.dart';

/// Orchestrates the 7-step sequential Odyssée lesson flow:
/// 0: Objectif → 1: Écoute → 2: Découverte → 3: Exercices
/// → 4: Mini-lecture → 5: Quiz → 6: Résultat
class OdysseeLessonFlowScreen extends ConsumerStatefulWidget {
  final int lessonNumber;
  const OdysseeLessonFlowScreen({super.key, required this.lessonNumber});

  @override
  ConsumerState<OdysseeLessonFlowScreen> createState() =>
      _OdysseeLessonFlowScreenState();
}

class _OdysseeLessonFlowScreenState
    extends ConsumerState<OdysseeLessonFlowScreen> {
  /// -1 = completed lesson entry, 0..6 = normal 7-step flow
  int _currentStep = 0;
  int _quizStars = 0;
  int _xpEarned = 0;
  int _existingStars = 0;
  OdysseeLessonContent? _lesson;
  bool _checkedCompletion = false;

  static const _stepLabels = [
    'Objectif',
    'Écoute',
    'Découverte',
    'Exercices',
    'Mini-lecture',
    'Quiz',
    'Résultat',
  ];

  static const _totalSteps = 7;

  void _nextStep({int stars = 0, int xp = 0}) {
    setState(() {
      if (stars > 0) _quizStars = stars;
      _xpEarned += xp;
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      }
    });

    // When reaching the result step (step 6), submit results to backend
    if (_currentStep == _totalSteps - 1) {
      _submitResults();
    }
  }

  List<Map<String, dynamic>> _quizAnswers = [];

  void _recordQuizAnswer(String questionId, int selected) {
    _quizAnswers.add({'question_id': questionId, 'selected': selected});
  }

  Future<void> _submitResults() async {
    try {
      final api = ref.read(odysseeLettresApiProvider);
      final lesson = _lesson;
      if (lesson == null) return;

      // Mark intermediate steps as done
      await api.updateProgress(widget.lessonNumber, 'ecoute');
      await api.updateProgress(widget.lessonNumber, 'discovery');
      await api.updateProgress(widget.lessonNumber, 'exercises');
      await api.updateProgress(widget.lessonNumber, 'mini_lecture');

      if (lesson.quizQuestions.isNotEmpty && _quizAnswers.isNotEmpty) {
        final result = await api.submitQuiz(
          widget.lessonNumber,
          answers: _quizAnswers,
          timeMs: 0,
        );
        if (mounted) {
          setState(() {
            _quizStars = result.stars;
            _xpEarned = result.xpEarned;
          });
        }
      } else {
        final score =
            _quizStars >= 3 ? 100.0 : _quizStars >= 2 ? 75.0 : 50.0;
        await api.updateProgress(widget.lessonNumber, 'quiz', value: score);
      }

      dev.log(
          'Odyssée lesson ${widget.lessonNumber} results submitted (stars: $_quizStars)');
    } catch (e) {
      dev.log('Failed to submit Odyssée lesson results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progression non sauvegardée (hors ligne ?)'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  void dispose() {
    // Invalidate after the frame to avoid using ref during dispose
    final container = ProviderScope.containerOf(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      container.invalidate(odysseeLessonsProvider);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(odysseeLessonProvider(widget.lessonNumber));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    odysseeLessonProvider(widget.lessonNumber)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (lesson) {
          _lesson = lesson;

          // Check if lesson is already completed (once)
          if (!_checkedCompletion) {
            _checkedCompletion = true;
            final lessonsState = ref.read(odysseeLessonsProvider);
            lessonsState.whenData((lessons) {
              final matches = lessons
                  .where((l) => l.lessonNumber == widget.lessonNumber);
              final item = matches.isEmpty ? null : matches.first;
              if (item != null && item.isCompleted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentStep = -1;
                      _existingStars = item.stars;
                    });
                  }
                });
              }
            });
          }

          // Completed lesson entry screen
          if (_currentStep == -1) {
            return _CompletedLessonEntry(
              lesson: lesson,
              stars: _existingStars,
              onReviewLesson: () => setState(() => _currentStep = 0),
              onTakeQuiz: () => setState(() {
                _quizAnswers = [];
                _quizStars = 0;
                _currentStep = 5;
              }),
            );
          }

          return _OdysseeLessonBody(
            lesson: lesson,
            currentStep: _currentStep,
            quizStars: _quizStars,
            xpEarned: _xpEarned,
            onNext: _nextStep,
            onBack: _goBack,
            onExit: () {
              ref.invalidate(odysseeLessonsProvider);
              if (context.mounted) context.pop();
            },
            onQuizAnswer: _recordQuizAnswer,
          );
        },
      ),
    );
  }
}

// ── Lesson Body ─────────────────────────────────────────────────────────────

class _OdysseeLessonBody extends StatelessWidget {
  final OdysseeLessonContent lesson;
  final int currentStep;
  final int quizStars;
  final int xpEarned;
  final void Function({int stars, int xp}) onNext;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final void Function(String questionId, int selected) onQuizAnswer;

  const _OdysseeLessonBody({
    required this.lesson,
    required this.currentStep,
    required this.quizStars,
    required this.xpEarned,
    required this.onNext,
    required this.onBack,
    required this.onExit,
    required this.onQuizAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with progress (not on first and last steps)
        if (currentStep > 0 && currentStep < 6)
          _OdysseeProgressBar(
            currentStep: currentStep,
            lesson: lesson,
            onBack: onBack,
            onExit: onExit,
          ),

        // Step content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (currentStep) {
      case 0:
        return OdysseeObjectiveStep(
          key: const ValueKey('objective'),
          lesson: lesson,
          onStart: () => onNext(),
        );
      case 1:
        return OdysseeEcouteStep(
          key: const ValueKey('ecoute'),
          lesson: lesson,
          onComplete: () => onNext(),
        );
      case 2:
        return OdysseeDiscoveryStep(
          key: const ValueKey('discovery'),
          lesson: lesson,
          onComplete: () => onNext(),
        );
      case 3:
        return OdysseeExercisesStep(
          key: const ValueKey('exercises'),
          lesson: lesson,
          onComplete: ({int xp = 0}) => onNext(xp: xp),
        );
      case 4:
        return OdysseeMiniLectureStep(
          key: const ValueKey('mini_lecture'),
          lesson: lesson,
          onComplete: () => onNext(),
        );
      case 5:
        return OdysseeQuizStep(
          key: const ValueKey('quiz'),
          lesson: lesson,
          onAnswer: onQuizAnswer,
          onComplete: ({required int stars, required int xp}) =>
              onNext(stars: stars, xp: xp),
        );
      case 6:
        return OdysseeResultStep(
          key: const ValueKey('result'),
          lesson: lesson,
          stars: quizStars,
          xpEarned: xpEarned,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Progress Bar ────────────────────────────────────────────────────────────

class _OdysseeProgressBar extends StatelessWidget {
  final int currentStep;
  final OdysseeLessonContent lesson;
  final VoidCallback onBack;
  final VoidCallback onExit;

  const _OdysseeProgressBar({
    required this.currentStep,
    required this.lesson,
    required this.onBack,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
              onPressed: () => _showExitDialog(context),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentStep / 6,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF2A9D8F),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leçon ${lesson.lessonNumber} — ${_stepName(currentStep)}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepName(int step) {
    const names = [
      'Objectif', 'Écoute', 'Découverte', 'Exercices',
      'Mini-lecture', 'Quiz', 'Résultat',
    ];
    return names[step.clamp(0, 6)];
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la leçon ?'),
        content:
            const Text('Ta progression dans cette leçon sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onExit();
            },
            child: const Text('Quitter',
                style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
  }
}

// ── Completed Lesson Entry ──────────────────────────────────────────────────

class _CompletedLessonEntry extends StatelessWidget {
  final OdysseeLessonContent lesson;
  final int stars;
  final VoidCallback onReviewLesson;
  final VoidCallback onTakeQuiz;

  const _CompletedLessonEntry({
    required this.lesson,
    required this.stars,
    required this.onReviewLesson,
    required this.onTakeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < stars
                      ? const Color(0xFFF4A261)
                      : Colors.grey.shade300,
                  size: 40,
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Leçon ${lesson.lessonNumber}',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.titleFr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu as déjà terminé cette leçon !',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReviewLesson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Revoir la leçon',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTakeQuiz,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF2A9D8F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Refaire le quiz',
                    style: TextStyle(
                        fontSize: 16, color: Color(0xFF2A9D8F))),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Retour',
                  style: TextStyle(color: Color(0xFF666666))),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';
import 'steps/completed_lesson_entry.dart';
import 'steps/objective_step.dart';
import 'steps/discovery_step.dart';
import 'steps/dialogue_step.dart';
import 'steps/practice_step.dart';
import 'steps/quiz_step.dart';
import 'steps/summary_step.dart';

/// Orchestrates the 6-step sequential lesson flow.
class LessonFlowScreen extends ConsumerStatefulWidget {
  final int lessonNumber;
  const LessonFlowScreen({super.key, required this.lessonNumber});

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  /// -1 = completed lesson entry screen, 0..5 = normal flow
  int _currentStep = 0;
  int _quizStars = 0;
  int _xpEarned = 0;
  int _existingStars = 0;
  LessonContentV2? _lesson;
  bool _checkedCompletion = false;

  static const _stepLabels = [
    'Objectif',
    'Découverte',
    'Dialogue',
    'Pratique',
    'Défi',
    'Résumé',
  ];

  void _nextStep({int stars = 0, int xp = 0}) {
    setState(() {
      if (stars > 0) _quizStars = stars;
      _xpEarned += xp;
      if (_currentStep < 5) {
        _currentStep++;
      }
    });

    // When reaching the summary step (step 5), submit results to backend
    if (_currentStep == 5) {
      _submitResults();
    }
  }

  // Store the user's actual quiz answers for backend submission
  List<Map<String, dynamic>> _quizAnswers = [];

  void _recordQuizAnswer(String questionId, int selected) {
    _quizAnswers.add({'question_id': questionId, 'selected': selected});
  }

  /// Submit quiz results to backend so the lesson is marked complete
  /// and the next lesson gets unlocked.
  Future<void> _submitResults() async {
    try {
      final api = ref.read(medineV2ApiProvider);
      final lesson = _lesson;
      if (lesson == null) return;

      if (lesson.quizQuestions.isNotEmpty && _quizAnswers.isNotEmpty) {
        // Submit actual quiz answers → backend calculates authoritative score
        final result = await api.submitQuiz(
          widget.lessonNumber,
          answers: _quizAnswers,
          timeMs: 0,
        );
        // Use backend's authoritative stars (overwrites local calculation)
        if (mounted) {
          setState(() {
            _quizStars = result.stars;
            _xpEarned = result.xpEarned;
          });
        }
      } else {
        // No quiz questions → still mark lesson as complete via progress endpoint
        final score = _quizStars >= 3 ? 100.0 : _quizStars >= 2 ? 75.0 : 50.0;
        await api.updateProgress(widget.lessonNumber, 'quiz', value: score);
      }

      dev.log('Lesson ${widget.lessonNumber} results submitted to backend (stars: $_quizStars)');
    } catch (e) {
      dev.log('Failed to submit lesson results: $e');
      // Show feedback so user knows progress wasn't saved
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
    // Invalidate the lessons list so the map re-fetches with updated unlock states
    ref.invalidate(medineV2LessonsProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(medineV2LessonProvider(widget.lessonNumber));

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
                onPressed: () => ref.invalidate(medineV2LessonProvider(widget.lessonNumber)),
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
            final lessonsState = ref.read(medineV2LessonsProvider);
            lessonsState.whenData((lessons) {
              final matches = lessons.where((l) => l.lessonNumber == widget.lessonNumber);
              final item = matches.isEmpty ? null : matches.first;
              if (item != null && item.isCompleted) {
                // Show completed entry screen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {
                    _currentStep = -1;
                    _existingStars = item.stars;
                  });
                });
              }
            });
          }

          // Completed lesson entry screen
          if (_currentStep == -1) {
            return CompletedLessonEntry(
              lesson: lesson,
              stars: _existingStars,
              onReviewLesson: () => setState(() => _currentStep = 0),
              onTakeQuiz: () => setState(() => _currentStep = 4),
            );
          }

          return _LessonBody(
            lesson: lesson,
            currentStep: _currentStep,
            quizStars: _quizStars,
            xpEarned: _xpEarned,
            onNext: _nextStep,
            onBack: _goBack,
            onExit: () {
              ref.invalidate(medineV2LessonsProvider);
              if (context.mounted) context.pop();
            },
            onQuizAnswer: _recordQuizAnswer,
          );
        },
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  final LessonContentV2 lesson;
  final int currentStep;
  final int quizStars;
  final int xpEarned;
  final void Function({int stars, int xp}) onNext;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final void Function(String questionId, int selected) onQuizAnswer;

  const _LessonBody({
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
        // Top bar with progress
        if (currentStep > 0 && currentStep < 5)
          _ProgressBar(
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
        return ObjectiveStep(
          key: const ValueKey('objective'),
          lesson: lesson,
          onStart: () => onNext(),
        );
      case 1:
        return DiscoveryStep(
          key: const ValueKey('discovery'),
          lesson: lesson,
          onComplete: () => onNext(),
        );
      case 2:
        return DialogueStep(
          key: const ValueKey('dialogue'),
          lesson: lesson,
          onComplete: () => onNext(),
        );
      case 3:
        return PracticeStep(
          key: const ValueKey('practice'),
          lesson: lesson,
          onComplete: ({int xp = 0}) => onNext(xp: xp),
        );
      case 4:
        return QuizStep(
          key: const ValueKey('quiz'),
          lesson: lesson,
          onAnswer: onQuizAnswer,
          onComplete: ({required int stars, required int xp}) =>
              onNext(stars: stars, xp: xp),
        );
      case 5:
        return SummaryStep(
          key: const ValueKey('summary'),
          lesson: lesson,
          stars: quizStars,
          xpEarned: xpEarned,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  final LessonContentV2 lesson;
  final VoidCallback onBack;
  final VoidCallback onExit;

  const _ProgressBar({
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
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentStep / 5,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF2D6A4F),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leçon ${lesson.lessonNumber} — ${_stepName(currentStep)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
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
    const names = ['Objectif', 'Découverte', 'Dialogue', 'Pratique', 'Défi', 'Résumé'];
    return names[step.clamp(0, 5)];
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la leçon ?'),
        content: const Text('Ta progression dans cette leçon sera perdue.'),
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
            child: const Text('Quitter', style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
  }
}

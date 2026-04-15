import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';
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
  int _currentStep = 0;
  int _quizStars = 0;
  int _xpEarned = 0;

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
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
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
        data: (lesson) => _LessonBody(
          lesson: lesson,
          currentStep: _currentStep,
          quizStars: _quizStars,
          xpEarned: _xpEarned,
          onNext: _nextStep,
          onBack: _goBack,
        ),
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

  const _LessonBody({
    required this.lesson,
    required this.currentStep,
    required this.quizStars,
    required this.xpEarned,
    required this.onNext,
    required this.onBack,
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

  const _ProgressBar({
    required this.currentStep,
    required this.lesson,
    required this.onBack,
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
              context.pop();
            },
            child: const Text('Quitter', style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
  }
}

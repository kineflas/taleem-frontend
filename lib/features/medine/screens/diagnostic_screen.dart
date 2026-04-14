import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/diagnostic_models.dart';
import '../providers/diagnostic_provider.dart';

/// CAT Diagnostic Screen — adaptive placement test with 3 pools (A/B/C).
class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  // States: intro → loading → question → feedback → result
  bool _intro = true;
  bool _loading = false;
  String? _sessionId;
  DiagnosticQuestion? _currentQuestion;
  String _currentPool = 'A';
  int _questionIndex = 0;
  int? _selectedOption;
  bool _showFeedback = false;
  bool? _wasCorrect;
  String? _explanation;
  DiagnosticResult? _result;
  int _totalAnswered = 0;

  Future<void> _startDiagnostic() async {
    setState(() {
      _intro = false;
      _loading = true;
    });

    try {
      final session = await ref.read(diagnosticApiProvider).startSession();
      setState(() {
        _sessionId = session.sessionId;
        _currentQuestion = session.question;
        _currentPool = session.currentPool;
        _questionIndex = session.questionIndex;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_sessionId == null || _currentQuestion == null || _selectedOption == null) return;
    setState(() => _loading = true);

    try {
      final response = await ref.read(diagnosticApiProvider).submitAnswer(
            _sessionId!,
            questionId: _currentQuestion!.id,
            selected: _selectedOption!,
          );

      _totalAnswered++;

      if (response.isCompleted) {
        // Fetch result
        final result = await ref.read(diagnosticApiProvider).getResult(_sessionId!);
        setState(() {
          _result = result;
          _loading = false;
        });
      } else {
        setState(() {
          _wasCorrect = response.isCorrect;
          _explanation = response.explanation;
          _showFeedback = true;
          _loading = false;
          // Queue next question
          _currentQuestion = response.nextQuestion;
          _currentPool = response.currentPool;
          _questionIndex = response.questionIndex;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _showFeedback = false;
      _selectedOption = null;
      _wasCorrect = null;
      _explanation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Test Diagnostique', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _result != null
          ? _ResultView(result: _result!)
          : _intro
              ? _IntroView(onStart: _startDiagnostic)
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _showFeedback
                      ? _FeedbackView(
                          isCorrect: _wasCorrect ?? false,
                          explanation: _explanation,
                          onNext: _nextQuestion,
                        )
                      : _currentQuestion != null
                          ? _QuestionView(
                              question: _currentQuestion!,
                              pool: _currentPool,
                              questionNumber: _totalAnswered + 1,
                              selectedOption: _selectedOption,
                              onSelect: (i) => setState(() => _selectedOption = i),
                              onSubmit: _submitAnswer,
                            )
                          : const Center(child: Text('Erreur inattendue')),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 64, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test de Placement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ce test adaptatif evaluera votre niveau en arabe.\n\n'
              'Il comporte 3 niveaux (A, B, C) de difficulte croissante. '
              'Si vous repondez correctement, le test passera au niveau superieur. '
              'Sinon, il s\'arretera et vous donnera un parcours personnalise.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Duree estimee : 5-10 minutes\nPas de pression — repondez a votre rythme.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer le test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(240, 52),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final DiagnosticQuestion question;
  final String pool;
  final int questionNumber;
  final int? selectedOption;
  final void Function(int) onSelect;
  final VoidCallback onSubmit;

  const _QuestionView({
    required this.question,
    required this.pool,
    required this.questionNumber,
    required this.selectedOption,
    required this.onSelect,
    required this.onSubmit,
  });

  String get _poolLabel {
    switch (pool) {
      case 'A':
        return 'Debutant';
      case 'B':
        return 'Intermediaire';
      case 'C':
        return 'Avance';
      default:
        return pool;
    }
  }

  Color get _poolColor {
    switch (pool) {
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.warning;
      case 'C':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pool badge + question number
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _poolColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Niveau $_poolLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _poolColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hint
          if (question.adaptiveHint != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.adaptiveHint!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Question text
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Options
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final isSelected = selectedOption == i;
                return GestureDetector(
                  onTap: () => onSelect(i),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Submit
          ElevatedButton(
            onPressed: selectedOption != null ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _FeedbackView extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback onNext;

  const _FeedbackView({
    required this.isCorrect,
    this.explanation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: isCorrect ? AppColors.success : AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Correct !' : 'Incorrect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCorrect ? AppColors.success : AppColors.danger,
              ),
            ),
            if (explanation != null) ...[
              const SizedBox(height: 12),
              Text(
                explanation!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Question suivante'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final DiagnosticResult result;
  const _ResultView({required this.result});

  String get _levelEmoji {
    switch (result.level) {
      case 'explorateur':
        return 'Explorateur';
      case 'voyageur':
        return 'Voyageur';
      case 'chercheur':
        return 'Chercheur';
      case 'savant':
        return 'Savant';
      case 'gardien':
        return 'Gardien de Medine';
      default:
        return result.level;
    }
  }

  IconData get _levelIcon {
    switch (result.level) {
      case 'explorateur':
        return Icons.explore;
      case 'voyageur':
        return Icons.flight;
      case 'chercheur':
        return Icons.search;
      case 'savant':
        return Icons.school;
      case 'gardien':
        return Icons.shield;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
              child: Icon(_levelIcon, size: 56, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              _levelEmoji,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Score : ${result.score} / 10',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (result.levelMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                result.levelMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (result.estimatedDuration != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Duree estimee : ${result.estimatedDuration}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.menu_book),
              label: const Text('Commencer les lecons'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(240, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

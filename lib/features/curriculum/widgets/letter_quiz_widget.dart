import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';

enum QuizMode { position, letter }

/// Self-contained quiz widget shown as a bottom sheet.
/// - **position**: "Quelle lettre est-ce ?" — shows a glyph, 4 name choices.
/// - **letter**: "Quelle est la position ?" — shows a glyph, 4 position choices.
class LetterQuizWidget extends StatefulWidget {
  final QuizMode mode;
  final List<CurriculumItem> items; // items to quiz on
  final VoidCallback onComplete;

  const LetterQuizWidget({
    super.key,
    required this.mode,
    required this.items,
    required this.onComplete,
  });

  @override
  State<LetterQuizWidget> createState() => _LetterQuizWidgetState();
}

class _LetterQuizWidgetState extends State<LetterQuizWidget> {
  late List<_QuizQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
  }

  List<_QuizQuestion> _generateQuestions() {
    final rng = Random();

    if (widget.mode == QuizMode.position) {
      // For each item: show the glyph, ask "Quelle lettre est-ce ?"
      // Choices = correct name + 3 random other names
      return widget.items.map((item) {
        final correctName = item.titleFr?.split(' — ').first ?? item.titleAr;
        final wrongNames = allLetterNames
            .where((n) => n != correctName && n != glyphToName[item.titleAr])
            .toList()
          ..shuffle(rng);
        final choices = [correctName, ...wrongNames.take(3)]..shuffle(rng);
        return _QuizQuestion(
          displayAr: item.titleAr,
          questionFr: 'Quelle lettre est-ce ?',
          correctAnswer: correctName,
          choices: choices,
        );
      }).toList()
        ..shuffle(rng);
    } else {
      // Letter mode: for each item, show glyph, ask position
      final positionLabels = {
        'isolated': 'Isolée',
        'initial': 'Initiale',
        'medial': 'Médiane',
        'final': 'Finale',
      };
      return widget.items
          .where((i) => i.letterPosition != null)
          .map((item) {
        final correctPos = positionLabels[item.letterPosition] ?? '';
        final choices = positionLabels.values.toList()..shuffle(rng);
        return _QuizQuestion(
          displayAr: item.titleAr,
          questionFr: 'Quelle est la position de cette forme ?',
          correctAnswer: correctPos,
          choices: choices,
        );
      }).toList()
        ..shuffle(rng);
    }
  }

  void _onSelect(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == _questions[_currentIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _next() {
    if (_currentIndex + 1 >= _questions.length) {
      // Show results
      setState(() => _currentIndex = -1); // signal for results
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Aucune question disponible.'),
      );
    }

    // Results screen
    if (_currentIndex == -1) return _buildResults();

    final q = _questions[_currentIndex];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              Text(
                'Score : $_score',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question
          Text(
            q.questionFr,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Displayed glyph
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Center(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  q.displayAr,
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Choices
          ...q.choices.map((choice) {
            Color bgColor = Colors.white;
            Color borderColor = Colors.grey[300]!;
            Color textColor = Colors.black87;

            if (_answered) {
              if (choice == q.correctAnswer) {
                bgColor = AppColors.success.withOpacity(0.12);
                borderColor = AppColors.success;
                textColor = AppColors.success;
              } else if (choice == _selectedAnswer) {
                bgColor = AppColors.danger.withOpacity(0.12);
                borderColor = AppColors.danger;
                textColor = AppColors.danger;
              }
            } else if (choice == _selectedAnswer) {
              borderColor = AppColors.primary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onSelect(choice),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),

          // Next button
          if (_answered) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _next,
                child: Text(
                  _currentIndex + 1 >= _questions.length
                      ? 'Voir les résultats'
                      : 'Suivant',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final total = _questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;
    final isGood = pct >= 75;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Result icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isGood ? AppColors.success : AppColors.accent)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.emoji_events : Icons.refresh,
              size: 40,
              color: isGood ? AppColors.success : AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isGood ? 'Excellent !' : 'Continuez vos efforts !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isGood ? AppColors.success : AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '$_score / $total ($pct %)',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isGood
                ? 'Vous maîtrisez bien cette lettre.'
                : 'Révisez les positions et réessayez.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    // Retry
                    setState(() {
                      _questions = _generateQuestions();
                      _currentIndex = 0;
                      _score = 0;
                      _selectedAnswer = null;
                      _answered = false;
                    });
                  },
                  child: Text('Recommencer',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onComplete();
                  },
                  child: Text('Fermer',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  final String displayAr;
  final String questionFr;
  final String correctAnswer;
  final List<String> choices;

  const _QuizQuestion({
    required this.displayAr,
    required this.questionFr,
    required this.correctAnswer,
    required this.choices,
  });
}

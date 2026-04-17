import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Classifier: Drag/tap items into the correct category columns.
class ClassifierExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const ClassifierExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<ClassifierExercise> createState() => _ClassifierExerciseState();
}

class _ClassifierExerciseState extends State<ClassifierExercise> {
  int _currentItem = 0;
  String? _selectedCategory;
  bool _showFeedback = false;
  int _correctCount = 0;

  static const _categoryColors = [
    Color(0xFF2A9D8F),
    Color(0xFFE76F51),
    Color(0xFF6C3483),
    Color(0xFF2980B9),
  ];

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    final categories = widget.exercise.categories;

    if (items.isEmpty || categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final word = item['word'] ?? '';
    final correctCategory = item['category'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.exercise.promptFr != null)
            Text(widget.exercise.promptFr!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Classe ce mot dans la bonne categorie',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Word to classify
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: _showFeedback
                          ? (_selectedCategory == correctCategory
                              ? const Color(0xFF2A9D8F).withOpacity(0.15)
                              : const Color(0xFFC0392B).withOpacity(0.1))
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showFeedback
                            ? (_selectedCategory == correctCategory
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFFC0392B))
                            : const Color(0xFF6C3483),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(
                          fontSize: 36, fontFamily: 'Amiri', color: Color(0xFF1A1A2E)),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Category columns
                  Row(
                    children: List.generate(categories.length, (i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory == cat;
                      final isCorrectCat = cat == correctCategory;
                      final color = _categoryColors[i % _categoryColors.length];

                      Color bgColor = color.withOpacity(0.05);
                      Color borderColor = color.withOpacity(0.3);

                      if (_showFeedback) {
                        if (isCorrectCat) {
                          bgColor = const Color(0xFF2A9D8F).withOpacity(0.2);
                          borderColor = const Color(0xFF2A9D8F);
                        } else if (isSelected && !isCorrectCat) {
                          bgColor = const Color(0xFFC0392B).withOpacity(0.1);
                          borderColor = const Color(0xFFC0392B);
                        }
                      }

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 6,
                            right: i == categories.length - 1 ? 0 : 6,
                          ),
                          child: GestureDetector(
                            onTap: _showFeedback
                                ? null
                                : () {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _showFeedback = true;
                                      if (cat == correctCategory) _correctCount++;
                                    });
                                    Future.delayed(const Duration(milliseconds: 1000), () {
                                      if (!mounted) return;
                                      if (_currentItem < items.length - 1) {
                                        setState(() {
                                          _currentItem++;
                                          _selectedCategory = null;
                                          _showFeedback = false;
                                        });
                                      } else {
                                        widget.onComplete(
                                            correct: _correctCount > items.length ~/ 2);
                                      }
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 120,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor, width: 2),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inbox_rounded, color: color, size: 28),
                                    const SizedBox(height: 8),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          Text(
            '${_currentItem + 1}/${items.length}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

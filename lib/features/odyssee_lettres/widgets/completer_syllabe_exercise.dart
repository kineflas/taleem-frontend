import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Completer Syllabe: Choose the correct vowel for the target sound.
class CompleterSyllabeExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const CompleterSyllabeExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<CompleterSyllabeExercise> createState() => _CompleterSyllabeExerciseState();
}

class _CompleterSyllabeExerciseState extends State<CompleterSyllabeExercise> {
  int _currentItem = 0;
  int? _selectedIndex;
  bool _showFeedback = false;
  int _correctCount = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final lettre = item['lettre'] ?? '';
    final sonCible = item['son_cible'] ?? '';
    final options = List<String>.from(item['options'] ?? []);
    final correctIndex = item['correct'] ?? 0;

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
            'Quelle voyelle produit le son "$sonCible" ?',
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
                  // Big letter display
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9D8F).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2A9D8F), width: 3),
                    ),
                    child: Center(
                      child: Text(
                        lettre,
                        style: const TextStyle(
                            fontSize: 64, fontFamily: 'Amiri', color: Color(0xFF2A9D8F)),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE76F51).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Son cible: $sonCible',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE76F51)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Vowel options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(options.length, (i) {
                      final isSelected = _selectedIndex == i;
                      final isCorrect = i == correctIndex;
                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey.shade300;

                      if (_showFeedback) {
                        if (isCorrect) {
                          bgColor = const Color(0xFF2A9D8F).withOpacity(0.2);
                          borderColor = const Color(0xFF2A9D8F);
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFFC0392B).withOpacity(0.1);
                          borderColor = const Color(0xFFC0392B);
                        }
                      }

                      return GestureDetector(
                        onTap: _showFeedback
                            ? null
                            : () {
                                setState(() {
                                  _selectedIndex = i;
                                  _showFeedback = true;
                                  if (i == correctIndex) _correctCount++;
                                });
                                Future.delayed(const Duration(milliseconds: 1000), () {
                                  if (!mounted) return;
                                  if (_currentItem < items.length - 1) {
                                    setState(() {
                                      _currentItem++;
                                      _selectedIndex = null;
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Text(
                            options[i],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Amiri',
                              color: _showFeedback && isCorrect
                                  ? const Color(0xFF2A9D8F)
                                  : const Color(0xFF1A1A2E),
                            ),
                            textDirection: TextDirection.rtl,
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

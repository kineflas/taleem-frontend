import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Cameleon: Identify the correct positional form of a letter.
class CameleonExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const CameleonExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<CameleonExercise> createState() => _CameleonExerciseState();
}

class _CameleonExerciseState extends State<CameleonExercise> {
  int _currentItem = 0;
  int? _selectedIndex;
  bool _showFeedback = false;
  int _correctCount = 0;

  String _positionLabel(String position) {
    switch (position) {
      case 'isolee':
        return 'Isolee';
      case 'debut':
        return 'Debut';
      case 'milieu':
        return 'Milieu';
      case 'fin':
        return 'Fin';
      default:
        return position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final lettre = item['lettre'] ?? '';
    final position = item['position'] ?? '';
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
            'Trouve la forme "${_positionLabel(position)}" de cette lettre',
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
                  // Target letter
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3483).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6C3483), width: 3),
                    ),
                    child: Center(
                      child: Text(
                        lettre,
                        style: const TextStyle(
                            fontSize: 52, fontFamily: 'Amiri', color: Color(0xFF6C3483)),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE76F51).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Position: ${_positionLabel(position)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE76F51)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4 form options in a grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(options.length, (i) {
                      final isSelected = _selectedIndex == i;
                      final isCorrect = i == correctIndex;
                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey.shade300;
                      Color textColor = const Color(0xFF1A1A2E);

                      if (_showFeedback) {
                        if (isCorrect) {
                          bgColor = const Color(0xFF2A9D8F).withOpacity(0.2);
                          borderColor = const Color(0xFF2A9D8F);
                          textColor = const Color(0xFF2A9D8F);
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFFC0392B).withOpacity(0.1);
                          borderColor = const Color(0xFFC0392B);
                          textColor = const Color(0xFFC0392B);
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              options[i],
                              style: TextStyle(
                                  fontSize: 40, fontFamily: 'Amiri', color: textColor),
                              textDirection: TextDirection.rtl,
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

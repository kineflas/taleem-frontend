import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Détecteur de Forme: Place dots in the right position to form the target letter.
class PointsExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const PointsExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<PointsExercise> createState() => _PointsExerciseState();
}

class _PointsExerciseState extends State<PointsExercise> {
  int _currentItem = 0;
  String? _selectedPosition;
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
    final positions = ['dessus', 'dessous', 'milieu'];
    final correctPosition = item['position'] ?? '';

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
            'Forme la lettre : ${item['nom_cible'] ?? ''} (${item['cible'] ?? ''})',
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
                  // Base form
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        item['forme_base'] ?? '',
                        style: const TextStyle(fontSize: 64, fontFamily: 'Amiri'),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['points'] ?? 1} point(s) à placer',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 24),

                  // Position options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: positions.map((pos) {
                      final isSelected = _selectedPosition == pos;
                      final isCorrect = pos == correctPosition;
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
                                  _selectedPosition = pos;
                                  _showFeedback = true;
                                  if (pos == correctPosition) _correctCount++;
                                });
                                Future.delayed(
                                    const Duration(milliseconds: 1000), () {
                                  if (!mounted) return;
                                  if (_currentItem < items.length - 1) {
                                    setState(() {
                                      _currentItem++;
                                      _selectedPosition = null;
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Text(
                            pos == 'dessus'
                                ? '⬆ Dessus'
                                : pos == 'dessous'
                                    ? '⬇ Dessous'
                                    : '↔ Milieu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _showFeedback && isCorrect
                                  ? const Color(0xFF2A9D8F)
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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

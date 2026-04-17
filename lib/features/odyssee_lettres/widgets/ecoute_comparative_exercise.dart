import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Ecoute Comparative: Compare two similar sounds and pick the correct one.
class EcouteComparativeExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const EcouteComparativeExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<EcouteComparativeExercise> createState() => _EcouteComparativeExerciseState();
}

class _EcouteComparativeExerciseState extends State<EcouteComparativeExercise> {
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
    final label = item['label'] ?? '';
    final question = item['question'] ?? '';
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

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play button
                  GestureDetector(
                    onTap: () {
                      // TODO: play audio item['audio_id']
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C3483).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6C3483), width: 3),
                      ),
                      child: const Icon(Icons.headphones_rounded,
                          color: Color(0xFF6C3483), size: 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C3483))),
                  const SizedBox(height: 20),

                  // Question
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Two-option picker
                  Row(
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

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 8,
                            right: i == options.length - 1 ? 0 : 8,
                          ),
                          child: GestureDetector(
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
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: 2),
                              ),
                              child: Text(
                                options[i],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Amiri',
                                  color: textColor,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
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

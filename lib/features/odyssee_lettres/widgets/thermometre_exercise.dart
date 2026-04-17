import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Thermometre: Place cursor on throat depth scale to match pronunciation zone.
class ThermometreExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const ThermometreExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<ThermometreExercise> createState() => _ThermometreExerciseState();
}

class _ThermometreExerciseState extends State<ThermometreExercise> {
  int _currentItem = 0;
  double _sliderValue = 0.5;
  bool _showFeedback = false;
  int _correctCount = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final lettre = item['lettre'] ?? '';
    final label = item['label'] ?? '';
    final profondeur = (item['profondeur'] as num?)?.toDouble() ?? 0.5;
    final zoneCorrecte = item['zone_correcte'] ?? '';
    final tolerance = 0.15;
    final isCorrectAnswer = (_sliderValue - profondeur).abs() <= tolerance;

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
            'Place le curseur sur la zone de prononciation',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Row(
              children: [
                // Letter info on the left
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play audio button
                      GestureDetector(
                        onTap: () {
                          // TODO: play audio item['audio_id']
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2A9D8F), width: 2),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Color(0xFF2A9D8F), size: 28),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Letter
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C3483).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF6C3483), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            lettre,
                            style: const TextStyle(
                                fontSize: 48, fontFamily: 'Amiri', color: Color(0xFF6C3483)),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF666666))),
                      if (_showFeedback) ...[
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCorrectAnswer
                                ? const Color(0xFF2A9D8F).withOpacity(0.15)
                                : const Color(0xFFC0392B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCorrectAnswer ? 'Bien place !' : 'Zone: $zoneCorrecte',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCorrectAnswer
                                  ? const Color(0xFF2A9D8F)
                                  : const Color(0xFFC0392B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Vertical slider on the right
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Text('Levres',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFFE76F51),
                              inactiveTrackColor: const Color(0xFFE76F51).withOpacity(0.2),
                              thumbColor: _showFeedback
                                  ? (isCorrectAnswer
                                      ? const Color(0xFF2A9D8F)
                                      : const Color(0xFFC0392B))
                                  : const Color(0xFFE76F51),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                              trackHeight: 8,
                              overlayColor: const Color(0xFFE76F51).withOpacity(0.1),
                            ),
                            child: Slider(
                              value: _sliderValue,
                              min: 0.0,
                              max: 1.0,
                              onChanged: _submitted
                                  ? null
                                  : (v) => setState(() => _sliderValue = v),
                            ),
                          ),
                        ),
                      ),
                      const Text('Gorge',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      // Show correct position marker when feedback
                      if (_showFeedback) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cible: ${(profondeur * 100).toInt()}%',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2A9D8F)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!_submitted)
            ElevatedButton(
              onPressed: () {
                final correct = (_sliderValue - profondeur).abs() <= tolerance;
                setState(() {
                  _submitted = true;
                  _showFeedback = true;
                  if (correct) _correctCount++;
                });
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (!mounted) return;
                  if (_currentItem < items.length - 1) {
                    setState(() {
                      _currentItem++;
                      _sliderValue = 0.5;
                      _showFeedback = false;
                      _submitted = false;
                    });
                  } else {
                    widget.onComplete(correct: _correctCount > items.length ~/ 2);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE76F51),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Valider',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 8),
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

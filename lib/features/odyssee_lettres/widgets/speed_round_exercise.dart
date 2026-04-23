import 'dart:async';
import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Speed Round: Identify max letters in a time limit (default 30s).
class SpeedRoundExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const SpeedRoundExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<SpeedRoundExercise> createState() => _SpeedRoundExerciseState();
}

class _SpeedRoundExerciseState extends State<SpeedRoundExercise> {
  int _currentItem = 0;
  int? _selectedIndex;
  bool _showFeedback = false;
  int _correctCount = 0;
  int _secondsLeft = 30;
  Timer? _timer;
  bool _started = false;
  bool _finished = false;
  /// Cached shuffled options per item index
  final Map<int, List<String>> _cachedOptions = {};

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.exercise.timeLimitSeconds ?? 30;
  }

  void _startTimer() {
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _finish();
      }
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final items = widget.exercise.items;
    widget.onComplete(correct: _correctCount > items.length ~/ 2);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> _generateOptions(List<Map<String, dynamic>> items, int currentIdx) {
    return _cachedOptions.putIfAbsent(currentIdx, () {
      final correctName = items[currentIdx]['name'] ?? '';
      final names = <String>{correctName};
      for (final it in items) {
        if (names.length >= 4) break;
        final n = it['name'] ?? '';
        if (n.isNotEmpty) names.add(n);
      }
      while (names.length < 4) {
        names.add('---');
      }
      return names.toList()..shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    // Start screen
    if (!_started) {
      final totalSeconds = widget.exercise.timeLimitSeconds ?? 30;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_rounded, color: Color(0xFFE76F51), size: 64),
              const SizedBox(height: 16),
              Text(
                'Speed Round !',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE76F51)),
              ),
              const SizedBox(height: 8),
              Text(
                'Identifie un max de lettres en ${totalSeconds}s',
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => setState(() => _startTimer()),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Go !',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE76F51),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentItem >= items.length || _finished) {
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final glyph = item['glyph'] ?? '';
    final correctName = item['name'] ?? '';
    final options = _generateOptions(items, _currentItem);

    // Timer color
    Color timerColor = const Color(0xFF2A9D8F);
    if (_secondsLeft <= 10) timerColor = const Color(0xFFE76F51);
    if (_secondsLeft <= 5) timerColor = const Color(0xFFC0392B);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer + score row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_rounded, color: timerColor, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '${_secondsLeft}s',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: timerColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $_correctCount',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A9D8F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Letter display
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _showFeedback
                          ? (_selectedIndex != null && options[_selectedIndex!] == correctName
                              ? const Color(0xFF2A9D8F).withOpacity(0.15)
                              : const Color(0xFFC0392B).withOpacity(0.1))
                          : const Color(0xFF6C3483).withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showFeedback
                            ? (_selectedIndex != null && options[_selectedIndex!] == correctName
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFFC0392B))
                            : const Color(0xFF6C3483),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        glyph,
                        style: const TextStyle(
                            fontSize: 56, fontFamily: 'Amiri', color: Color(0xFF1A1A2E)),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4 name options
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(options.length, (i) {
                      final isSelected = _selectedIndex == i;
                      final isCorrect = options[i] == correctName;
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
                                  if (options[i] == correctName) _correctCount++;
                                });
                                Future.delayed(const Duration(milliseconds: 600), () {
                                  if (!mounted || _finished) return;
                                  if (_currentItem < items.length - 1) {
                                    setState(() {
                                      _currentItem++;
                                      _selectedIndex = null;
                                      _showFeedback = false;
                                    });
                                  } else {
                                    _finish();
                                  }
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 140,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Text(
                            options[i],
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Progress indicator
          LinearProgressIndicator(
            value: (_currentItem + 1) / items.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2A9D8F)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Karaoke Exercise: Read syllables with timing, scored as an exercise.
class KaraokeExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const KaraokeExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<KaraokeExercise> createState() => _KaraokeExerciseState();
}

class _KaraokeExerciseState extends State<KaraokeExercise> {
  int _currentItem = 0;
  int _activeSyllable = -1;
  bool _playing = false;
  bool _showFeedback = false;
  int _correctCount = 0;
  int? _userRating;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _playSyllables(Map<String, dynamic> item) {
    final syllabes = List<String>.from(item['syllabes'] ?? item['syllabes_correctes'] ?? []);
    if (syllabes.isEmpty) return;

    setState(() {
      _playing = true;
      _activeSyllable = 0;
    });

    // Auto-advance through syllables with a delay
    final delayMs = item['delay_ms'] ?? 800;
    int idx = 0;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: delayMs is int ? delayMs : 800), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      idx++;
      if (idx >= syllabes.length) {
        t.cancel();
        setState(() {
          _playing = false;
          _activeSyllable = syllabes.length - 1;
        });
        // TODO: play audio item['audio_id']
      } else {
        setState(() => _activeSyllable = idx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final text = item['text'] ?? item['mot'] ?? '';
    final son = item['son'] ?? '';
    final syllabes = List<String>.from(
        item['syllabes'] ?? item['syllabes_correctes'] ?? []);

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
            'Lis les syllabes en suivant le rythme',
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
                  // Full text display
                  if (text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C3483).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                            fontSize: 32, fontFamily: 'Amiri', color: Color(0xFF6C3483)),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (son.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(son,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF999999))),
                  ],
                  const SizedBox(height: 24),

                  // Syllables karaoke display
                  if (syllabes.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(syllabes.length, (i) {
                          final isActive = i == _activeSyllable;
                          final isPast = i < _activeSyllable;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFE76F51).withOpacity(0.2)
                                  : isPast
                                      ? const Color(0xFF2A9D8F).withOpacity(0.15)
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFE76F51)
                                    : isPast
                                        ? const Color(0xFF2A9D8F)
                                        : Colors.grey.shade300,
                                width: isActive ? 2.5 : 1.5,
                              ),
                            ),
                            child: Text(
                              syllabes[i],
                              style: TextStyle(
                                fontSize: isActive ? 28 : 24,
                                fontFamily: 'Amiri',
                                fontWeight:
                                    isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive
                                    ? const Color(0xFFE76F51)
                                    : isPast
                                        ? const Color(0xFF2A9D8F)
                                        : const Color(0xFF1A1A2E),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Play / replay button
                  if (!_playing && !_showFeedback)
                    ElevatedButton.icon(
                      onPressed: () => _playSyllables(item),
                      icon: Icon(
                        _activeSyllable < 0
                            ? Icons.play_arrow_rounded
                            : Icons.replay_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _activeSyllable < 0 ? 'Lire' : 'Rejouer',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A9D8F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                  // Self-rating after playback (if not playing and has been played)
                  if (!_playing && _activeSyllable >= 0 && !_showFeedback) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Comment etait ta lecture ?',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RatingButton(
                          label: 'Difficile',
                          icon: Icons.sentiment_dissatisfied_rounded,
                          color: const Color(0xFFC0392B),
                          isSelected: _userRating == 0,
                          onTap: () => setState(() => _userRating = 0),
                        ),
                        const SizedBox(width: 12),
                        _RatingButton(
                          label: 'Moyen',
                          icon: Icons.sentiment_neutral_rounded,
                          color: const Color(0xFFE76F51),
                          isSelected: _userRating == 1,
                          onTap: () => setState(() => _userRating = 1),
                        ),
                        const SizedBox(width: 12),
                        _RatingButton(
                          label: 'Facile',
                          icon: Icons.sentiment_satisfied_alt_rounded,
                          color: const Color(0xFF2A9D8F),
                          isSelected: _userRating == 2,
                          onTap: () => setState(() => _userRating = 2),
                        ),
                      ],
                    ),
                  ],

                  // Feedback
                  if (_showFeedback) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Bien joue !',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A9D8F)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Submit / Next
          if (!_playing && _userRating != null && !_showFeedback)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFeedback = true;
                  // Rating 1 or 2 counts as correct
                  if (_userRating != null && _userRating! >= 1) _correctCount++;
                });
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (!mounted) return;
                  if (_currentItem < items.length - 1) {
                    setState(() {
                      _currentItem++;
                      _activeSyllable = -1;
                      _showFeedback = false;
                      _userRating = null;
                    });
                  } else {
                    widget.onComplete(correct: _correctCount > items.length ~/ 2);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3483),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Valider',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
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

class _RatingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

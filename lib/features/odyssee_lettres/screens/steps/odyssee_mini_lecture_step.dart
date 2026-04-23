import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';

/// Step 4: Mini-lecture (Karaoké) — Syllables light up with timing.
class OdysseeMiniLectureStep extends StatefulWidget {
  final OdysseeLessonContent lesson;
  final VoidCallback onComplete;

  const OdysseeMiniLectureStep({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<OdysseeMiniLectureStep> createState() =>
      _OdysseeMiniLectureStepState();
}

class _OdysseeMiniLectureStepState extends State<OdysseeMiniLectureStep> {
  int _activeIndex = -1;
  bool _isPlaying = false;
  bool _hasPlayed = false;
  /// All scheduled timers for karaoke highlights (cancellable on dispose)
  final List<Timer> _timers = [];

  MiniLectureData? get _miniLecture => widget.lesson.miniLecture;

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _startKaraoke() {
    final miniLecture = _miniLecture;
    if (miniLecture == null || miniLecture.items.isEmpty) return;

    _cancelTimers();
    setState(() {
      _isPlaying = true;
      _activeIndex = 0;
    });

    // Schedule highlights based on delay_ms
    for (int i = 0; i < miniLecture.items.length; i++) {
      final delay = miniLecture.items[i].delayMs;
      _timers.add(Timer(Duration(milliseconds: delay), () {
        if (mounted && _isPlaying) {
          setState(() => _activeIndex = i);
        }
      }));
    }

    // End after last item + 1.5s
    final lastDelay = miniLecture.items.last.delayMs;
    _timers.add(Timer(Duration(milliseconds: lastDelay + 1500), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _hasPlayed = true;
          _activeIndex = -1;
        });
      }
    }));
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final miniLecture = _miniLecture;
    if (miniLecture == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onComplete());
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C3483).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF6C3483), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      miniLecture.instruction,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF264653)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Karaoke syllables grid
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: List.generate(miniLecture.items.length, (i) {
                    final item = miniLecture.items[i];
                    final isActive = i == _activeIndex;
                    final isPast = i < _activeIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2A9D8F)
                            : isPast
                                ? const Color(0xFF2A9D8F).withOpacity(0.15)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF2A9D8F)
                              : Colors.grey.shade200,
                          width: isActive ? 3 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2A9D8F)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.text,
                            style: TextStyle(
                              fontSize: 28,
                              fontFamily: 'Amiri',
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            item.son,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive
                                  ? Colors.white.withOpacity(0.9)
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Play / Continue button
            const SizedBox(height: 16),
            if (!_hasPlayed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPlaying ? null : _startKaraoke,
                  icon: Icon(
                    _isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isPlaying ? 'Écoute en cours...' : 'Lancer le karaoké',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3483),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _hasPlayed = false);
                      _startKaraoke();
                    },
                    icon: const Icon(Icons.replay_rounded,
                        color: Color(0xFF6C3483)),
                    label: const Text('Rejouer',
                        style: TextStyle(color: Color(0xFF6C3483))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF6C3483)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A9D8F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continuer',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

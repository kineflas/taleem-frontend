import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LetterSpeedRoundScreen — Mode Vitesse
//
// Flashcards rapides : affiche un glyph pendant max 4 secondes,
// l'élève doit tapper le bon nom parmi 4 choix.
// Score final + record.
// ─────────────────────────────────────────────────────────────────────────────

class LetterSpeedRoundScreen extends StatefulWidget {
  /// Glyphs to review — if empty, uses all 28 letters
  final List<String> glyphsToReview;

  const LetterSpeedRoundScreen({super.key, this.glyphsToReview = const []});

  @override
  State<LetterSpeedRoundScreen> createState() => _LetterSpeedRoundScreenState();
}

class _LetterSpeedRoundScreenState extends State<LetterSpeedRoundScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  final _audio = AudioPlayer();

  late List<String> _glyphs;
  int _index = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _answered = false;
  String? _selected;
  bool _finished = false;

  late List<String> _choices;
  late AnimationController _timerCtrl;
  late AnimationController _fadeCtrl;
  Timer? _autoNext;

  static const _timePerCard = 4; // seconds

  @override
  void initState() {
    super.initState();
    _glyphs = widget.glyphsToReview.isNotEmpty
        ? [...widget.glyphsToReview]..shuffle(_rng)
        : [...glyphToName.keys.toList()]..shuffle(_rng);

    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timePerCard),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_answered) {
          _onTimeout();
        }
      });

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadCard();
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _fadeCtrl.dispose();
    _autoNext?.cancel();
    _audio.dispose();
    super.dispose();
  }

  void _loadCard() {
    final glyph = _glyphs[_index];
    final correct = glyphToName[glyph] ?? glyph;
    final distractors = allLetterNames.where((n) => n != correct).toList()..shuffle(_rng);
    _choices = [correct, ...distractors.take(3)]..shuffle(_rng);
    _answered = false;
    _selected = null;

    _fadeCtrl.forward(from: 0);
    _timerCtrl.forward(from: 0);

    // Auto-play audio
    _playAudio(glyph);
  }

  Future<void> _playAudio(String glyph) async {
    final name = glyphToName[glyph]?.toLowerCase().replaceAll(' ', '_') ?? glyph;
    try {
      await _audio.play(UrlSource('${ApiConstants.baseUrl}/static/audio/letters/$name.mp3'));
    } catch (_) {}
  }

  void _onTimeout() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selected = null; // no selection = wrong
      _streak = 0;
    });
    _scheduleNext();
  }

  void _onAnswer(String choice) {
    if (_answered) return;
    final correct = glyphToName[_glyphs[_index]] ?? _glyphs[_index];
    final isRight = choice == correct;

    _timerCtrl.stop();
    setState(() {
      _answered = true;
      _selected = choice;
      if (isRight) {
        _score++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });
    _scheduleNext();
  }

  void _scheduleNext() {
    _autoNext?.cancel();
    _autoNext = Timer(const Duration(milliseconds: 900), _nextCard);
  }

  void _nextCard() {
    if (_index + 1 >= _glyphs.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() => _index++);
    _loadCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult(context);

    final glyph = _glyphs[_index];
    final correctName = glyphToName[glyph] ?? glyph;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('⚡ Mode Vitesse', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              '${_index + 1}/${_glyphs.length}',
              style: const TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Score + streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Chip(label: '✅ $_score', color: AppColors.success),
                  if (_streak >= 2)
                    _Chip(label: '🔥 $_streak', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 16),

              // Timer bar
              AnimatedBuilder(
                animation: _timerCtrl,
                builder: (_, __) => LinearProgressIndicator(
                  value: 1 - _timerCtrl.value,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timerCtrl.value < 0.5 ? Colors.orange : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Glyph card
              FadeTransition(
                opacity: _fadeCtrl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _playAudio(glyph),
                        child: Text(
                          glyph,
                          style: TextStyle(
                            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                            fontSize: 96,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '🔊 Appuyez pour réécouter',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Answer choices
              ...List.generate(2, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: List.generate(2, (col) {
                      final i = row * 2 + col;
                      final choice = _choices[i];
                      final isCorrect = choice == correctName;
                      final isSelected = choice == _selected;

                      Color bg = Colors.white.withOpacity(0.08);
                      Color border = Colors.white24;
                      if (_answered) {
                        if (isCorrect) {
                          bg = AppColors.success.withOpacity(0.2);
                          border = AppColors.success;
                        } else if (isSelected) {
                          bg = AppColors.danger.withOpacity(0.2);
                          border = AppColors.danger;
                        }
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onAnswer(choice),
                          child: Container(
                            margin: EdgeInsets.only(right: col == 0 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border, width: 1.5),
                            ),
                            child: Text(
                              choice,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final pct = _glyphs.isEmpty ? 0 : (_score / _glyphs.length * 100).round();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pct >= 80 ? '🏆' : pct >= 60 ? '⚡' : '💪',
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_score bonne${_score > 1 ? 's' : ''} / ${_glyphs.length}',
                  style: const TextStyle(fontSize: 16, color: Colors.white60),
                ),
                const SizedBox(height: 8),
                if (_bestStreak >= 3)
                  Text(
                    '🔥 Meilleure série : $_bestStreak',
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() {
                        _index = 0;
                        _score = 0;
                        _streak = 0;
                        _bestStreak = 0;
                        _finished = false;
                        _glyphs.shuffle(_rng);
                      });
                      _loadCard();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Rejouer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour', style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

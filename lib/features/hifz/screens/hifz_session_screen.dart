import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../../autonomous_learning/providers/learning_provider.dart';

class HifzSessionScreen extends ConsumerStatefulWidget {
  final HifzGoalModel goal;

  const HifzSessionScreen({super.key, required this.goal});

  @override
  ConsumerState<HifzSessionScreen> createState() => _HifzSessionScreenState();
}

class _HifzSessionScreenState extends ConsumerState<HifzSessionScreen> {
  late int _currentVerse;
  int _loopCount = 5;
  int _currentLoop = 0;
  int _pauseSeconds = 5;
  int _maskingLevel = 0; // 0=fully visible, 1=30%, 2=60%, 3=auto-dictée
  bool _isPlaying = false;
  Set<int> _versesMarked = {};
  Timer? _pauseTimer;
  Timer? _loopTimer;

  // Mock verse text (in real app, fetch from Quran API)
  final Map<String, String> _verseTexts = {
    '1:1': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    '1:2': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    '1:3': 'الرَّحْمَٰنِ الرَّحِيمِ',
    '1:4': 'مَالِكِ يَوْمِ الدِّينِ',
    '1:5': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
  };

  @override
  void initState() {
    super.initState();
    _currentVerse = widget.goal.totalVerses > 0 ? 1 : 1;
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _loopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verseKey = '${widget.goal.surahNumber}:$_currentVerse';
    final verseText = _verseTexts[verseKey] ?? 'الحمد لله رب العالمين...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('سورة ${widget.goal.surahNumber}'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الآية $_currentVerse / ${widget.goal.totalVerses}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${((_currentVerse / widget.goal.totalVerses) * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentVerse / widget.goal.totalVerses,
                      minHeight: 6,
                      backgroundColor: AppColors.heatmapEmpty,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Verse text display
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Text(
                    'الآية $_currentVerse',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Verse text with masking
                  _buildMaskedVerseText(verseText),
                  const SizedBox(height: 16),
                  // Masking level indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('مستوى الإخفاء: '),
                      Text(
                        ['واضح', '30%', '60%', 'أول حرف'][_maskingLevel],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Loop counter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔁'),
                      const SizedBox(width: 8),
                      Text(
                        'الاستماع ${_currentLoop + 1}/$_loopCount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    '⏱️ ${_pauseSeconds}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main controls
            _buildPlayerControls(),
            const SizedBox(height: 24),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  // Mark as known button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _versesMarked.contains(_currentVerse)
                          ? null
                          : _handleMarkKnown,
                      icon: const Text('✅', style: TextStyle(fontSize: 20)),
                      label: const Text(
                        'Je le connais',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.heatmapEmpty,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Repeat button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleRepeat,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Encore',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaskedVerseText(String verseText) {
    final words = verseText.split(' ');

    if (_maskingLevel == 0) {
      // Fully visible
      return Text(
        verseText,
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        textDirection: TextDirection.rtl,
      );
    } else if (_maskingLevel == 1) {
      // 30% masked
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          final isMasked = (word.hashCode % 100) < 30;
          return Text(
            isMasked ? '█████' : word,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isMasked ? AppColors.textHint : AppColors.primary,
            ),
          );
        }).toList(),
      );
    } else if (_maskingLevel == 2) {
      // 60% masked
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          final isMasked = (word.hashCode % 100) < 60;
          return Text(
            isMasked ? '█████' : word,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isMasked ? AppColors.textHint : AppColors.primary,
            ),
          );
        }).toList(),
      );
    } else {
      // Auto-dictée: show only first letter
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          return Text(
            '${word[0]}__',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildPlayerControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Play/Pause + Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Loop stepper
              _buildControl(
                '🔁',
                '$_loopCount',
                () => setState(() => _loopCount = (_loopCount - 1).clamp(1, 20)),
                () => setState(() => _loopCount = (_loopCount + 1).clamp(1, 20)),
              ),
              // Play button (large center)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isPlaying ? '⏸️' : '▶️',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
              // Pause stepper
              _buildControl(
                '⏸️',
                '${_pauseSeconds}s',
                () => setState(() => _pauseSeconds = (_pauseSeconds - 1).clamp(0, 60)),
                () => setState(() => _pauseSeconds = (_pauseSeconds + 1).clamp(0, 60)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Masking level toggle
          Row(
            children: [
              Expanded(
                child: _buildMaskingButton('واضح', 0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMaskingButton('30%', 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMaskingButton('60%', 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMaskingButton('أول', 3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Navigation
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentVerse > 1 ? _previousVerse : null,
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('السابق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentVerse < widget.goal.totalVerses ? _nextVerse : null,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControl(String emoji, String label, VoidCallback onMinus, VoidCallback onPlus) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onMinus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPlus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaskingButton(String label, int level) {
    final isSelected = _maskingLevel == level;
    return ElevatedButton(
      onPressed: () => setState(() => _maskingLevel = level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      _loopTimer = Timer.periodic(Duration(seconds: 3 + _pauseSeconds), (timer) {
        if (_currentLoop < _loopCount - 1) {
          setState(() => _currentLoop++);
        } else {
          timer.cancel();
          setState(() => _isPlaying = false);
        }
      });
    } else {
      _loopTimer?.cancel();
    }
  }

  void _handleRepeat() {
    setState(() {
      _currentLoop = 0;
      _isPlaying = false;
    });
    _loopTimer?.cancel();
    _togglePlayPause();
  }

  void _handleMarkKnown() {
    setState(() {
      _versesMarked.add(_currentVerse);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الآية $_currentVerse مسجلة ✅'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );

    // Auto-advance to next verse
    if (_currentVerse < widget.goal.totalVerses) {
      Future.delayed(const Duration(milliseconds: 500), _nextVerse);
    }
  }

  void _nextVerse() {
    if (_currentVerse < widget.goal.totalVerses) {
      setState(() {
        _currentVerse++;
        _currentLoop = 0;
        _isPlaying = false;
      });
      _loopTimer?.cancel();
    }
  }

  void _previousVerse() {
    if (_currentVerse > 1) {
      setState(() {
        _currentVerse--;
        _currentLoop = 0;
        _isPlaying = false;
      });
      _loopTimer?.cancel();
    }
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../providers/hifz_provider.dart';
import '../providers/quran_provider.dart';

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
  bool _audioError = false;
  Set<int> _versesMarked = {};
  Timer? _pauseTimer;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Normalise le nom du récitateur — certains goals en DB ont des variantes
  /// incorrectes (ex: 'Al-Husary_128kbps' au lieu de 'Husary_128kbps').
  static const Map<String, String> _reciterAliases = {
    'Al-Husary_128kbps': 'Husary_128kbps',
    'Al-Husary_64kbps': 'Husary_64kbps',
    'Husary': 'Husary_128kbps',
    'Alafasy': 'Alafasy_128kbps',
    'Abdul_Basit': 'Abdul_Basit_Murattal_192kbps',
  };

  String get _normalizedReciter {
    final raw = widget.goal.reciterFolder.isNotEmpty
        ? widget.goal.reciterFolder
        : 'Alafasy_128kbps';
    return _reciterAliases[raw] ?? raw;
  }

  /// Builds the EveryAyah CDN URL for the given surah/verse.
  /// Format: https://everyayah.com/data/{reciter}/{SSS}{VVV}.mp3
  String _audioUrl(int surah, int verse, {String? reciterOverride}) {
    final s = surah.toString().padLeft(3, '0');
    final v = verse.toString().padLeft(3, '0');
    final reciter = reciterOverride ?? _normalizedReciter;
    return 'https://everyayah.com/data/$reciter/$s$v.mp3';
  }

  /// Joue un verset avec fallback automatique sur Alafasy si le récitateur
  /// principal échoue (URL 404 / CORS / format non supporté).
  Future<void> _playVerseAudio(int surah, int verse) async {
    setState(() => _audioError = false);
    try {
      await _audioPlayer.play(UrlSource(_audioUrl(surah, verse)));
    } catch (_) {
      // Fallback: essayer Alafasy
      try {
        await _audioPlayer.play(
          UrlSource(_audioUrl(surah, verse, reciterOverride: 'Alafasy_128kbps')),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Récitateur indisponible — lecture avec Alafasy"),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _audioError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Audio indisponible — vérifiez la connexion"),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentVerse = 1;

    // When one play-through of the verse finishes, either loop again or stop.
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_currentLoop < _loopCount - 1) {
        // Still have loops to do — wait pauseSeconds then replay
        setState(() => _currentLoop++);
        _pauseTimer = Timer(Duration(seconds: _pauseSeconds), () {
          if (mounted && _isPlaying) {
            _playVerseAudio(widget.goal.surahNumber, _currentVerse);
          }
        });
      } else {
        // All loops done
        setState(() {
          _isPlaying = false;
          _currentLoop = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(quranSurahProvider(widget.goal.surahNumber));

    return surahAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('سورة ${widget.goal.surahNumber}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des versets…'),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('سورة ${widget.goal.surahNumber}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger les versets',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez votre connexion internet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(quranSurahProvider(widget.goal.surahNumber)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (verseTexts) => _buildSession(context, verseTexts),
    );
  }

  Widget _buildSession(BuildContext context, Map<int, String> verseTexts) {
    final verseText = verseTexts[_currentVerse] ?? '…';

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
                onTap: _audioError ? null : _togglePlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _audioError
                        ? AppColors.danger
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _audioError
                        ? const Icon(Icons.wifi_off, color: Colors.white, size: 28)
                        : Text(
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

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      // Pause
      _pauseTimer?.cancel();
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      // Play (resume or start from beginning of current loop)
      setState(() => _isPlaying = true);
      final state = _audioPlayer.state;
      if (state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _playVerseAudio(widget.goal.surahNumber, _currentVerse);
      }
    }
  }

  Future<void> _handleRepeat() async {
    _pauseTimer?.cancel();
    await _audioPlayer.stop();
    setState(() {
      _currentLoop = 0;
      _isPlaying = true;
    });
    await _playVerseAudio(widget.goal.surahNumber, _currentVerse);
  }

  Future<void> _stopAudio() async {
    _pauseTimer?.cancel();
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentLoop = 0;
    });
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

  Future<void> _nextVerse() async {
    if (_currentVerse < widget.goal.totalVerses) {
      await _stopAudio();
      setState(() => _currentVerse++);
    }
  }

  Future<void> _previousVerse() async {
    if (_currentVerse > 1) {
      await _stopAudio();
      setState(() => _currentVerse--);
    }
  }
}

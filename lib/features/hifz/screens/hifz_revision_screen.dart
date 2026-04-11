import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../providers/hifz_provider.dart';
import '../providers/quran_provider.dart';

class HifzRevisionScreen extends ConsumerStatefulWidget {
  const HifzRevisionScreen({super.key});

  @override
  ConsumerState<HifzRevisionScreen> createState() => _HifzRevisionScreenState();
}

class _HifzRevisionScreenState extends ConsumerState<HifzRevisionScreen> {
  late int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? _playingVerse; // tracks which verse (by index) is currently playing

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _audioUrl(int surah, int verse) {
    final s = surah.toString().padLeft(3, '0');
    final v = verse.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$s$v.mp3';
  }

  Future<void> _toggleAudio(int idx, int surah, int verse) async {
    if (_isPlaying && _playingVerse == idx) {
      await _audioPlayer.stop();
      setState(() { _isPlaying = false; _playingVerse = null; });
    } else {
      await _audioPlayer.stop();
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() { _isPlaying = false; _playingVerse = null; });
      });
      try {
        await _audioPlayer.play(UrlSource(_audioUrl(surah, verse)));
        setState(() { _isPlaying = true; _playingVerse = idx; });
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio indisponible pour ce verset'),
              backgroundColor: Color(0xFFE53E3E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  final surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
    'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
  ];

  @override
  Widget build(BuildContext context) {
    final dueVersesAsync = ref.watch(hifzDueVersesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Révisions'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: dueVersesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Erreur: $e'),
          ),
        ),
        data: (verses) {
          final dueVerses = verses.where((v) {
            final nextReview = DateTime.parse(v.nextReviewDate);
            return nextReview.isBefore(DateTime.now().add(const Duration(days: 1)));
          }).toList();

          if (dueVerses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune révision requise!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bravo, vous êtes à jour!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Versets à revoir',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentIndex + 1} / ${dueVerses.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dueVerses.length} 📖',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / dueVerses.length,
                    minHeight: 6,
                    backgroundColor: AppColors.heatmapEmpty,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),

              // Verse display
              Expanded(
                child: PageView.builder(
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: dueVerses.length,
                  itemBuilder: (context, index) {
                    final verse = dueVerses[index];
                    return _buildVerseCard(context, ref, index, verse);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerseCard(BuildContext context, WidgetRef ref, int idx, VerseProgressModel verse) {
    // Fetch verse text from alquran.cloud (cached per surah by Riverpod)
    final verseAsync = ref.watch(
      quranVerseProvider((surah: verse.surahNumber, verse: verse.verseNumber)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${surahNames[verse.surahNumber - 1]}:${verse.verseNumber}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy', 'fr').format(
                            DateTime.parse(verse.nextReviewDate),
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    // Mastery badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: verse.mastery.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: verse.mastery.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(verse.mastery == VerseMastery.red
                              ? '🔴'
                              : verse.mastery == VerseMastery.orange
                                  ? '🟡'
                                  : '🟢'),
                          const SizedBox(width: 4),
                          Text(
                            '${verse.masteryScore}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: verse.mastery.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Verse text — loaded from alquran.cloud
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                verseAsync.when(
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => Text(
                    'Verset non disponible',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  data: (text) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _toggleAudio(idx, verse.surahNumber, verse.verseNumber),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_isPlaying && _playingVerse == idx)
                          ? AppColors.accent.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_isPlaying && _playingVerse == idx)
                            ? AppColors.accent
                            : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (_isPlaying && _playingVerse == idx)
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up,
                          color: (_isPlaying && _playingVerse == idx)
                              ? AppColors.accent
                              : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_isPlaying && _playingVerse == idx) ? 'Arrêter' : 'Écouter',
                          style: TextStyle(
                            color: (_isPlaying && _playingVerse == idx)
                                ? AppColors.accent
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('📖', verse.totalListens.toString(), 'Écoutes'),
                _buildStatItem('✅', verse.consecutiveSuccesses.toString(), 'Succès'),
                _buildStatItem('🔄', verse.reviewCount.toString(), 'Révisions'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success button
              ElevatedButton.icon(
                onPressed: () => _handleVerseReview(true),
                icon: const Text('✅', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Je m\'en souviens',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Failure button
              OutlinedButton.icon(
                onPressed: () => _handleVerseReview(false),
                icon: const Text('❌', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'À revoir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  void _handleVerseReview(bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Excellent!' : '🔄 À bientôt!'),
        backgroundColor: success ? AppColors.success : AppColors.warning,
        duration: const Duration(seconds: 1),
      ),
    );

    // TODO: Call API to record review result
    // For now, simulate moving to next verse
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

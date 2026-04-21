import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../../hifz_v2/data/hifz_v2_service.dart' show EnrichedSurahResponse;
import '../../hifz_v2/providers/hifz_v2_provider.dart';

import '../../quran_player/providers/quran_player_provider.dart';
import '../../quran_player/services/quran_audio_service.dart';
import '../../quran_player/models/player_models.dart';
import '../../quran_player/widgets/verse_display.dart';
import '../../quran_player/widgets/karaoke_verse_display.dart';
import '../../quran_player/widgets/player_controls.dart';
import '../../quran_player/widgets/reciter_selector.dart';
import '../../../core/constants/app_colors.dart';

/// Onglet Coran — accès rapide + lecteur intégré.
///
/// Structure :
///   - Cartes d'accès rapide (dernière écoute, Wird, révision SRS)
///   - Sélection sourate avec recherche
///   - Lecteur audio intégré (quand actif)
class QuranTabScreen extends ConsumerStatefulWidget {
  const QuranTabScreen({super.key});

  @override
  ConsumerState<QuranTabScreen> createState() => _QuranTabScreenState();
}

class _QuranTabScreenState extends ConsumerState<QuranTabScreen> {
  String _searchQuery = '';
  int? _selectedSurah;
  int _startVerse = 1;
  int _endVerse = 1;
  int _totalVerses = 1;
  bool _showTranslation = false;
  bool _isPlayerActive = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(quranAudioServiceProvider);
    final surahsAsync = ref.watch(surahListProvider);

    // Si le lecteur est actif → afficher le mode lecture
    if (_isPlayerActive) {
      return _buildActivePlayer(audioService);
    }

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── En-tête ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Coran', style: HifzTypo.sectionTitle().copyWith(fontSize: 24)),
              ),
            ),

            // ── Cartes d'accès rapide ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.play_circle_filled,
                        color: HifzColors.emerald,
                        title: 'Mon Wird',
                        subtitle: 'Mémorisation',
                        onTap: () => context.push('/hifz-v2/ikhtiar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.repeat_rounded,
                        color: HifzColors.gold,
                        title: 'Révision SRS',
                        subtitle: 'Versets à revoir',
                        onTap: () => _launchRevisionMode(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.mosque_outlined,
                        color: const Color(0xFF5C6BC0),
                        title: 'Hifz Master',
                        subtitle: 'Ma progression',
                        onTap: () => context.go('/student/hifz-v2'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Barre de recherche ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une sourate...',
                    hintStyle: HifzTypo.body(color: HifzColors.textLight),
                    prefixIcon: const Icon(Icons.search, color: HifzColors.textLight),
                    filled: true,
                    fillColor: HifzColors.ivoryWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HifzColors.ivoryDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HifzColors.ivoryDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: HifzColors.emerald),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Sélecteur de récitateur ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: ReciterSelector(
                  selected: ref.watch(quranAudioServiceProvider).reciter,
                  onChanged: (r) =>
                      ref.read(quranAudioServiceProvider).setReciter(r),
                ),
              ),
            ),

            // ── Liste des sourates ──
            surahsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Erreur: $e')),
              ),
              data: (surahs) {
                final filtered = _searchQuery.isEmpty
                    ? surahs
                    : surahs.where((s) =>
                        s.nameFr.toLowerCase().contains(_searchQuery) ||
                        s.nameAr.contains(_searchQuery) ||
                        '${s.number}'.contains(_searchQuery)).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final surah = filtered[index];
                      return _SurahTile(
                        surah: surah,
                        onTap: () => _launchSurah(surah),
                      );
                    },
                    childCount: filtered.length,
                  ),
                );
              },
            ),

            // Padding bottom
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _launchSurah(SurahInfo surah) async {
    final audioService = ref.read(quranAudioServiceProvider);
    audioService.setReciter(audioService.reciter);

    audioService.buildLecturePlaylist(
      surah: surah.number,
      startVerse: 1,
      endVerse: surah.totalVerses,
      surahName: '${surah.nameAr} — ${surah.nameFr}',
    );

    setState(() {
      _selectedSurah = surah.number;
      _startVerse = 1;
      _endVerse = surah.totalVerses;
      _totalVerses = surah.totalVerses;
      _isPlayerActive = true;
    });

    await audioService.play();
  }

  void _launchRevisionMode() {
    // Naviguer vers le lecteur dédié en mode révision
    context.push('/quran-player');
  }

  Widget _buildActivePlayer(QuranAudioService audioService) {
    final surahTextAsync = _selectedSurah != null
        ? ref.watch(surahTextProvider(_selectedSurah!))
        : null;
    final translationAsync = _showTranslation && _selectedSurah != null
        ? ref.watch(surahTranslationProvider(_selectedSurah!))
        : null;

    // Tenter de charger les données enrichies (karaoke timings)
    final enrichedAsync = _selectedSurah != null
        ? ref.watch(surahContentProvider(_selectedSurah!))
        : null;

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      appBar: AppBar(
        backgroundColor: HifzColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: HifzColors.textDark, size: 20),
          onPressed: () {
            audioService.stop();
            setState(() => _isPlayerActive = false);
          },
        ),
        title: Text('Lecture', style: HifzTypo.sectionTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
              color: _showTranslation ? HifzColors.emerald : HifzColors.textLight,
            ),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
        ],
      ),
      body: Column(
        children: [
          // Versets
          Expanded(
            child: _buildVerseContent(
              audioService: audioService,
              surahTextAsync: surahTextAsync,
              translationAsync: translationAsync,
              enrichedAsync: enrichedAsync,
            ),
          ),

          // Contrôles
          PlayerControls(service: audioService),
        ],
      ),
    );
  }

  Widget _buildVerseContent({
    required QuranAudioService audioService,
    required AsyncValue<Map<int, String>>? surahTextAsync,
    required AsyncValue<Map<int, String>>? translationAsync,
    required AsyncValue<EnrichedSurahResponse>? enrichedAsync,
  }) {
    if (_selectedSurah == null) {
      return const Center(child: Text('Sélectionnez une sourate'));
    }

    // Si données enrichies disponibles avec timings → mode karaoke
    final enrichedVerses = enrichedAsync?.valueOrNull?.verses;
    if (enrichedVerses != null && enrichedVerses.isNotEmpty) {
      final hasTimings = enrichedVerses.any((v) => v.audioTimings != null);
      if (hasTimings) {
        return KaraokeVerseDisplay(
          verses: enrichedVerses,
          audioService: audioService,
          startVerse: _startVerse,
          showTranslation: _showTranslation,
          translations: translationAsync?.valueOrNull,
        );
      }
    }

    // Fallback : affichage standard
    return surahTextAsync?.when(
          data: (verses) => VerseDisplay(
            verses: verses,
            translations: translationAsync?.valueOrNull,
            showTranslation: _showTranslation,
            currentVerse: audioService.currentEntry?.verse ?? 1,
            startVerse: _startVerse,
            scrollController: _scrollController,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ) ??
        const Center(child: Text('Sélectionnez une sourate'));
  }
}

// ── Quick Card ──────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Surah Tile ──────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  final SurahInfo surah;
  final VoidCallback onTap;

  const _SurahTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HifzColors.emeraldMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${surah.number}',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HifzColors.emerald,
          ),
        ),
      ),
      title: Text(
        surah.nameFr,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: HifzColors.textDark,
        ),
      ),
      subtitle: Text(
        '${surah.totalVerses} versets',
        style: HifzTypo.body(color: HifzColors.textLight),
      ),
      trailing: Text(
        surah.nameAr,
        style: GoogleFonts.amiri(
          fontSize: 18,
          color: HifzColors.textMedium,
        ),
      ),
    );
  }
}

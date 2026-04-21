import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../../hifz_v2/providers/hifz_v2_provider.dart';
import '../models/player_models.dart';
import '../providers/quran_player_provider.dart';
import '../services/quran_audio_service.dart';
import '../widgets/verse_display.dart';
import '../widgets/karaoke_verse_display.dart';
import '../widgets/player_controls.dart';
import '../widgets/reciter_selector.dart';

/// Écran principal du lecteur audio Coran.
///
/// Deux onglets :
///   - Lecture libre (sourate + plage de versets)
///   - Révision SRS (playlist automatique)
class QuranPlayerScreen extends ConsumerStatefulWidget {
  const QuranPlayerScreen({super.key});

  @override
  ConsumerState<QuranPlayerScreen> createState() => _QuranPlayerScreenState();
}

class _QuranPlayerScreenState extends ConsumerState<QuranPlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Mode Lecture ──
  int? _selectedSurah;
  int _startVerse = 1;
  int _endVerse = 1;
  int _totalVerses = 1;
  bool _showTranslation = false;
  bool _isPlayerActive = false;

  // Scroll controller pour auto-scroll au verset actif
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(quranAudioServiceProvider);

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
            Navigator.of(context).pop();
          },
        ),
        title: Text('Lecteur Coran', style: HifzTypo.sectionTitle()),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HifzColors.emerald,
          labelColor: HifzColors.emerald,
          unselectedLabelColor: HifzColors.textLight,
          labelStyle:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Lecture libre'),
            Tab(text: 'Révision SRS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLectureTab(audioService),
          _buildRevisionTab(audioService),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TAB 1 — LECTURE LIBRE
  // ════════════════════════════════════════════════════════════════

  Widget _buildLectureTab(QuranAudioService audioService) {
    final surahList = ref.watch(surahListProvider);

    return Column(
      children: [
        // ── Configuration (masquée quand le player est actif) ──
        if (!_isPlayerActive)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Récitateur
                  Text('Récitateur', style: HifzTypo.stepLabel()),
                  const SizedBox(height: 8),
                  ReciterSelector(
                    selected: audioService.reciter,
                    onChanged: (r) => audioService.setReciter(r),
                  ),

                  const SizedBox(height: 24),

                  // Sourate
                  Text('Sourate', style: HifzTypo.stepLabel()),
                  const SizedBox(height: 8),
                  surahList.when(
                    data: (surahs) => _buildSurahDropdown(surahs),
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: HifzColors.emerald)),
                    error: (e, _) => Text('Erreur: $e',
                        style: HifzTypo.body(color: HifzColors.wrong)),
                  ),

                  const SizedBox(height: 24),

                  // Plage de versets
                  if (_selectedSurah != null) ...[
                    Text('Versets', style: HifzTypo.stepLabel()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVerseField(
                            label: 'De',
                            value: _startVerse,
                            max: _totalVerses,
                            onChanged: (v) =>
                                setState(() => _startVerse = v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('→',
                              style: HifzTypo.body(color: HifzColors.gold)),
                        ),
                        Expanded(
                          child: _buildVerseField(
                            label: 'À',
                            value: _endVerse,
                            max: _totalVerses,
                            onChanged: (v) => setState(() => _endVerse = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _startVerse = 1;
                          _endVerse = _totalVerses;
                        }),
                        child: Text(
                          'Sourate complète ($_totalVerses versets)',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: HifzColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Traduction toggle
                    SwitchListTile(
                      title: Text('Afficher la traduction',
                          style: HifzTypo.body()),
                      value: _showTranslation,
                      activeColor: HifzColors.emerald,
                      onChanged: (v) =>
                          setState(() => _showTranslation = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 24),

                    // Bouton Lancer
                    ElevatedButton.icon(
                      style: HifzDecor.primaryButton,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Lancer la lecture'),
                      onPressed: _startLecture,
                    ),
                  ],
                ],
              ),
            ),
          ),

        // ── Player actif : affichage des versets ──
        if (_isPlayerActive && _selectedSurah != null)
          Expanded(
            child: Column(
              children: [
                // Bouton retour config
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            size: 20, color: HifzColors.textMedium),
                        onPressed: () {
                          audioService.stop();
                          setState(() => _isPlayerActive = false);
                        },
                      ),
                      Text(
                        _surahName ?? 'Sourate $_selectedSurah',
                        style: HifzTypo.sectionTitle(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _showTranslation
                              ? Icons.translate
                              : Icons.translate,
                          color: _showTranslation
                              ? HifzColors.emerald
                              : HifzColors.textLight,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _showTranslation = !_showTranslation),
                      ),
                    ],
                  ),
                ),
                // Versets
                Expanded(child: _buildVerseArea(audioService)),
              ],
            ),
          ),

        // ── Contrôles (toujours visibles quand actif) ──
        if (_isPlayerActive)
          PlayerControls(
            service: audioService,
            surahName: _surahName,
          ),
      ],
    );
  }

  Widget _buildVerseArea(QuranAudioService audioService) {
    final surahText = ref.watch(surahTextProvider(_selectedSurah!));
    final translations = _showTranslation
        ? ref.watch(surahTranslationProvider(_selectedSurah!))
        : null;

    // Tenter de charger les données enrichies (avec timings karaoke)
    // Disponible pour les sourates du Juz Amma (78-114) via le backend
    final enrichedAsync = ref.watch(surahContentProvider(_selectedSurah!));

    // Si les données enrichies sont disponibles → mode karaoke
    final enrichedVerses = enrichedAsync.valueOrNull?.verses;
    if (enrichedVerses != null && enrichedVerses.isNotEmpty) {
      final hasTimings = enrichedVerses.any((v) => v.audioTimings != null);
      if (hasTimings) {
        return KaraokeVerseDisplay(
          verses: enrichedVerses,
          audioService: audioService,
          startVerse: _startVerse,
          showTranslation: _showTranslation,
          translations: translations?.valueOrNull,
        );
      }
    }

    // Fallback : affichage standard sans karaoke
    return surahText.when(
      data: (verses) {
        return ListenableBuilder(
          listenable: audioService,
          builder: (context, _) {
            final currentVerse = audioService.currentEntry?.verse ?? _startVerse;

            return VerseDisplay(
              verses: verses,
              currentVerse: currentVerse,
              startVerse: _startVerse,
              showTranslation: _showTranslation,
              translations: translations?.value,
              scrollController: _scrollController,
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: HifzColors.emerald)),
      error: (e, _) => Center(
          child: Text('Erreur de chargement: $e',
              style: HifzTypo.body(color: HifzColors.wrong))),
    );
  }

  void _startLecture() {
    if (_selectedSurah == null) return;
    if (_startVerse > _endVerse) {
      setState(() {
        final tmp = _startVerse;
        _startVerse = _endVerse;
        _endVerse = tmp;
      });
    }

    final audioService = ref.read(quranAudioServiceProvider);
    audioService.buildLecturePlaylist(
      surah: _selectedSurah!,
      startVerse: _startVerse,
      endVerse: _endVerse,
    );
    audioService.play();
    setState(() => _isPlayerActive = true);
  }

  // ════════════════════════════════════════════════════════════════
  // TAB 2 — RÉVISION SRS
  // ════════════════════════════════════════════════════════════════

  Widget _buildRevisionTab(QuranAudioService audioService) {
    final playlistAsync = ref.watch(revisionPlaylistProvider);

    return playlistAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return _buildEmptyRevision();
        }
        return _buildRevisionContent(audioService, verses);
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: HifzColors.emerald)),
      error: (e, _) => _buildRevisionError(e),
    );
  }

  Widget _buildEmptyRevision() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: HifzColors.emerald.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun verset à réviser',
              style: HifzTypo.sectionTitle(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tous vos versets sont à jour ! Commencez par mémoriser de nouveaux versets dans le Wird.',
              style: HifzTypo.body(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: HifzColors.textLight),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: HifzTypo.sectionTitle(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Impossible de récupérer la playlist de révision. Vérifiez votre connexion et réessayez.',
              style: HifzTypo.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              style: HifzTypo.body(color: HifzColors.textLight),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: HifzDecor.primaryButton,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              onPressed: () => ref.invalidate(revisionPlaylistProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionContent(
      QuranAudioService audioService, List<RevisionVerse> verses) {
    final isActive = audioService.isPlaying || audioService.isPaused;

    return Column(
      children: [
        if (!isActive) ...[
          // ── Résumé de la playlist ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Récitateur
                  Text('Récitateur', style: HifzTypo.stepLabel()),
                  const SizedBox(height: 8),
                  ReciterSelector(
                    selected: audioService.reciter,
                    onChanged: (r) => audioService.setReciter(r),
                  ),

                  const SizedBox(height: 24),

                  // Stats playlist
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: HifzDecor.card,
                    child: Column(
                      children: [
                        _StatRow(
                          icon: Icons.library_music_rounded,
                          label: 'Versets à réviser',
                          value: '${verses.length}',
                        ),
                        const Divider(height: 16),
                        _StatRow(
                          icon: Icons.repeat_rounded,
                          label: 'Écoutes totales',
                          value: '${verses.fold<int>(0, (sum, v) => sum + v.adaptiveRepeat)}',
                        ),
                        const Divider(height: 16),
                        _StatRow(
                          icon: Icons.timer_rounded,
                          label: 'Durée estimée',
                          value: '~${(verses.fold<int>(0, (s, v) => s + v.adaptiveRepeat) * 8 / 60).ceil()} min',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liste des versets
                  Text('Playlist', style: HifzTypo.stepLabel()),
                  const SizedBox(height: 8),
                  ...verses.take(10).map((v) => _RevisionVerseRow(verse: v)),
                  if (verses.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${verses.length - 10} autres versets',
                        style: HifzTypo.body(color: HifzColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: HifzDecor.primaryButton,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Lancer la révision'),
                    onPressed: () {
                      audioService.buildRevisionPlaylist(verses);
                      audioService.play();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],

        if (isActive) ...[
          // ── Player actif en mode révision ──
          Expanded(
            child: ListenableBuilder(
              listenable: audioService,
              builder: (context, _) {
                final entry = audioService.currentEntry;
                if (entry == null) return const SizedBox();

                final surahText =
                    ref.watch(surahTextProvider(entry.surah));

                return surahText.when(
                  data: (versesMap) {
                    final text = versesMap[entry.verse] ?? '';
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tier badge
                            if (entry.srsTier != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _tierColor(entry.srsTier!)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.srsTier!.toUpperCase(),
                                  style: HifzTypo.stepLabel(
                                      color: _tierColor(entry.srsTier!)),
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Verset arabe
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                text,
                                style: GoogleFonts.amiri(
                                  fontSize: 28,
                                  height: 2.0,
                                  color: HifzColors.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sourate ${entry.surah} — Verset ${entry.verse}',
                              style: HifzTypo.body(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: HifzColors.emerald)),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
          ),
          PlayerControls(service: audioService),
        ],
      ],
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'fragile':
        return HifzColors.srsFragile;
      case 'en_cours':
        return HifzColors.srsEnCours;
      case 'acquis':
        return HifzColors.srsAcquis;
      case 'solide':
        return HifzColors.srsSolide;
      case 'maitrise':
      case 'maîtrisé':
        return HifzColors.srsMaitrise;
      case 'ancre':
      case 'ancré':
        return HifzColors.srsAncre;
      default:
        return HifzColors.srsNew;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGETS UTILITAIRES
  // ════════════════════════════════════════════════════════════════

  String? _surahName;

  Widget _buildSurahDropdown(List<SurahInfo> surahs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: HifzColors.ivory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HifzColors.ivoryDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSurah,
          isExpanded: true,
          hint: Text('Choisir une sourate', style: HifzTypo.body()),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: HifzColors.emerald),
          items: surahs.map((s) {
            return DropdownMenuItem<int>(
              value: s.number,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '${s.number}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: HifzColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(s.nameAr,
                        style: GoogleFonts.amiri(
                            fontSize: 16, color: HifzColors.textDark)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.nameFr,
                        style: HifzTypo.body(color: HifzColors.textMedium),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${s.totalVerses}v',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: HifzColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            final surah = surahs.firstWhere((s) => s.number == v);
            setState(() {
              _selectedSurah = v;
              _totalVerses = surah.totalVerses;
              _startVerse = 1;
              _endVerse = surah.totalVerses;
              _surahName = '${surah.nameAr} — ${surah.nameFr}';
            });
          },
        ),
      ),
    );
  }

  Widget _buildVerseField({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: HifzColors.ivory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HifzColors.ivoryDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value.clamp(1, max),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: HifzColors.emerald, size: 18),
          items: List.generate(max, (i) {
            final v = i + 1;
            return DropdownMenuItem(
              value: v,
              child: Text('$label $v', style: HifzTypo.body()),
            );
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SOUS-WIDGETS PRIVÉS
// ═════════════════════════════════════════════════════════════════

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HifzColors.emerald),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label, style: HifzTypo.body())),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HifzColors.textDark)),
      ],
    );
  }
}

class _RevisionVerseRow extends StatelessWidget {
  const _RevisionVerseRow({required this.verse});

  final RevisionVerse verse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${verse.surahNameAr} — v${verse.verse}',
              style: HifzTypo.body(color: HifzColors.textDark),
            ),
          ),
          Text(
            '${verse.adaptiveRepeat}×',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: HifzColors.textMedium,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              verse.tier.toUpperCase(),
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (verse.tier.toLowerCase()) {
      case 'fragile':
        return HifzColors.srsFragile;
      case 'en_cours':
        return HifzColors.srsEnCours;
      case 'acquis':
        return HifzColors.srsAcquis;
      default:
        return HifzColors.srsNew;
    }
  }
}

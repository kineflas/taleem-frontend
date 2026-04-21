/// HifzMapScreen — La carte du voyage du Hafiz.
///
/// Remplace le HifzHubScreen. Affiche les sourates de Juz Amma
/// comme étapes d'un voyage, avec la progression de l'élève.
/// En bas : bouton « Commencer mon Wird ».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/hifz_v2_service.dart' show JourneyMapResponse, SurahMapEntry, WirdTodayResponse, EnrichedSurahResponse;
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../../quran_player/providers/quran_player_provider.dart';
import '../../quran_player/services/quran_audio_service.dart';
import '../../quran_player/models/player_models.dart';

class HifzMapScreen extends ConsumerWidget {
  const HifzMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(journeyMapProvider);
    final wirdAsync = ref.watch(wirdTodayProvider);

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: mapAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HifzColors.emerald),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: HifzColors.textLight),
                const SizedBox(height: 16),
                Text('Impossible de charger la carte',
                    style: HifzTypo.body(color: HifzColors.textMedium)),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: HifzDecor.secondaryButton,
                  onPressed: () => ref.invalidate(journeyMapProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (map) => CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, map)),

            // ── Stats rapides ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildStats(map)),

            // ── Liste des sourates ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: map.surahs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final surah = map.surahs[map.surahs.length - 1 - i]; // 114 first
                  return _SurahCard(surah: surah);
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bouton Wird flottant ───────────────────────────────────────
      bottomNavigationBar: wirdAsync.when(
        data: (wird) => _buildWirdButton(context, ref, wird),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JourneyMapResponse map) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HifzColors.emeraldDark, HifzColors.emerald],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + streak
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      map.titleAr,
                      style: HifzTypo.verse(
                          size: 24, color: HifzColors.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      map.titleFr,
                      style: HifzTypo.body(
                          color: HifzColors.ivory.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              // Lecteur Quran
              GestureDetector(
                onTap: () => context.push('/quran-player'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: HifzColors.ivory.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headphones_rounded,
                          color: HifzColors.ivory, size: 18),
                      SizedBox(width: 4),
                      Icon(Icons.play_arrow_rounded,
                          color: HifzColors.ivory, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Streak
              if (map.currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: HifzColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: HifzColors.gold, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${map.currentStreak}',
                        style: HifzTypo.sectionTitle(color: HifzColors.gold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // XP bar
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: HifzColors.goldLight, size: 18),
              const SizedBox(width: 6),
              Text(
                '${map.totalXp} XP',
                style: HifzTypo.body(color: HifzColors.ivory),
              ),
              const Spacer(),
              Text(
                '${map.totalStars} ★',
                style: HifzTypo.body(color: HifzColors.goldLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(JourneyMapResponse map) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.menu_book_rounded,
            value: '${map.totalVersesMemorized}',
            label: 'versets',
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.auto_awesome,
            value: '${map.surahs.where((s) => s.isCompleted).length}',
            label: 'sourates',
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.trending_up_rounded,
            value: map.level,
            label: 'niveau',
          ),
        ],
      ),
    );
  }

  Widget _buildWirdButton(
      BuildContext context, WidgetRef ref, WirdTodayResponse wird) {
    final isCompleted = wird.status == 'COMPLETED';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: HifzColors.ivory,
        boxShadow: [
          BoxShadow(
            color: HifzColors.textDark.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: isCompleted
                  ? HifzDecor.secondaryButton.copyWith(
                      backgroundColor:
                          WidgetStatePropertyAll(HifzColors.emeraldMuted),
                    )
                  : HifzDecor.primaryButton,
              onPressed: isCompleted
                  ? null
                  : () => context.push('/hifz-v2/ikhtiar'),
              child: Text(
                isCompleted
                    ? 'Wird terminé ✓'
                    : wird.status == 'IN_PROGRESS'
                        ? 'Reprendre mon Wird'
                        : 'Commencer mon Wird',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: HifzDecor.card,
        child: Column(
          children: [
            Icon(icon, color: HifzColors.emerald, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: HifzTypo.sectionTitle(color: HifzColors.textDark)),
            const SizedBox(height: 2),
            Text(label,
                style: HifzTypo.body(color: HifzColors.textLight)),
          ],
        ),
      ),
    );
  }
}

class _SurahCard extends ConsumerWidget {
  const _SurahCard({required this.surah});

  final SurahMapEntry surah;

  Color get _statusColor {
    if (surah.isCompleted) return HifzColors.gold;
    if (surah.versesStarted > 0) return HifzColors.emerald;
    return HifzColors.textLight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = surah.totalVerses > 0
        ? surah.versesStarted / surah.totalVerses
        : 0.0;

    return Container(
      decoration: HifzDecor.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSurahDetail(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro de sourate
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${surah.surahNumber}',
                    style: HifzTypo.body(color: _statusColor).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos sourate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              surah.nameAr,
                              style: HifzTypo.verse(size: 18),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          if (surah.isCompleted)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_circle,
                                  color: HifzColors.gold, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        surah.nameFr,
                        style: HifzTypo.body(color: HifzColors.textMedium),
                      ),
                      const SizedBox(height: 8),
                      // Barre de progression
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: HifzColors.ivoryDark,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  surah.isCompleted
                                      ? HifzColors.gold
                                      : HifzColors.emerald,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${surah.versesStarted}/${surah.totalVerses}',
                            style: HifzTypo.body(color: HifzColors.textLight)
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      // Étoiles
                      if (surah.totalStars > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: HifzColors.goldLight, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${surah.totalStars}/${surah.maxStars}',
                              style:
                                  HifzTypo.body(color: HifzColors.gold)
                                      .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                const Icon(Icons.chevron_right,
                    color: HifzColors.textLight, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSurahDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HifzColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _SurahDetailModal(surah: surah),
    );
  }
}

/// ── Modal détail sourate avec lecteur embarqué ──────────────────

class _SurahDetailModal extends ConsumerStatefulWidget {
  const _SurahDetailModal({required this.surah});
  final SurahMapEntry surah;

  @override
  ConsumerState<_SurahDetailModal> createState() => _SurahDetailModalState();
}

class _SurahDetailModalState extends ConsumerState<_SurahDetailModal> {
  bool _isPlayerMode = false;
  bool _isLaunchingWird = false;
  final ScrollController _scrollController = ScrollController();

  SurahMapEntry get surah => widget.surah;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Lance le Wird directement sur la sourate sélectionnée.
  Future<void> _launchWird() async {
    if (_isLaunchingWird) return;
    setState(() => _isLaunchingWird = true);

    try {
      final service = ref.read(hifzV2ServiceProvider);

      // 1. Récupérer le Wird pour cette sourate
      final wird = await service.fetchWirdToday(surahNumber: surah.surahNumber);

      // 2. Charger le contenu enrichi
      final surahNumbers = <int>{};
      for (final bloc in wird.blocs) {
        for (final v in bloc.verses) {
          surahNumbers.add(v.surahNumber);
        }
      }

      final surahContents = <int, EnrichedSurahResponse>{};
      final futures = surahNumbers.map(
        (sn) =>
            service.fetchSurahContent(sn).then((r) => surahContents[sn] = r),
      );
      await Future.wait(futures);

      // 3. Construire les EnrichedVerse pour chaque bloc
      EnrichedVerse? findVerse(int s, int v) {
        final content = surahContents[s];
        if (content == null) return null;
        return content.verses
            .where((ev) => ev.verseNumber == v)
            .firstOrNull;
      }

      final jadidVerses = <EnrichedVerse>[];
      final qaribVerses = <EnrichedVerse>[];
      final baidVerses = <EnrichedVerse>[];

      for (final bloc in wird.blocs) {
        for (final v in bloc.verses) {
          final enriched = findVerse(v.surahNumber, v.verseNumber);
          if (enriched == null) continue;
          switch (bloc.blocType) {
            case 'JADID':
              jadidVerses.add(enriched);
            case 'QARIB':
              qaribVerses.add(enriched);
            case 'BAID':
              baidVerses.add(enriched);
          }
        }
      }

      if (jadidVerses.isEmpty && qaribVerses.isEmpty && baidVerses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun verset disponible pour cette sourate'),
            ),
          );
        }
        return;
      }

      final session = WirdSession(
        date: DateTime.now(),
        jadidVerses: jadidVerses,
        qaribVerses: qaribVerses,
        baidVerses: baidVerses,
        reciterFolder: wird.reciterFolder,
      );

      // 4. Démarrer la session backend
      await ref
          .read(wirdSessionProvider.notifier)
          .start(surahNumber: surah.surahNumber);

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer la modale
      context.push('/hifz-v2/wird', extra: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunchingWird = false);
    }
  }

  /// Active le mode lecteur embarqué.
  void _startPlayer(EnrichedSurahResponse content) {
    final audioService = ref.read(quranAudioServiceProvider);
    audioService.buildLecturePlaylist(
      surah: surah.surahNumber,
      startVerse: 1,
      endVerse: content.verseCount,
      surahName: content.nameAr,
    );
    audioService.play();
    setState(() => _isPlayerMode = true);
  }

  /// Arrête le lecteur et revient aux boutons d'action.
  void _stopPlayer() {
    ref.read(quranAudioServiceProvider).stop();
    setState(() => _isPlayerMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final asyncContent = ref.watch(surahContentProvider(surah.surahNumber));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: asyncContent.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: HifzColors.emerald),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Erreur : $e',
                style: HifzTypo.body(color: HifzColors.textLight)),
          ),
        ),
        data: (content) {
          final audioService = ref.watch(quranAudioServiceProvider);

          return Column(
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HifzColors.ivoryDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Header fixe ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Text(
                      content.nameAr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: HifzTypo.verse(size: 28, color: HifzColors.emerald),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${content.nameFr} — ${content.verseCount} versets',
                      textAlign: TextAlign.center,
                      style: HifzTypo.body(color: HifzColors.textMedium),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MiniStat(
                            '${surah.versesStarted}/${surah.totalVerses}',
                            'Versets'),
                        _MiniStat('${surah.totalStars}', 'Étoiles'),
                        _MiniStat(
                            '${surah.averageScore.round()}%', 'Score moy.'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: HifzColors.ivoryDark),
                  ],
                ),
              ),

              // ── Liste des versets (scrollable) ──
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
                  itemCount: content.verses.length,
                  itemBuilder: (_, i) {
                    final v = content.verses[i];
                    final isCurrentVerse = _isPlayerMode &&
                        audioService.currentEntry != null &&
                        audioService.currentEntry!.verse == v.verseNumber;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrentVerse
                              ? HifzColors.gold.withOpacity(0.08)
                              : HifzColors.ivoryWarm,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentVerse
                              ? Border.all(
                                  color: HifzColors.gold.withOpacity(0.4),
                                  width: 1.5)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCurrentVerse
                                        ? HifzColors.gold.withOpacity(0.2)
                                        : HifzColors.emerald.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: isCurrentVerse
                                      ? Icon(Icons.volume_up_rounded,
                                          color: HifzColors.gold, size: 14)
                                      : Text(
                                          '${v.verseNumber}',
                                          style: HifzTypo.body(
                                                  color: HifzColors.emerald)
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                        ),
                                ),
                                const Spacer(),
                                // Mini play button per verse
                                if (_isPlayerMode)
                                  GestureDetector(
                                    onTap: () {
                                      final idx = audioService.playlist.indexWhere(
                                          (e) => e.verse == v.verseNumber);
                                      if (idx >= 0) audioService.jumpToIndex(idx);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isCurrentVerse
                                            ? HifzColors.gold.withOpacity(0.15)
                                            : HifzColors.emerald.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        isCurrentVerse
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 14,
                                        color: isCurrentVerse
                                            ? HifzColors.gold
                                            : HifzColors.emerald,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              v.textAr,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: HifzTypo.verse(size: 20),
                            ),
                            if (v.textFr != null && v.textFr!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(v.textFr!, style: HifzTypo.translation()),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Footer : lecteur embarqué OU boutons d'action ──
              _isPlayerMode
                  ? _buildEmbeddedPlayer(audioService, bottomPad)
                  : _buildActionButtons(content, bottomPad),
            ],
          );
        },
      ),
    );
  }

  /// Lecteur audio embarqué dans le footer de la modale.
  Widget _buildEmbeddedPlayer(QuranAudioService audio, double bottomPad) {
    final entry = audio.currentEntry;
    final progress = audio.duration.inMilliseconds > 0
        ? audio.position.inMilliseconds / audio.duration.inMilliseconds
        : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFF5C6BC0).withOpacity(0.06),
        border: const Border(
          top: BorderSide(color: Color(0xFFBBBFD6), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF5C6BC0)),
            ),
          ),
          const SizedBox(height: 10),

          // Contrôles
          Row(
            children: [
              // Info verset actuel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry != null
                          ? 'Verset ${entry.verse}/${audio.playlist.length}'
                          : 'Prêt',
                      style: HifzTypo.body(color: const Color(0xFF5C6BC0))
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'x${audio.globalRepeat} — ${audio.reciter.nameFr}',
                      style: HifzTypo.body(color: HifzColors.textLight)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Prev
              _PlayerIconButton(
                icon: Icons.skip_previous_rounded,
                onTap: audio.currentIndex > 0 ? () => audio.previous() : null,
              ),
              const SizedBox(width: 4),

              // Play/Pause (plus grand)
              GestureDetector(
                onTap: () => audio.togglePlayPause(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6BC0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    audio.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: HifzColors.ivory,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Next
              _PlayerIconButton(
                icon: Icons.skip_next_rounded,
                onTap: audio.currentIndex < audio.playlist.length - 1
                    ? () => audio.next()
                    : null,
              ),
              const SizedBox(width: 8),

              // Repeat cycle
              _PlayerIconButton(
                icon: Icons.repeat_rounded,
                label: 'x${audio.globalRepeat}',
                onTap: () {
                  final next = audio.globalRepeat >= 5 ? 1 : audio.globalRepeat + 1;
                  audio.setGlobalRepeat(next);
                },
              ),
              const SizedBox(width: 4),

              // Fermer le player
              _PlayerIconButton(
                icon: Icons.close_rounded,
                onTap: _stopPlayer,
                color: HifzColors.textLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Boutons d'action classiques (Écouter / Mémoriser / ASR / Fermer).
  Widget _buildActionButtons(
      EnrichedSurahResponse content, double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: HifzColors.ivory,
        border: const Border(
          top: BorderSide(color: HifzColors.ivoryDark, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne 1 : Écouter + Mémoriser
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.headphones_rounded,
                  label: 'Écouter',
                  color: const Color(0xFF5C6BC0),
                  onTap: () => _startPlayer(content),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.auto_stories_rounded,
                  label: _isLaunchingWird ? 'Chargement...' : 'Mémoriser',
                  color: HifzColors.emerald,
                  onTap: _isLaunchingWird ? () {} : _launchWird,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 2 : Vérifier ASR + Fermer
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.mic_rounded,
                  label: 'Vérifier (ASR)',
                  color: HifzColors.gold,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/hifz-v2/surah-asr',
                      extra: {
                        'surahNumber': surah.surahNumber,
                        'surahNameAr': surah.nameAr,
                        'surahNameFr': surah.nameFr,
                        'allVerses': content.verses,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: HifzDecor.secondaryButton.copyWith(
                    minimumSize:
                        const WidgetStatePropertyAll(Size.fromHeight(44)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit bouton icône pour les contrôles du lecteur.
class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF5C6BC0);
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1.0,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 22),
              if (label != null) ...[
                const SizedBox(width: 2),
                Text(
                  label!,
                  style: HifzTypo.body(color: c)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: HifzTypo.sectionTitle(color: HifzColors.emerald)),
        Text(label, style: HifzTypo.body(color: HifzColors.textLight)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: HifzTypo.body(color: color).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HifzMapScreen — La carte du voyage du Hafiz.
///
/// Remplace le HifzHubScreen. Affiche les sourates de Juz Amma
/// comme étapes d'un voyage, avec la progression de l'élève.
/// En bas : bouton « Commencer mon Wird ».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/hifz_v2_service.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';

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
    final hasVerses = wird.totalVerses > 0;

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
          if (hasVerses && !isCompleted)
            Text(
              '${wird.totalVerses} versets · ~${wird.estimatedDurationMinutes} min',
              style: HifzTypo.body(color: HifzColors.textMedium),
            ),
          if (hasVerses && !isCompleted) const SizedBox(height: 8),
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
                  : () async {
                      // Charger le contenu des sourates et construire le WirdSession
                      await _startWird(context, ref, wird);
                    },
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

  Future<void> _startWird(
      BuildContext context, WidgetRef ref, WirdTodayResponse wird) async {
    final service = ref.read(hifzV2ServiceProvider);

    // Charger le contenu enrichi pour chaque sourate unique dans le Wird
    final allVerseRefs = <({int surah, int verse})>[];
    final surahNumbers = <int>{};

    for (final bloc in wird.blocs) {
      for (final v in bloc.verses) {
        allVerseRefs.add((surah: v.surahNumber, verse: v.verseNumber));
        surahNumbers.add(v.surahNumber);
      }
    }

    // Charger toutes les sourates en parallèle
    final surahContents = <int, EnrichedSurahResponse>{};
    try {
      final futures = surahNumbers.map(
        (sn) => service.fetchSurahContent(sn).then((r) => surahContents[sn] = r),
      );
      await Future.wait(futures);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
      return;
    }

    // Construire les EnrichedVerse pour chaque bloc
    EnrichedVerse? _findVerse(int surah, int verse) {
      final content = surahContents[surah];
      if (content == null) return null;
      return content.verses.where((v) => v.verseNumber == verse).firstOrNull;
    }

    final jadidVerses = <EnrichedVerse>[];
    final qaribVerses = <EnrichedVerse>[];
    final baidVerses = <EnrichedVerse>[];

    for (final bloc in wird.blocs) {
      for (final v in bloc.verses) {
        final enriched = _findVerse(v.surahNumber, v.verseNumber);
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

    final session = WirdSession(
      date: DateTime.now(),
      jadidVerses: jadidVerses,
      qaribVerses: qaribVerses,
      baidVerses: baidVerses,
      reciterFolder: wird.reciterFolder,
    );

    // Démarrer la session côté backend
    await ref.read(wirdSessionProvider.notifier).start();

    if (!context.mounted) return;
    context.push('/hifz-v2/wird', extra: session);
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
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;

        return Container(
          // Hauteur fixe : 70% de l'écran max
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final asyncContent =
                  ref.watch(surahContentProvider(surah.surahNumber));

              return asyncContent.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: HifzColors.emerald),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Erreur : $e',
                      style: HifzTypo.body(color: HifzColors.textLight),
                    ),
                  ),
                ),
                data: (content) => Column(
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

                    // ── Header fixe (ne scroll pas) ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          Text(
                            content.nameAr,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: HifzTypo.verse(
                                size: 28, color: HifzColors.emerald),
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
                              _MiniStat(
                                  '${surah.totalStars}', 'Étoiles'),
                              _MiniStat(
                                  '${surah.averageScore.round()}%',
                                  'Score moy.'),
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
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
                        itemCount: content.verses.length,
                        itemBuilder: (_, i) {
                          final v = content.verses[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: HifzColors.ivoryWarm,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Numéro du verset
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: HifzColors.emerald
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${i + 1}',
                                          style: HifzTypo.body(
                                                  color: HifzColors.emerald)
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    v.textAr,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: HifzTypo.verse(size: 20),
                                  ),
                                  if (v.textFr != null &&
                                      v.textFr!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      v.textFr!,
                                      style: HifzTypo.translation(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Bouton fermer en bas ──
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomPad),
                      decoration: BoxDecoration(
                        color: HifzColors.ivory,
                        border: Border(
                          top: BorderSide(
                              color: HifzColors.ivoryDark, width: 1),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: HifzDecor.secondaryButton,
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Fermer'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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

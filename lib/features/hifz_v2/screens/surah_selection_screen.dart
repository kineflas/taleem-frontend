/// SurahSelectionScreen — Écran Ikhtiar (اختيار).
///
/// Permet à l'apprenant de choisir la sourate sur laquelle
/// il veut travailler avant de lancer le Wird.
///
/// Sections :
///   1. Sourate en cours (continuer)
///   2. Sourates avec révisions dues
///   3. Suggestions de nouvelles sourates
///   4. Toutes les sourates (browse)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/hifz_v2_service.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';

class SurahSelectionScreen extends ConsumerStatefulWidget {
  const SurahSelectionScreen({super.key});

  @override
  ConsumerState<SurahSelectionScreen> createState() =>
      _SurahSelectionScreenState();
}

class _SurahSelectionScreenState extends ConsumerState<SurahSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final suggestedAsync = ref.watch(suggestedSurahsProvider);

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: suggestedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: HifzColors.emerald),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: HifzColors.textLight),
                const SizedBox(height: 16),
                Text('Impossible de charger',
                    style: HifzTypo.body(color: HifzColors.textMedium)),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: HifzDecor.secondaryButton,
                  onPressed: () => ref.invalidate(suggestedSurahsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (data) => _buildContent(data),
        ),
      ),
    );
  }

  Widget _buildContent(SuggestedSurahsResponse data) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Sourate en cours ──
            if (data.currentSurah != null)
              SliverToBoxAdapter(
                child: _buildSection(
                  'Continuer',
                  'واصل',
                  [data.currentSurah!],
                  isPrimary: true,
                ),
              ),

            // ── Révisions dues ──
            if (data.reviewDueSurahs.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSection(
                  'Révisions dues',
                  'مراجعة',
                  data.reviewDueSurahs,
                  showReviewBadge: true,
                ),
              ),

            // ── Suggestions ──
            if (data.suggestions.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSection(
                  'Nouvelles sourates',
                  'جديد',
                  data.suggestions,
                ),
              ),

            // ── Browse toutes les sourates ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Text('Toutes les sourates',
                        style: HifzTypo.sectionTitle()),
                    const Spacer(),
                    Text('جميع السور',
                        style: HifzTypo.verse(
                            size: 16, color: HifzColors.textLight)),
                  ],
                ),
              ),
            ),

            // ── Liste complète via journeyMap ──
            _buildAllSurahsList(),

            // Padding bottom
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // ── Loading overlay ──
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: HifzColors.ivory.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: HifzColors.emerald),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HifzColors.emeraldDark, HifzColors.emerald],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: HifzColors.ivory),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Text(
                'اختيار السورة',
                style: HifzTypo.verse(size: 22, color: HifzColors.gold),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choisis ta sourate pour cette session',
            style: HifzTypo.body(color: HifzColors.ivory.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String titleFr,
    String titleAr,
    List<SuggestedSurah> surahs, {
    bool isPrimary = false,
    bool showReviewBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(titleFr, style: HifzTypo.sectionTitle()),
              const Spacer(),
              Text(titleAr,
                  style:
                      HifzTypo.verse(size: 16, color: HifzColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          ...surahs.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SurahSelectionCard(
                  surah: s,
                  isPrimary: isPrimary,
                  showReviewBadge: showReviewBadge,
                  onTap: () => _launchWird(s.surahNumber),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAllSurahsList() {
    final mapAsync = ref.watch(journeyMapProvider);

    return mapAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: HifzColors.emerald),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (map) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: map.surahs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            // 114 first (from end of list)
            final surah = map.surahs[map.surahs.length - 1 - i];
            // Mode Rapide : éligible si ≥80% des versets sont démarrés
            // et score moyen ≥ 55 (Acquis/Tier 4+)
            final isQuickEligible = surah.totalVerses > 0 &&
                surah.versesStarted / surah.totalVerses >= 0.80 &&
                surah.averageScore >= 55;
            return _AllSurahCard(
              surah: surah,
              onTap: () => _launchWird(surah.surahNumber),
              onQuickVerify: isQuickEligible
                  ? () => _launchQuickVerify(surah.surahNumber, surah.nameAr, surah.nameFr)
                  : null,
              // ASR disponible pour TOUTES les sourates — permet de valider
              // une sourate déjà connue sans avoir à démarrer 80% des versets
              onAsrVerify: () => _launchAsrVerify(surah.surahNumber, surah.nameAr, surah.nameFr),
            );
          },
        ),
      ),
    );
  }

  /// Lance le Wird pour la sourate sélectionnée.
  Future<void> _launchWird(int surahNumber) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(hifzV2ServiceProvider);

      // 1. Récupérer le Wird pour cette sourate
      final wird = await service.fetchWirdToday(surahNumber: surahNumber);

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
      EnrichedVerse? findVerse(int surah, int verse) {
        final content = surahContents[surah];
        if (content == null) return null;
        return content.verses
            .where((v) => v.verseNumber == verse)
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
          .start(surahNumber: surahNumber);

      if (!mounted) return;
      context.push('/hifz-v2/wird', extra: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Lance le Mode Rapide pour une sourate éligible.
  Future<void> _launchQuickVerify(
      int surahNumber, String nameAr, String nameFr) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(hifzV2ServiceProvider);
      final content = await service.fetchSurahContent(surahNumber);

      if (!mounted) return;
      context.push('/hifz-v2/quick-verify', extra: {
        'surahNumber': surahNumber,
        'surahNameAr': nameAr,
        'surahNameFr': nameFr,
        'allVerses': content.verses,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Lance la validation vocale ASR pour une sourate complète.
  Future<void> _launchAsrVerify(
      int surahNumber, String nameAr, String nameFr) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(hifzV2ServiceProvider);
      final content = await service.fetchSurahContent(surahNumber);

      if (!mounted) return;
      context.push('/hifz-v2/surah-asr', extra: {
        'surahNumber': surahNumber,
        'surahNameAr': nameAr,
        'surahNameFr': nameFr,
        'allVerses': content.verses,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Widgets internes ────────────────────────────────────────────────

/// Carte pour une sourate suggérée (sections Continuer / Révision / Nouveau).
class _SurahSelectionCard extends StatelessWidget {
  const _SurahSelectionCard({
    required this.surah,
    required this.onTap,
    this.isPrimary = false,
    this.showReviewBadge = false,
  });

  final SuggestedSurah surah;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool showReviewBadge;

  @override
  Widget build(BuildContext context) {
    final progress = surah.totalVerses > 0
        ? surah.versesStarted / surah.totalVerses
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? HifzColors.emeraldMuted : HifzColors.ivoryWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? HifzColors.emerald.withOpacity(0.3)
              : HifzColors.ivoryDark,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro sourate
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? HifzColors.emerald
                        : HifzColors.emerald.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${surah.surahNumber}',
                    style: HifzTypo.body(
                      color: isPrimary ? HifzColors.ivory : HifzColors.emerald,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
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
                          if (showReviewBadge && surah.reviewCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: HifzColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${surah.reviewCount} dues',
                                style: HifzTypo.body(color: HifzColors.gold)
                                    .copyWith(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        surah.nameFr,
                        style: HifzTypo.body(color: HifzColors.textMedium),
                      ),
                      if (surah.versesStarted > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: HifzColors.ivoryDark,
                                  valueColor: const AlwaysStoppedAnimation(
                                      HifzColors.emerald),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${surah.versesStarted}/${surah.totalVerses}',
                              style: HifzTypo.body(color: HifzColors.textLight)
                                  .copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          '${surah.totalVerses} versets',
                          style: HifzTypo.body(color: HifzColors.textLight)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  isPrimary ? Icons.play_arrow_rounded : Icons.chevron_right,
                  color: isPrimary ? HifzColors.emerald : HifzColors.textLight,
                  size: isPrimary ? 28 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte compacte pour la liste "Toutes les sourates".
class _AllSurahCard extends StatelessWidget {
  const _AllSurahCard({
    required this.surah,
    required this.onTap,
    this.onQuickVerify,
    this.onAsrVerify,
  });

  final SurahMapEntry surah;
  final VoidCallback onTap;
  final VoidCallback? onQuickVerify;
  final VoidCallback? onAsrVerify;

  @override
  Widget build(BuildContext context) {
    final progress = surah.totalVerses > 0
        ? surah.versesStarted / surah.totalVerses
        : 0.0;

    final statusColor = surah.isCompleted
        ? HifzColors.gold
        : surah.versesStarted > 0
            ? HifzColors.emerald
            : HifzColors.textLight;

    return Container(
      decoration: HifzDecor.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Numéro
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${surah.surahNumber}',
                    style: HifzTypo.body(color: statusColor)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),

                // Nom
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.nameAr,
                          style: HifzTypo.verse(size: 16),
                          textDirection: TextDirection.rtl),
                      Text(surah.nameFr,
                          style: HifzTypo.body(color: HifzColors.textMedium)
                              .copyWith(fontSize: 12)),
                    ],
                  ),
                ),

                // Progress
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${surah.versesStarted}/${surah.totalVerses}',
                        style: HifzTypo.body(color: HifzColors.textLight)
                            .copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: HifzColors.ivoryDark,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Icônes Mode Rapide + ASR ou chevron
                if (onQuickVerify != null || onAsrVerify != null) ...[
                  if (onAsrVerify != null)
                    GestureDetector(
                      onTap: onAsrVerify,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: HifzColors.goldMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic_rounded,
                            color: HifzColors.gold, size: 18),
                      ),
                    ),
                  if (onQuickVerify != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onQuickVerify,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: HifzColors.emeraldMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt,
                            color: HifzColors.emerald, size: 18),
                      ),
                    ),
                  ],
                ] else if (surah.isCompleted)
                  const Icon(Icons.check_circle,
                      color: HifzColors.gold, size: 18)
                else
                  const Icon(Icons.chevron_right,
                      color: HifzColors.textLight, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

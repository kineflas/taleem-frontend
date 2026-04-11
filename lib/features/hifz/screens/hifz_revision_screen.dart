import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../models/hifz_score_model.dart';
import '../providers/hifz_provider.dart';
import '../providers/quran_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SILSILA — Mode MURAJA'A SMART
//
// 3 innovations vs la version précédente :
//   1. Interleaving automatique : les versets sont triés par alternance de
//      sourates pour forcer la discrimination (Rohrer & Taylor, 2007 : +43-76%)
//   2. Évaluation 3 niveaux (🟢 J+7 / 🟡 J+3 / 🔴 J+1) au lieu du binaire
//   3. Versets 🔴 remontent en priorité dans la session
//
// ReviewScore et reviewIntervals sont importés depuis ../models/hifz_score_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class HifzRevisionScreen extends ConsumerStatefulWidget {
  const HifzRevisionScreen({super.key});

  @override
  ConsumerState<HifzRevisionScreen> createState() => _HifzRevisionScreenState();
}

class _HifzRevisionScreenState extends ConsumerState<HifzRevisionScreen> {
  late int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying  = false;
  int? _playingVerse;

  // Cache des scores de la session en cours
  final Map<String, ReviewScore> _sessionScores = {};

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
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // ── Interleaving sort ────────────────────────────────────────────────────
  // Algorithme : trier par ordre de priorité (🔴 > 🟡 > 🟢) puis interleaver
  // les sourates (alterner) pour forcer la discrimination.
  List<VerseProgressModel> _applyInterleaving(List<VerseProgressModel> verses) {
    if (verses.length <= 1) return verses;

    // Trier par mastery : red en premier, puis orange, puis green
    final sorted = [...verses]..sort((a, b) {
      final priorityA = a.mastery == VerseMastery.red ? 0 : a.mastery == VerseMastery.orange ? 1 : 2;
      final priorityB = b.mastery == VerseMastery.red ? 0 : b.mastery == VerseMastery.orange ? 1 : 2;
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return a.surahNumber.compareTo(b.surahNumber);
    });

    // Interleaving par sourate : on distribue les versets en alternant les sourates
    final Map<int, List<VerseProgressModel>> bySurah = {};
    for (final v in sorted) {
      bySurah.putIfAbsent(v.surahNumber, () => []).add(v);
    }

    final surahKeys = bySurah.keys.toList();
    final result = <VerseProgressModel>[];
    int maxLen = bySurah.values.map((l) => l.length).reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      for (final key in surahKeys) {
        final list = bySurah[key]!;
        if (i < list.length) result.add(list[i]);
      }
    }

    return result;
  }

  // ── Noms des sourates (114 entrées complètes) ─────────────────────────────
  static const List<String> _surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
    'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
    'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
    'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
    'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
    'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
    'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',  // ← Al-Ma'arij (70)
    'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
    'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الإنفطار', 'المطففين', 'الانشقاق', 'البروج',
    'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
    'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
    'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس',
  ];

  String _surahName(int surahNumber) {
    if (surahNumber < 1 || surahNumber > _surahNames.length) return 'سورة $surahNumber';
    return _surahNames[surahNumber - 1];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dueVersesAsync = ref.watch(hifzDueVersesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Murājaʿa — Révisions'),
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
        data: (allVerses) {
          // Filtrer les versets dus
          final rawDue = allVerses.where((v) {
            final nextReview = DateTime.parse(v.nextReviewDate);
            return nextReview.isBefore(DateTime.now().add(const Duration(days: 1)));
          }).toList();

          // Appliquer l'interleaving
          final dueVerses = _applyInterleaving(rawDue);

          if (dueVerses.isEmpty) {
            return _buildEmptyState(context);
          }

          // Statistiques rapides
          final redCount    = rawDue.where((v) => v.mastery == VerseMastery.red).length;
          final orangeCount = rawDue.where((v) => v.mastery == VerseMastery.orange).length;
          final greenCount  = rawDue.where((v) => v.mastery == VerseMastery.green).length;

          return Column(
            children: [
              // En-tête résumé
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Column(
                  children: [
                    Row(
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
                        // Répartition mastery
                        Row(
                          children: [
                            _masteryChip('🔴', redCount, Colors.red),
                            const SizedBox(width: 6),
                            _masteryChip('🟡', orangeCount, Colors.orange),
                            const SizedBox(width: 6),
                            _masteryChip('🟢', greenCount, Colors.green),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / dueVerses.length,
                        minHeight: 6,
                        backgroundColor: AppColors.heatmapEmpty,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // Interleaving notice
              Container(
                color: AppColors.primary.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔀', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      'Ordre interleaving actif — alternance des sourates',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),

              // Cartes de versets (PageView)
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Aucune révision requise !',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Bravo, vous êtes à jour !',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Text(
              'Revenez demain pour la prochaine session de révision espacée.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _masteryChip(String emoji, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$emoji $count',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVerseCard(
      BuildContext context, WidgetRef ref, int idx, VerseProgressModel verse) {
    final verseAsync = ref.watch(
      quranVerseProvider((surah: verse.surahNumber, verse: verse.verseNumber)),
    );
    final sessionScore = _sessionScores[verse.id];
    final alreadyScored = sessionScore != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Entête du verset ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_surahName(verse.surahNumber)} : ${verse.verseNumber}',
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prochaine révision : ${DateFormat('dd/MM/yyyy', 'fr').format(DateTime.parse(verse.nextReviewDate))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                // Badge mastery actuel
                _masteryBadge(verse),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Texte du verset ───────────────────────────────────────────
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
                    height: 60,
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
                // Bouton audio
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
          const SizedBox(height: 16),

          // ── Statistiques ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('📖', verse.totalListens.toString(), 'Écoutes'),
                _statItem('✅', verse.consecutiveSuccesses.toString(), 'Succès consécutifs'),
                _statItem('🔄', verse.reviewCount.toString(), 'Révisions'),
                _statItem('🎯', '${verse.masteryScore}%', 'Maîtrise'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Évaluation MURAJA'A SMART ─────────────────────────────────
          if (alreadyScored)
            _buildScoredFeedback(context, sessionScore!, verse)
          else
            _buildEvaluationButtons(context, verse),
        ],
      ),
    );
  }

  /// Affichage après que l'élève a noté ce verset dans cette session
  Widget _buildScoredFeedback(
      BuildContext context, ReviewScore score, VerseProgressModel verse) {
    final config = {
      ReviewScore.green: (
        emoji: '🟢',
        label: 'Mémorisé',
        color: AppColors.success,
        daysFr: '7 jours',
      ),
      ReviewScore.orange: (
        emoji: '🟡',
        label: 'Hésitation',
        color: AppColors.warning,
        daysFr: '3 jours',
      ),
      ReviewScore.red: (
        emoji: '🔴',
        label: 'À retravailler',
        color: AppColors.danger,
        daysFr: 'demain',
      ),
    }[score]!;

    final nextDate = DateTime.now().add(Duration(days: reviewIntervals[score]!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: config.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prochaine révision : ${DateFormat('dd/MM/yyyy', 'fr').format(nextDate)} (${config.daysFr})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Les 3 boutons d'évaluation MURAJA'A SMART
  Widget _buildEvaluationButtons(BuildContext context, VerseProgressModel verse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Auto-évaluation',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // 🟢 Mémorisé
        _evalButton(
          context: context,
          emoji: '🟢',
          label: 'Mémorisé',
          sublabel: 'Révision dans 7 jours',
          color: AppColors.success,
          onTap: () => _handleReview(verse, ReviewScore.green),
        ),
        const SizedBox(height: 8),

        // 🟡 Hésitation
        _evalButton(
          context: context,
          emoji: '🟡',
          label: 'Hésitation',
          sublabel: 'Révision dans 3 jours',
          color: AppColors.warning,
          onTap: () => _handleReview(verse, ReviewScore.orange),
        ),
        const SizedBox(height: 8),

        // 🔴 Oublié
        _evalButton(
          context: context,
          emoji: '🔴',
          label: 'Oublié',
          sublabel: 'Révision demain',
          color: AppColors.danger,
          onTap: () => _handleReview(verse, ReviewScore.red),
        ),
      ],
    );
  }

  Widget _evalButton({
    required BuildContext context,
    required String emoji,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _masteryBadge(VerseProgressModel verse) {
    final emoji = verse.mastery == VerseMastery.red
        ? '🔴'
        : verse.mastery == VerseMastery.orange
            ? '🟡'
            : '🟢';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verse.mastery.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verse.mastery.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
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
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Handler principal ─────────────────────────────────────────────────────

  void _handleReview(VerseProgressModel verse, ReviewScore score) {
    // Enregistrer le score dans le cache session
    setState(() => _sessionScores[verse.id] = score);

    final msgs = {
      ReviewScore.green:  '✅ Excellent — Prochaine révision dans 7 jours',
      ReviewScore.orange: '⚠️ Bien — Révision dans 3 jours',
      ReviewScore.red:    '🔄 À retravailler — Révision demain',
    };
    final colors = {
      ReviewScore.green:  AppColors.success,
      ReviewScore.orange: AppColors.warning,
      ReviewScore.red:    AppColors.danger,
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msgs[score]!),
      backgroundColor: colors[score],
      duration: const Duration(seconds: 2),
    ));

    // TODO: API call — enregistrer le score en base
    // ref.read(learningApiProvider).recordVerseReview(
    //   verseId: verse.id,
    //   score: score.name.toUpperCase(),
    //   nextReviewDays: reviewIntervals[score]!,
    // );
  }
}

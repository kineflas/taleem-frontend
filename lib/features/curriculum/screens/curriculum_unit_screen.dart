import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';
import 'letter_page_screen.dart';

/// Screen listing all items in a unit with completion badges.
/// For LETTER units (Option A): shows one card per letter → LetterPageScreen.
/// For other units: shows items list with completion badges.
/// Route: /student/curriculum/:enrollmentId/unit/:unitId
class CurriculumUnitScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String unitId;

  const CurriculumUnitScreen({
    super.key,
    required this.enrollmentId,
    required this.unitId,
  });

  @override
  ConsumerState<CurriculumUnitScreen> createState() =>
      _CurriculumUnitScreenState();
}

class _CurriculumUnitScreenState extends ConsumerState<CurriculumUnitScreen> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioUrl) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      final fullUrl = '${ApiConstants.baseUrl}$audioUrl';
      setState(() => _isPlaying = true);
      await _audioPlayer.play(UrlSource(fullUrl));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  /// Navigue vers LetterPageScreen et récupère le score (étoiles) au retour
  Future<void> _openLetterPage(
    BuildContext context,
    CurriculumUnit unit,
    int existingStars,
  ) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => LetterPageScreen(
          enrollmentId: widget.enrollmentId,
          unit: unit,
          existingStars: existingStars,
        ),
      ),
    );
    // Rafraîchir la progression si un score a été retourné
    if (result != null && result > 0) {
      ref.invalidate(enrollmentProgressProvider(widget.enrollmentId));
      // Recharger aussi les détails de l'unité parente
      ref.invalidate(curriculumUnitDetailProvider(widget.unitId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitAsync = ref.watch(curriculumUnitDetailProvider(widget.unitId));
    final progressAsync =
        ref.watch(enrollmentProgressProvider(widget.enrollmentId));

    return unitAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (unit) {
        final progressMap = <String, ItemProgress>{};
        if (progressAsync.hasValue) {
          for (final unitProg in progressAsync.value!.units) {
            for (final ip in unitProg.itemsProgress) {
              progressMap[ip.curriculumItemId] = ip;
            }
          }
        }

        final isLetterUnit = unit.unitType == 'LETTER';

        // ── Option A : unité de type LETTER ─────────────────────────────
        // Une seule carte cliquable par lettre → LetterPageScreen
        if (isLetterUnit) {
          // Calculer le score (étoiles) depuis le premier item de la lettre
          final firstItem = unit.items.isNotEmpty ? unit.items.first : null;
          final prog = firstItem != null ? progressMap[firstItem.id] : null;
          final existingStars = prog?.masteryLevel ?? 0;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.titleFr ?? unit.titleAr,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    unit.titleAr,
                    style: TextStyle(
                        fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                        fontSize: 14,
                        color: Colors.white70),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            body: Center(
              child: _LetterEntryCard(
                unit: unit,
                stars: existingStars,
                onTap: () => _openLetterPage(context, unit, existingStars),
              ),
            ),
          );
        }

        // ── Unités non-lettre (règles, vocab, grammaire, Hifz…) ──────────
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.titleFr ?? unit.titleAr,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  unit.titleAr,
                  style: TextStyle(
                      fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      fontSize: 14,
                      color: Colors.white70),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            actions: [
              if (unit.audioUrl != null)
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.stop_circle : Icons.volume_up,
                    color: _isPlaying ? Colors.amber : Colors.white,
                  ),
                  onPressed: () => _playAudio(unit.audioUrl!),
                  tooltip: _isPlaying ? 'Arrêter' : 'Écouter',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description
                if (unit.descriptionFr != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      unit.descriptionFr!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),

                // Items list
                ...unit.items.map((item) {
                  final prog = progressMap[item.id];
                  final isCompleted = prog?.isCompleted ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ItemTile(
                      item: item,
                      isCompleted: isCompleted,
                      masteryLevel: prog?.masteryLevel,
                      teacherValidated: prog?.teacherValidated ?? false,
                      onTap: () => context.push(
                          '/student/curriculum/${widget.enrollmentId}/item/${item.id}'),
                      onQuiz: null,
                    ),
                  );
                }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Carte d'entrée lettre (Option A) ─────────────────────────────────────────

class _LetterEntryCard extends StatelessWidget {
  final CurriculumUnit unit;
  final int stars; // 0-3
  final VoidCallback onTap;

  const _LetterEntryCard({
    required this.unit,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = unit.titleAr;
    final letterName = glyphToName[glyph] ?? unit.titleFr ?? glyph;
    final passed = stars > 0;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Hero glyph ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.10),
                  AppColors.primary.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  letterName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (stars > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: i < stars ? Colors.amber : Colors.grey[300],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Bouton principal ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: passed ? AppColors.accent : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onTap,
              icon: Icon(
                passed ? Icons.star_outlined : Icons.school_outlined,
                color: Colors.white,
              ),
              label: Text(
                passed ? 'Améliorer mon score' : 'Apprendre cette lettre',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (passed) ...[
            const SizedBox(height: 10),
            Text(
              'Lettre validée ✅ — Vise ${stars < 3 ? "${stars + 1} étoile${stars + 1 > 1 ? 's' : ''}" : "la perfection !"}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Item tile (unités non-lettre : règles, vocab, grammaire…) ────────────────

class _ItemTile extends StatelessWidget {
  final CurriculumItem item;
  final bool isCompleted;
  final int? masteryLevel;
  final bool teacherValidated;
  final VoidCallback onTap;
  final VoidCallback? onQuiz; // conservé pour compatibilité, inutilisé pour les lettres

  const _ItemTile({
    required this.item,
    required this.isCompleted,
    required this.masteryLevel,
    required this.teacherValidated,
    required this.onTap,
    this.onQuiz,
  });

  Color get _statusColor {
    if (!isCompleted) return Colors.grey[300]!;
    if (masteryLevel == 3) return AppColors.success;
    if (masteryLevel == 2) return AppColors.accent;
    return AppColors.primary.withOpacity(0.5);
  }

  IconData get _typeIcon {
    switch (item.itemType) {
      case ItemType.letterForm:
        return Icons.translate;
      case ItemType.vocabulary:
        return Icons.menu_book;
      case ItemType.grammarPoint:
        return Icons.rule;
      case ItemType.rule:
        return Icons.lightbulb_outline;
      case ItemType.example:
        return Icons.format_quote;
      case ItemType.surahSegment:
        return Icons.auto_stories;
      case ItemType.combination:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Completion circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _statusColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: _statusColor, size: 20)
                      : Icon(_typeIcon, color: Colors.grey[400], size: 18),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic title (RTL)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.titleAr,
                        style: TextStyle(
                          fontFamily:
                              GoogleFonts.scheherazadeNew().fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.titleFr != null)
                      Text(
                        item.titleFr!,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (item.transliteration != null)
                      Text(
                        '[${item.transliteration}]',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),

              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (teacherValidated)
                    const Icon(Icons.verified,
                        color: AppColors.success, size: 18),
                  if (masteryLevel != null) ...[
                    const SizedBox(height: 4),
                    _MasteryDots(level: masteryLevel!),
                  ],
                  // onQuiz supprimé — les lettres utilisent LetterPageScreen
                  if (false && onQuiz != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onQuiz,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.quiz,
                            size: 16, color: AppColors.accent),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasteryDots extends StatelessWidget {
  final int level;
  const _MasteryDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < level ? AppColors.success : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

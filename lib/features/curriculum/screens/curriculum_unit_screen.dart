import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';
import '../widgets/letter_forms_preview.dart';
import '../widgets/letter_family_chip.dart';
import '../widgets/letter_pronunciation_card.dart';
import '../widgets/letter_quiz_widget.dart';

/// Screen listing all items in a unit with completion badges.
/// For Alphabet units: shows letter overview (description, audio, 4 forms preview,
/// family chip) before the items list.
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

  void _showQuiz(
      BuildContext context, QuizMode mode, List<CurriculumItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LetterQuizWidget(
        mode: mode,
        items: items,
        onComplete: () {},
      ),
    );
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

        final isAlphabetLetter = unit.unitType == 'LETTER';
        final letterItems = isAlphabetLetter
            ? unit.items
                .where((i) => i.letterPosition != null)
                .toList()
            : <CurriculumItem>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.titleFr ?? unit.titleAr,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  unit.titleAr,
                  style: TextStyle(
                      fontFamily:
                          GoogleFonts.scheherazadeNew().fontFamily,
                      fontSize: 14,
                      color: Colors.white70),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            actions: [
              // Audio play button in app bar
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
                // ── Letter overview (Alphabet only) ──────────────
                if (isAlphabetLetter) ...[
                  // Big letter + audio button
                  _LetterHeroCard(
                    glyph: unit.titleAr,
                    audioUrl: unit.audioUrl,
                    isPlaying: _isPlaying,
                    onPlay: unit.audioUrl != null
                        ? () => _playAudio(unit.audioUrl!)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (unit.descriptionFr != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              unit.descriptionFr!,
                              style: TextStyle(
                                  fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pronunciation guide
                  LetterPronunciationCard(glyph: unit.titleAr),

                  // 4 forms preview
                  if (letterItems.length == 4)
                    LetterFormsPreview(items: letterItems),

                  // Letter family
                  LetterFamilyChip(currentGlyph: unit.titleAr),
                ],

                // ── Non-alphabet description card ─────────────────
                if (!isAlphabetLetter && unit.descriptionFr != null)
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
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),

                // ── Section title ─────────────────────────────────
                if (isAlphabetLetter) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Apprendre chaque position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],

                // ── Items list ────────────────────────────────────
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
                      onQuiz: isCompleted && isAlphabetLetter
                          ? () => _showQuiz(
                              context, QuizMode.position, [item])
                          : null,
                    ),
                  );
                }),

                // ── Letter quiz (all positions completed) ─────────
                if (isAlphabetLetter &&
                    letterItems.isNotEmpty &&
                    letterItems.every(
                        (i) => progressMap[i.id]?.isCompleted ?? false)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          _showQuiz(context, QuizMode.letter, letterItems),
                      icon: const Icon(Icons.quiz, color: Colors.white),
                      label: Text(
                        'Quiz de la lettre',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Letter hero card with big glyph + audio ─────────────────────────────────

class _LetterHeroCard extends StatelessWidget {
  final String glyph;
  final String? audioUrl;
  final bool isPlaying;
  final VoidCallback? onPlay;

  const _LetterHeroCard({
    required this.glyph,
    this.audioUrl,
    required this.isPlaying,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Big glyph
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              glyph,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Audio button
          if (onPlay != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPlaying ? AppColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
              ),
              onPressed: onPlay,
              icon: Icon(isPlaying ? Icons.stop : Icons.volume_up, size: 20),
              label: Text(
                isPlaying ? 'Arrêter' : 'Écouter la prononciation',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item tile (reused from before) ──────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final CurriculumItem item;
  final bool isCompleted;
  final int? masteryLevel;
  final bool teacherValidated;
  final VoidCallback onTap;
  final VoidCallback? onQuiz;

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
                  if (onQuiz != null) ...[
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

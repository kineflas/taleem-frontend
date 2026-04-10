import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';

/// Displays pronunciation tips for a given Arabic letter.
/// Shows: difficulty badge, equivalent sound, description, tips, common mistakes.
class LetterPronunciationCard extends StatelessWidget {
  final String glyph; // isolated form

  const LetterPronunciationCard({super.key, required this.glyph});

  @override
  Widget build(BuildContext context) {
    final pron = letterPronunciations[glyph];
    if (pron == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with category + difficulty ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _difficultyColor(pron.difficulty).withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.record_voice_over,
                    size: 18, color: _difficultyColor(pron.difficulty)),
                const SizedBox(width: 8),
                Text(
                  'Prononciation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _difficultyColor(pron.difficulty),
                  ),
                ),
                const Spacer(),
                _DifficultyBadge(difficulty: pron.difficulty),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category + equivalent ────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        pron.categoryFr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (pron.equivalentLanguage != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pron.equivalentLanguage!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Equivalent sound ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.hearing, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pron.equivalentFr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Description ──────────────────────────────────
                Text(
                  pron.descriptionFr,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),

                // ── Astuce ───────────────────────────────────────
                if (pron.astuceFr != null) ...[
                  const SizedBox(height: 12),
                  _TipBox(
                    icon: Icons.tips_and_updates,
                    color: AppColors.accent,
                    label: 'Astuce',
                    text: pron.astuceFr!,
                  ),
                ],

                // ── Erreur fréquente ─────────────────────────────
                if (pron.erreurFr != null) ...[
                  const SizedBox(height: 10),
                  _TipBox(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange[700]!,
                    label: 'Attention',
                    text: pron.erreurFr!,
                  ),
                ],

                // ── Paire minimale ───────────────────────────────
                if (pron.paireFr != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.blueGrey.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows,
                            size: 16, color: Colors.blueGrey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey[700],
                                fontFamily:
                                    GoogleFonts.scheherazadeNew().fontFamily,
                              ),
                              children: _buildPairText(pron.paireFr!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildPairText(String pairText) {
    // Simple: render the whole text with mixed font
    // Arabic chars use Scheherazade, Latin chars use default
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool inArabic = false;

    for (final char in pairText.runes) {
      final c = String.fromCharCode(char);
      final isAr = char >= 0x0600 && char <= 0x06FF;

      if (isAr != inArabic && buffer.isNotEmpty) {
        spans.add(TextSpan(
          text: buffer.toString(),
          style: inArabic
              ? TextStyle(
                  fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )
              : null,
        ));
        buffer.clear();
      }
      inArabic = isAr;
      buffer.write(c);
    }
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(
        text: buffer.toString(),
        style: inArabic
            ? TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              )
            : null,
      ));
    }
    return spans;
  }

  Color _difficultyColor(PronunciationDifficulty d) {
    switch (d) {
      case PronunciationDifficulty.easy:
        return AppColors.success;
      case PronunciationDifficulty.medium:
        return AppColors.accent;
      case PronunciationDifficulty.hard:
        return Colors.orange[700]!;
      case PronunciationDifficulty.expert:
        return AppColors.danger;
    }
  }
}

class _DifficultyBadge extends StatelessWidget {
  final PronunciationDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  String get _label {
    switch (difficulty) {
      case PronunciationDifficulty.easy:
        return 'Facile';
      case PronunciationDifficulty.medium:
        return 'Moyen';
      case PronunciationDifficulty.hard:
        return 'Difficile';
      case PronunciationDifficulty.expert:
        return 'Avancé';
    }
  }

  Color get _color {
    switch (difficulty) {
      case PronunciationDifficulty.easy:
        return AppColors.success;
      case PronunciationDifficulty.medium:
        return AppColors.accent;
      case PronunciationDifficulty.hard:
        return Colors.orange[700]!;
      case PronunciationDifficulty.expert:
        return AppColors.danger;
    }
  }

  int get _dots {
    switch (difficulty) {
      case PronunciationDifficulty.easy:
        return 1;
      case PronunciationDifficulty.medium:
        return 2;
      case PronunciationDifficulty.hard:
        return 3;
      case PronunciationDifficulty.expert:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            _dots,
            (_) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color,
              ),
            ),
          ),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;

  const _TipBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

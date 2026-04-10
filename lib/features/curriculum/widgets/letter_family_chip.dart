import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';

/// Shows the letter family (similar-looking letters that differ by dots).
/// Highlights the current letter in the group.
class LetterFamilyChip extends StatelessWidget {
  final String currentGlyph; // isolated form of the current letter

  const LetterFamilyChip({super.key, required this.currentGlyph});

  @override
  Widget build(BuildContext context) {
    final familyIdx = glyphToFamilyIndex[currentGlyph];
    if (familyIdx == null) return const SizedBox.shrink();

    final family = letterFamilies[familyIdx];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: family.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: family.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_work, size: 16, color: family.color),
              const SizedBox(width: 8),
              Text(
                'Famille de lettres',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: family.color,
                ),
              ),
              const Spacer(),
              Text(
                family.descriptionFr,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: family.letters.map((glyph) {
              final isCurrent = glyph == currentGlyph;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? family.color.withOpacity(0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? family.color : Colors.grey[300]!,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    glyph,
                    style: TextStyle(
                      fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      fontSize: 28,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? family.color : AppColors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

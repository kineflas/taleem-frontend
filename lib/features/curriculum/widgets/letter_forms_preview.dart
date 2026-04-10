import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';

/// Shows the 4 positional forms of a letter side by side.
/// Used on CurriculumUnitScreen before the items list.
class LetterFormsPreview extends StatelessWidget {
  final List<CurriculumItem> items;

  const LetterFormsPreview({super.key, required this.items});

  static const _positionOrder = ['isolated', 'initial', 'medial', 'final'];
  static const _positionLabels = {
    'isolated': 'Isolée',
    'initial': 'Initiale',
    'medial': 'Médiane',
    'final': 'Finale',
  };

  @override
  Widget build(BuildContext context) {
    // Sort items in canonical position order
    final sorted = List<CurriculumItem>.from(items)
      ..sort((a, b) {
        final ai = _positionOrder.indexOf(a.letterPosition ?? '');
        final bi = _positionOrder.indexOf(b.letterPosition ?? '');
        return ai.compareTo(bi);
      });

    // Check if all forms are identical (e.g. Alif)
    final allSame =
        sorted.map((e) => e.titleAr).toSet().length == 1 && sorted.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.view_column, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Les 4 formes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 glyphs row
          Row(
            children: sorted.map((item) {
              final label =
                  _positionLabels[item.letterPosition] ?? item.letterPosition ?? '';
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            item.titleAr,
                            style: TextStyle(
                              fontFamily:
                                  GoogleFonts.scheherazadeNew().fontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Note for identical forms
          if (allSame) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette lettre garde la même forme dans toutes les positions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Non-connecting note
          if (sorted.isNotEmpty &&
              nonConnectingLetters.contains(sorted.first.titleAr)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lettre non-connectante : elle ne se lie pas à la lettre suivante.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

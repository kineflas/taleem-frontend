import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../providers/curriculum_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LetterMasteryMapScreen — Vue globale des 28 lettres colorées par niveau
//
// Affiche les 28 lettres organisées par groupe, colorées par étoiles :
//   gris   = pas encore commencé
//   rouge  = vu (⭐)
//   orange = pratiqué (⭐⭐)
//   vert   = maîtrisé (⭐⭐⭐)
// ─────────────────────────────────────────────────────────────────────────────

class LetterMasteryMapScreen extends ConsumerWidget {
  final String enrollmentId;

  const LetterMasteryMapScreen({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(enrollmentProgressProvider(enrollmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Carte de maîtrise', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (progress) {
          // Build map: glyph → stars (masteryLevel)
          // Map each UnitProgress to its glyph's mastery level
          final masteryMap = <String, int>{};
          for (final unitProg in progress.units) {
            // For LETTER units, the titleAr is the glyph itself
            // Use the first item's masteryLevel as the letter's mastery
            if (unitProg.itemsProgress.isNotEmpty) {
              final firstItem = unitProg.itemsProgress.first;
              // The unit's titleAr should be the glyph
              if (unitProg.unit.titleAr.isNotEmpty) {
                masteryMap[unitProg.unit.titleAr] = firstItem.masteryLevel ?? 0;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend
                _buildLegend(),
                const SizedBox(height: 20),

                // Groups
                ...List.generate(letterGroups.length, (groupIdx) {
                  final group = letterGroups[groupIdx];
                  final groupName = letterGroupNames[groupIdx];
                  final stars = group.map((g) => masteryMap[g] ?? 0).toList();
                  final mastered = stars.where((s) => s >= 1).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
                        child: Row(
                          children: [
                            Text(
                              'Groupe ${groupIdx + 1} — $groupName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$mastered/${group.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: mastered == group.length
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: group.map((glyph) {
                          final s = masteryMap[glyph] ?? 0;
                          return Expanded(
                            child: _LetterTile(
                              glyph: glyph,
                              stars: s,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    const items = [
      ('Pas commencé', Colors.grey, 0),
      ('Vu ⭐', Color(0xFFFF6B35), 1),
      ('Pratiqué ⭐⭐', Color(0xFFFF9800), 2),
      ('Maîtrisé ⭐⭐⭐', Color(0xFF4CAF50), 3),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items.map(((String label, Color color, int s) item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(item.$1, style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String glyph;
  final int stars;

  const _LetterTile({required this.glyph, required this.stars});

  Color get _color {
    switch (stars) {
      case 0: return Colors.grey.shade200;
      case 1: return const Color(0xFFFF6B35).withOpacity(0.15);
      case 2: return const Color(0xFFFF9800).withOpacity(0.15);
      case 3: return const Color(0xFF4CAF50).withOpacity(0.15);
      default: return Colors.grey.shade200;
    }
  }

  Color get _borderColor {
    switch (stars) {
      case 0: return Colors.grey.shade300;
      case 1: return const Color(0xFFFF6B35);
      case 2: return const Color(0xFFFF9800);
      case 3: return const Color(0xFF4CAF50);
      default: return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: stars > 0 ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: TextStyle(
              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: stars > 0 ? AppColors.primary : Colors.grey.shade500,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          Text(
            glyphToName[glyph] ?? glyph,
            style: TextStyle(
              fontSize: 9,
              color: stars > 0 ? AppColors.textSecondary : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (stars > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                size: 8,
                color: i < stars ? _borderColor : Colors.grey.shade300,
              )),
            ),
          ],
        ],
      ),
    );
  }
}

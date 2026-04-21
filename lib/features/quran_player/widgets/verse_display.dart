import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../models/player_models.dart';

/// Affiche les versets arabes avec highlight du verset actif.
///
/// - Verset en cours : fond doré + grande taille
/// - Versets passés : vert émeraude discret
/// - Versets à venir : gris clair
class VerseDisplay extends StatelessWidget {
  const VerseDisplay({
    super.key,
    required this.verses,
    required this.currentVerse,
    required this.startVerse,
    this.showTranslation = false,
    this.translations,
    this.scrollController,
  });

  final Map<int, String> verses;
  final int currentVerse;
  final int startVerse;
  final bool showTranslation;
  final Map<int, String>? translations;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final sortedKeys = verses.keys.toList()..sort();
    // Filter to only show verses in the current playlist range
    final visibleKeys = sortedKeys.where((k) => k >= startVerse).toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: visibleKeys.length,
      itemBuilder: (context, index) {
        final verseNum = visibleKeys[index];
        final text = verses[verseNum] ?? '';
        final isActive = verseNum == currentVerse;
        final isPast = verseNum < currentVerse;

        return _VerseCard(
          verseNumber: verseNum,
          text: text,
          translation: showTranslation ? (translations?[verseNum]) : null,
          isActive: isActive,
          isPast: isPast,
        );
      },
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verseNumber,
    required this.text,
    this.translation,
    required this.isActive,
    required this.isPast,
  });

  final int verseNumber;
  final String text;
  final String? translation;
  final bool isActive;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? HifzColors.goldMuted
        : isPast
            ? HifzColors.emeraldMuted
            : Colors.transparent;

    final textColor = isActive
        ? HifzColors.textDark
        : isPast
            ? HifzColors.emeraldDark
            : HifzColors.textLight;

    final borderColor = isActive ? HifzColors.gold : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Numéro de verset
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? HifzColors.gold : HifzColors.ivoryDark,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$verseNumber',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : HifzColors.textMedium,
                  ),
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: HifzColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EN COURS',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Texte arabe
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              style: GoogleFonts.amiri(
                fontSize: isActive ? 26 : 22,
                height: 2.0,
                color: textColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Traduction (optionnel)
          if (translation != null) ...[
            const SizedBox(height: 8),
            Divider(color: HifzColors.ivoryDark, height: 1),
            const SizedBox(height: 8),
            Text(
              translation!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.5,
                color: HifzColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

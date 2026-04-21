import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../models/player_models.dart';

/// Sélecteur de récitateur sous forme de cartes horizontales.
class ReciterSelector extends StatelessWidget {
  const ReciterSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ReciterChoice selected;
  final ValueChanged<ReciterChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ReciterChoice.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final reciter = ReciterChoice.values[index];
          final isSelected = reciter == selected;

          return GestureDetector(
            onTap: () => onChanged(reciter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? HifzColors.emeraldMuted : HifzColors.ivory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? HifzColors.emerald : HifzColors.ivoryDark,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reciter.nameAr,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: isSelected
                          ? HifzColors.emeraldDark
                          : HifzColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reciter.description,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: HifzColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

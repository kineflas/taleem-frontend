import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette sacrée — ivoire, émeraude, or.
/// Chaque couleur est choisie pour évoquer un mushaf ouvert
/// sur un lutriin en bois, éclairé par la lumière du matin.
class HifzColors {
  HifzColors._();

  // ── Fond & surfaces ──
  static const Color ivory = Color(0xFFFAF8F3);        // Fond principal — parchemin
  static const Color ivoryWarm = Color(0xFFF5F0E6);     // Surface card
  static const Color ivoryDark = Color(0xFFEDE8DB);      // Séparateurs subtils

  // ── Émeraude — couleur d'action ──
  static const Color emerald = Color(0xFF1B6B50);        // Primaire
  static const Color emeraldLight = Color(0xFF2A8C6A);   // Hover / actif
  static const Color emeraldDark = Color(0xFF0F4D38);    // Texte fort
  static const Color emeraldMuted = Color(0x1A1B6B50);   // Fond subtil

  // ── Or — accent & récompense ──
  static const Color gold = Color(0xFFBFA04A);           // Accent principal
  static const Color goldLight = Color(0xFFD4B85C);      // Étoiles actives
  static const Color goldMuted = Color(0x33BFA04A);      // Fond doré subtil

  // ── Texte ──
  static const Color textDark = Color(0xFF2C2417);       // Texte principal
  static const Color textMedium = Color(0xFF6B5D4F);     // Texte secondaire
  static const Color textLight = Color(0xFFA39888);      // Indice / inactif

  // ── Statuts ──
  static const Color correct = Color(0xFF2E7D5E);       // Réussite — vert émeraude
  static const Color close = Color(0xFFD4A24C);          // Proche — or chaud
  static const Color wrong = Color(0xFFC45A4A);          // Erreur — terre cuite
  static const Color missing = Color(0xFFA39888);        // Oublié — sable

  // ── 7 paliers SRS ──
  static const Color srsNew = Color(0xFFC45A4A);         // Palier 1 — Rouge foncé
  static const Color srsFragile = Color(0xFFD46B5A);     // Palier 2 — Rouge
  static const Color srsEnCours = Color(0xFFD4A24C);     // Palier 3 — Orange
  static const Color srsAcquis = Color(0xFFBFA04A);      // Palier 4 — Jaune doré
  static const Color srsSolide = Color(0xFF5AAE7E);      // Palier 5 — Vert clair
  static const Color srsMaitrise = Color(0xFF2E7D5E);    // Palier 6 — Vert
  static const Color srsAncre = Color(0xFFBFA04A);       // Palier 7 — Doré

  // ── Karaoke ──
  static const Color karaokeActive = Color(0xFFBFA04A);  // Mot actuel — or
  static const Color karaokePast = Color(0xFF2E7D5E);    // Mot passé — émeraude
  static const Color karaokePending = Color(0xFFA39888);  // Mot à venir — sable
}

/// Styles typographiques du Wird.
class HifzTypo {
  HifzTypo._();

  /// Verset coranique — grande taille, Amiri.
  static TextStyle verse({double size = 28, Color? color}) => GoogleFonts.amiri(
        fontSize: size,
        height: 2.0,
        color: color ?? HifzColors.textDark,
        fontWeight: FontWeight.w400,
      );

  /// Traduction / contexte
  static TextStyle translation({double size = 15, Color? color}) =>
      GoogleFonts.nunito(
        fontSize: size,
        height: 1.6,
        color: color ?? HifzColors.textMedium,
        fontStyle: FontStyle.italic,
      );

  /// Label d'étape (NOUR, TIKRAR…)
  static TextStyle stepLabel({Color? color}) => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: color ?? HifzColors.gold,
      );

  /// Titre de section
  static TextStyle sectionTitle({Color? color}) => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? HifzColors.textDark,
      );

  /// Corps de texte
  static TextStyle body({Color? color}) => GoogleFonts.nunito(
        fontSize: 14,
        height: 1.5,
        color: color ?? HifzColors.textMedium,
      );

  /// Score / chiffre grand
  static TextStyle score({Color? color}) => GoogleFonts.nunito(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: color ?? HifzColors.gold,
      );
}

/// Décorations partagées — nobles et épurées.
class HifzDecor {
  HifzDecor._();

  /// Card principale du Wird.
  static BoxDecoration card = BoxDecoration(
    color: HifzColors.ivoryWarm,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: HifzColors.ivoryDark, width: 1),
  );

  /// Séparateur fin doré.
  static BoxDecoration goldDivider = BoxDecoration(
    border: Border(
      bottom: BorderSide(color: HifzColors.gold.withOpacity(0.3), width: 0.5),
    ),
  );

  /// Bouton principal émeraude.
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: HifzColors.emerald,
    foregroundColor: HifzColors.ivory,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
  );

  /// Bouton secondaire bordure or.
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: HifzColors.gold,
    side: const BorderSide(color: HifzColors.gold, width: 1.5),
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

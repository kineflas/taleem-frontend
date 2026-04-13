import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MouthDiagramWidget — Schéma d'articulation (vue sagittale)
//
// Affiche une carte phonétique pré-générée (PNG 800×500) montrant la position
// de la langue et de la bouche pour chaque lettre arabe phonétiquement
// complexe. Pour les autres lettres, affiche un schéma de zone générique.
//
// Usage :
//   MouthDiagramWidget(glyph: 'ح')                 // carte dédiée
//   MouthDiagramWidget(zones: [ArticulationZone.palatal]) // zone générique
// ─────────────────────────────────────────────────────────────────────────────

/// Point d'articulation : où le son est produit dans la bouche/gorge
enum ArticulationZone {
  /// ب م و — lèvres
  lips,

  /// ف — lèvre inf. + dents sup.
  labiodental,

  /// ث ذ — langue entre les dents
  interdental,

  /// ت د ن ل ر — pointe de langue + derrière des dents
  alveolar,

  /// ش ج — milieu de langue + palais dur
  palatal,

  /// ك — arrière de langue + voile du palais
  velar,

  /// خ غ ق — arrière de langue + luette
  uvular,

  /// ح ع — gorge (pharynx)
  pharyngeal,

  /// ء ه — glotte (fond de la gorge)
  glottal,

  /// ص ض ط ظ — langue surélevée (emphatique)
  emphatic,
}

// ── Cartes phonétiques dédiées par glyphe ─────────────────────────────────
// 12 cartes Banana AI (coupe sagittale haute qualité) + 3 anciennes cartes
const Map<String, String> _glyphToCard = {
  // ── Banana AI (gemini/) ──
  'ث': 'assets/images/gemini/phon_tha.png',
  'ذ': 'assets/images/gemini/phon_dhal.png',
  'ر': 'assets/images/gemini/phon_ra.png',
  'خ': 'assets/images/gemini/phon_kha.png',
  'ح': 'assets/images/gemini/phon_hha.png',
  'ع': 'assets/images/gemini/phon_ayn.png',
  'ق': 'assets/images/gemini/phon_qaf.png',
  'ص': 'assets/images/gemini/phon_saad.png',
  'ض': 'assets/images/gemini/phon_daad.png',
  'ط': 'assets/images/gemini/phon_taa.png',
  'ظ': 'assets/images/gemini/phon_thaa.png',
  'ه': 'assets/images/gemini/phon_ha.png',
  // ── Anciennes cartes (articulation/) ──
  'ج': 'assets/images/articulation/phon_jim.png',
  'غ': 'assets/images/articulation/phon_ghayn.png',
  'ء': 'assets/images/articulation/phon_hamza.png',
};

/// Métadonnées d'affichage par zone (pour le fallback)
class _ZoneMeta {
  final String asset;
  final String labelFr;
  final Color color;

  const _ZoneMeta({
    required this.asset,
    required this.labelFr,
    required this.color,
  });
}

const Map<ArticulationZone, _ZoneMeta> _zoneMeta = {
  ArticulationZone.lips: _ZoneMeta(
    asset: 'assets/images/articulation/lips.png',
    labelFr: 'Lèvres',
    color: Color(0xFFE91E63),
  ),
  ArticulationZone.labiodental: _ZoneMeta(
    asset: 'assets/images/articulation/labiodental.png',
    labelFr: 'Lèvre + dents',
    color: Color(0xFFFF5722),
  ),
  ArticulationZone.interdental: _ZoneMeta(
    asset: 'assets/images/articulation/phon_tha.png',
    labelFr: 'Langue entre les dents',
    color: Color(0xFFFF9800),
  ),
  ArticulationZone.alveolar: _ZoneMeta(
    asset: 'assets/images/articulation/phon_ra.png',
    labelFr: 'Derrière des dents',
    color: Color(0xFFFFC107),
  ),
  ArticulationZone.palatal: _ZoneMeta(
    asset: 'assets/images/articulation/phon_jim.png',
    labelFr: 'Milieu du palais',
    color: Color(0xFF4CAF50),
  ),
  ArticulationZone.velar: _ZoneMeta(
    asset: 'assets/images/articulation/phon_kha.png',
    labelFr: 'Voile du palais',
    color: Color(0xFF00BCD4),
  ),
  ArticulationZone.uvular: _ZoneMeta(
    asset: 'assets/images/articulation/phon_qaf.png',
    labelFr: 'Luette',
    color: Color(0xFF3F51B5),
  ),
  ArticulationZone.pharyngeal: _ZoneMeta(
    asset: 'assets/images/articulation/phon_hha.png',
    labelFr: 'Fond de gorge',
    color: Color(0xFF9C27B0),
  ),
  ArticulationZone.glottal: _ZoneMeta(
    asset: 'assets/images/articulation/phon_hamza.png',
    labelFr: 'Glotte',
    color: Color(0xFF607D8B),
  ),
  ArticulationZone.emphatic: _ZoneMeta(
    asset: 'assets/images/articulation/emphatic.png',
    labelFr: 'Langue surélevée',
    color: Color(0xFF795548),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────

class MouthDiagramWidget extends StatelessWidget {
  /// Glyphe arabe de la lettre courante (ex. 'ح').
  /// Si une carte dédiée existe, elle sera affichée en priorité.
  final String? glyph;

  /// Zones à afficher (fallback quand pas de carte dédiée).
  final List<ArticulationZone> zones;

  /// Si true, affiche la légende en dessous (uniquement pour le mode zone).
  final bool showLegend;

  const MouthDiagramWidget({
    super.key,
    this.glyph,
    this.zones = const [],
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    // ── Priorité 1 : carte phonétique dédiée ────────────────────────────
    final cardAsset = glyph != null ? _glyphToCard[glyph!] : null;
    if (cardAsset != null) {
      return _PhoneticCard(asset: cardAsset);
    }

    // ── Priorité 2 : schéma générique par zone ──────────────────────────
    if (zones.isEmpty) return const SizedBox.shrink();

    final primary = zones.first;
    final meta = _zoneMeta[primary];
    if (meta == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            meta.asset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackDiagram(),
          ),
        ),

        // Zones supplémentaires (badges)
        if (zones.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aussi : ',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              ...zones.skip(1).map((z) {
                final m = _zoneMeta[z];
                if (m == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _ZoneBadge(label: m.labelFr, color: m.color),
                );
              }),
            ],
          ),
        ],

        // Légende zone principale
        if (showLegend) ...[
          const SizedBox(height: 6),
          _ZoneBadge(label: meta.labelFr, color: meta.color, large: true),
        ],
      ],
    );
  }
}

// ── Carte phonétique complète (800×500) ───────────────────────────────────────

class _PhoneticCard extends StatelessWidget {
  final String asset;
  const _PhoneticCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _FallbackDiagram(),
      ),
    );
  }
}

// ── Badge de zone ─────────────────────────────────────────────────────────────

class _ZoneBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool large;
  const _ZoneBadge({required this.label, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 9 : 7,
            height: large ? 9 : 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 11 : 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback ──────────────────────────────────────────────────────────────────

class _FallbackDiagram extends StatelessWidget {
  const _FallbackDiagram();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text('Schéma non disponible',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mapping glyph → zones d'articulation
// ─────────────────────────────────────────────────────────────────────────────

/// Retourne les zones d'articulation associées à un glyphe.
List<ArticulationZone> zonesForGlyph(String glyph) {
  return _glyphZones[glyph] ?? [];
}

/// Retourne true si une carte phonétique dédiée existe pour ce glyphe.
bool hasPhoneticCard(String glyph) => _glyphToCard.containsKey(glyph);

const Map<String, List<ArticulationZone>> _glyphZones = {
  'ب': [ArticulationZone.lips],
  'م': [ArticulationZone.lips],
  'و': [ArticulationZone.lips],
  'ف': [ArticulationZone.labiodental],
  'ث': [ArticulationZone.interdental],
  'ذ': [ArticulationZone.interdental],
  'ت': [ArticulationZone.alveolar],
  'د': [ArticulationZone.alveolar],
  'ن': [ArticulationZone.alveolar],
  'ل': [ArticulationZone.alveolar],
  'ر': [ArticulationZone.alveolar],
  'س': [ArticulationZone.alveolar],
  'ز': [ArticulationZone.alveolar],
  'ش': [ArticulationZone.palatal],
  'ج': [ArticulationZone.palatal],
  'ك': [ArticulationZone.velar],
  'خ': [ArticulationZone.velar],
  'غ': [ArticulationZone.velar],
  'ق': [ArticulationZone.uvular],
  'ح': [ArticulationZone.pharyngeal],
  'ع': [ArticulationZone.pharyngeal],
  'ء': [ArticulationZone.glottal],
  'ه': [ArticulationZone.glottal],
  'ص': [ArticulationZone.emphatic, ArticulationZone.alveolar],
  'ض': [ArticulationZone.emphatic, ArticulationZone.alveolar],
  'ط': [ArticulationZone.emphatic, ArticulationZone.alveolar],
  'ظ': [ArticulationZone.emphatic, ArticulationZone.interdental],
  'ا': [],
  'ي': [ArticulationZone.palatal],
};

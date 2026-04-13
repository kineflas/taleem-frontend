import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MouthDiagramWidget — Schéma d'articulation (vue sagittale)
//
// Affiche une image PNG pré-générée montrant la position de la langue et de
// la bouche pour chaque zone d'articulation des lettres arabes.
//
// Usage :
//   MouthDiagramWidget(zones: [ArticulationZone.pharyngeal])
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

/// Métadonnées d'affichage par zone
class _ZoneMeta {
  final String asset;   // chemin relatif assets/
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
    asset: 'assets/images/articulation/interdental.png',
    labelFr: 'Langue entre les dents',
    color: Color(0xFFFF9800),
  ),
  ArticulationZone.alveolar: _ZoneMeta(
    asset: 'assets/images/articulation/alveolar.png',
    labelFr: 'Derrière des dents',
    color: Color(0xFFFFC107),
  ),
  ArticulationZone.palatal: _ZoneMeta(
    asset: 'assets/images/articulation/palatal.png',
    labelFr: 'Milieu du palais',
    color: Color(0xFF4CAF50),
  ),
  ArticulationZone.velar: _ZoneMeta(
    asset: 'assets/images/articulation/velar.png',
    labelFr: 'Voile du palais',
    color: Color(0xFF00BCD4),
  ),
  ArticulationZone.uvular: _ZoneMeta(
    asset: 'assets/images/articulation/uvular.png',
    labelFr: 'Luette',
    color: Color(0xFF3F51B5),
  ),
  ArticulationZone.pharyngeal: _ZoneMeta(
    asset: 'assets/images/articulation/pharyngeal.png',
    labelFr: 'Fond de gorge',
    color: Color(0xFF9C27B0),
  ),
  ArticulationZone.glottal: _ZoneMeta(
    asset: 'assets/images/articulation/glottal.png',
    labelFr: 'Glotte',
    color: Color(0xFF607D8B),
  ),
  ArticulationZone.emphatic: _ZoneMeta(
    asset: 'assets/images/articulation/emphatic.png',
    labelFr: 'Langue surélevée',
    color: Color(0xFF795548),
  ),
};

class MouthDiagramWidget extends StatelessWidget {
  /// Zones à afficher. Si plusieurs zones sont actives, une carte par zone.
  final List<ArticulationZone> zones;

  /// Si true, affiche la légende en dessous.
  final bool showLegend;

  const MouthDiagramWidget({
    super.key,
    required this.zones,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();

    // Si plusieurs zones (ex. ظ = emphatic + interdental), afficher en tabs
    // ou empiler verticalement. On affiche la première zone + badge pour les autres.
    final primary = zones.first;
    final meta = _zoneMeta[primary]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Diagramme principal ────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            meta.asset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackDiagram(),
          ),
        ),

        // ── Zones supplémentaires (badges) ────────────────────────────────
        if (zones.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aussi : ', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ...zones.skip(1).map((z) {
                final m = _zoneMeta[z]!;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: m.color.withOpacity(0.5)),
                    ),
                    child: Text(
                      m.labelFr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: m.color,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],

        // ── Légende zone principale ────────────────────────────────────────
        if (showLegend) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: meta.color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  meta.labelFr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: meta.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Fallback si l'image ne charge pas (dev local sans assets)
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
// Mapping glyph → zones d'articulation (inchangé)
// ─────────────────────────────────────────────────────────────────────────────

List<ArticulationZone> zonesForGlyph(String glyph) {
  return _glyphZones[glyph] ?? [];
}

const Map<String, List<ArticulationZone>> _glyphZones = {
  'ب': [],
  'م': [],
  'و': [ArticulationZone.lips],
  'ف': [ArticulationZone.labiodental],
  'ث': [ArticulationZone.interdental],
  'ذ': [ArticulationZone.interdental],
  'ت': [],
  'د': [],
  'ن': [],
  'ل': [],
  'ر': [ArticulationZone.alveolar],
  'س': [],
  'ز': [],
  'ش': [],
  'ج': [ArticulationZone.palatal],
  'ك': [],
  'خ': [ArticulationZone.uvular],
  'غ': [ArticulationZone.uvular],
  'ق': [ArticulationZone.uvular],
  'ح': [ArticulationZone.pharyngeal],
  'ع': [ArticulationZone.pharyngeal],
  'ء': [ArticulationZone.glottal],
  'ه': [ArticulationZone.glottal],
  'ص': [ArticulationZone.emphatic],
  'ض': [ArticulationZone.emphatic],
  'ط': [ArticulationZone.emphatic],
  'ظ': [ArticulationZone.emphatic, ArticulationZone.interdental],
};

import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MouthDiagramWidget — Schéma interactif d'articulation
//
// Affiche une coupe sagittale (vue de côté) simplifiée de la bouche et de
// la gorge, avec une zone animée (pulse) indiquant l'endroit où le son est
// produit. Utilisé dans la fiche de prononciation des lettres arabes qui
// n'ont pas d'équivalent en français.
//
// Usage :
//   MouthDiagramWidget(zones: [ArticulationZone.pharynx])
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

/// Métadonnées d'affichage pour chaque zone
class _ZoneMeta {
  final String labelFr;
  final Color color;
  final Offset center; // 0..1 relatif à la taille du canvas
  final double radius; // 0..1 relatif à la largeur

  const _ZoneMeta({
    required this.labelFr,
    required this.color,
    required this.center,
    required this.radius,
  });
}

// Coordonnées relatives dans le canvas 1×1
// Le canvas représente une coupe de côté : bouche à gauche, gorge à droite/bas
const Map<ArticulationZone, _ZoneMeta> _zoneMeta = {
  ArticulationZone.lips: _ZoneMeta(
    labelFr: 'Lèvres',
    color: Color(0xFFE91E63),
    center: Offset(0.10, 0.42),
    radius: 0.055,
  ),
  ArticulationZone.labiodental: _ZoneMeta(
    labelFr: 'Lèvre + dents',
    color: Color(0xFFFF5722),
    center: Offset(0.17, 0.40),
    radius: 0.055,
  ),
  ArticulationZone.interdental: _ZoneMeta(
    labelFr: 'Langue entre les dents',
    color: Color(0xFFFF9800),
    center: Offset(0.23, 0.50),
    radius: 0.060,
  ),
  ArticulationZone.alveolar: _ZoneMeta(
    labelFr: 'Derrière des dents',
    color: Color(0xFFFFEB3B),
    center: Offset(0.30, 0.35),
    radius: 0.058,
  ),
  ArticulationZone.palatal: _ZoneMeta(
    labelFr: 'Milieu du palais',
    color: Color(0xFF4CAF50),
    center: Offset(0.45, 0.28),
    radius: 0.060,
  ),
  ArticulationZone.velar: _ZoneMeta(
    labelFr: 'Voile du palais',
    color: Color(0xFF00BCD4),
    center: Offset(0.60, 0.30),
    radius: 0.062,
  ),
  ArticulationZone.uvular: _ZoneMeta(
    labelFr: 'Luette',
    color: Color(0xFF3F51B5),
    center: Offset(0.68, 0.38),
    radius: 0.060,
  ),
  ArticulationZone.pharyngeal: _ZoneMeta(
    labelFr: 'Fond de gorge',
    color: Color(0xFF9C27B0),
    center: Offset(0.75, 0.60),
    radius: 0.065,
  ),
  ArticulationZone.glottal: _ZoneMeta(
    labelFr: 'Glotte',
    color: Color(0xFF607D8B),
    center: Offset(0.72, 0.80),
    radius: 0.055,
  ),
  ArticulationZone.emphatic: _ZoneMeta(
    labelFr: 'Langue surélevée',
    color: Color(0xFF795548),
    center: Offset(0.42, 0.48),
    radius: 0.072,
  ),
};

class MouthDiagramWidget extends StatefulWidget {
  /// Zones à mettre en évidence (peut en avoir plusieurs)
  final List<ArticulationZone> zones;

  /// Si true, affiche la légende des zones actives en bas
  final bool showLegend;

  const MouthDiagramWidget({
    super.key,
    required this.zones,
    this.showLegend = true,
  });

  @override
  State<MouthDiagramWidget> createState() => _MouthDiagramWidgetState();
}

class _MouthDiagramWidgetState extends State<MouthDiagramWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Diagramme ────────────────────────────────────────────────────
        AspectRatio(
          aspectRatio: 1.5,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => CustomPaint(
              painter: _MouthPainter(
                zones: widget.zones,
                pulseValue: _pulse.value,
              ),
            ),
          ),
        ),

        // ── Légende ───────────────────────────────────────────────────────
        if (widget.showLegend && widget.zones.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: widget.zones.map((z) {
              final meta = _zoneMeta[z]!;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: meta.color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: meta.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      meta.labelFr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: meta.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter : coupe sagittale simplifiée
// ─────────────────────────────────────────────────────────────────────────────

class _MouthPainter extends CustomPainter {
  final List<ArticulationZone> zones;
  final double pulseValue; // 0..1

  const _MouthPainter({required this.zones, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Fond ──────────────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = const Color(0xFFFAF8F5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      bgPaint,
    );

    // ── Dessin de la coupe sagittale ──────────────────────────────────────
    _drawCavity(canvas, w, h);
    _drawTongue(canvas, w, h);
    _drawTeeth(canvas, w, h);
    _drawLips(canvas, w, h);
    _drawUvula(canvas, w, h);

    // ── Zones actives (pulse) ─────────────────────────────────────────────
    for (final zone in zones) {
      final meta = _zoneMeta[zone];
      if (meta == null) continue;

      final cx = meta.center.dx * w;
      final cy = meta.center.dy * h;
      final r = meta.radius * w;

      // Halo externe animé
      final haloPaint = Paint()
        ..color = meta.color.withOpacity(0.15 + 0.20 * pulseValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(cx, cy),
        r * (1.4 + 0.4 * pulseValue),
        haloPaint,
      );

      // Cercle principal
      final zonePaint = Paint()
        ..color = meta.color.withOpacity(0.75 + 0.25 * pulseValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r, zonePaint);

      // Icône "son ici" — petite flèche
      _drawArrow(canvas, cx, cy, r, meta.color, size);
    }

    // ── Étiquettes des zones statiques (grisées) ─────────────────────────
    _drawZoneLabels(canvas, w, h);
  }

  // Cavité buccale + gorge
  void _drawCavity(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFFFD6C0)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Bouche (espace intérieur)
    path.moveTo(w * 0.08, h * 0.35);
    path.lineTo(w * 0.08, h * 0.55);
    // Sol de la bouche → gorge
    path.quadraticBezierTo(w * 0.45, h * 0.68, w * 0.70, h * 0.72);
    path.lineTo(w * 0.70, h * 0.95);
    path.lineTo(w * 0.88, h * 0.95);
    path.lineTo(w * 0.88, h * 0.35);
    // Plafond : palais dur → voile → pharynx
    path.quadraticBezierTo(w * 0.60, h * 0.22, w * 0.40, h * 0.22);
    path.quadraticBezierTo(w * 0.22, h * 0.22, w * 0.08, h * 0.35);
    path.close();
    canvas.drawPath(path, paint);

    // Contour
    final border = Paint()
      ..color = const Color(0xFFBE9080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, border);
  }

  // Langue
  void _drawTongue(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFFF8A80)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.10, h * 0.55);
    path.quadraticBezierTo(w * 0.25, h * 0.60, w * 0.45, h * 0.58);
    path.quadraticBezierTo(w * 0.62, h * 0.56, w * 0.68, h * 0.65);
    path.lineTo(w * 0.68, h * 0.72);
    path.quadraticBezierTo(w * 0.45, h * 0.70, w * 0.20, h * 0.68);
    path.lineTo(w * 0.10, h * 0.68);
    path.close();
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = const Color(0xFFD32F2F).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, border);
  }

  // Dents (supérieures + inférieures)
  void _drawTeeth(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dents supérieures
    for (int i = 0; i < 3; i++) {
      final x = w * (0.09 + i * 0.045);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h * 0.28, w * 0.038, h * 0.10),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, border);
    }

    // Dents inférieures
    for (int i = 0; i < 3; i++) {
      final x = w * (0.09 + i * 0.045);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h * 0.54, w * 0.038, h * 0.09),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, border);
    }
  }

  // Lèvres
  void _drawLips(Canvas canvas, double w, double h) {
    final upper = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final lower = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;

    // Lèvre supérieure
    final upperPath = Path();
    upperPath.moveTo(w * 0.04, h * 0.38);
    upperPath.quadraticBezierTo(w * 0.09, h * 0.28, w * 0.14, h * 0.36);
    upperPath.lineTo(w * 0.08, h * 0.38);
    upperPath.close();
    canvas.drawPath(upperPath, upper);

    // Lèvre inférieure
    final lowerPath = Path();
    lowerPath.moveTo(w * 0.04, h * 0.56);
    lowerPath.quadraticBezierTo(w * 0.09, h * 0.66, w * 0.14, h * 0.55);
    lowerPath.lineTo(w * 0.08, h * 0.54);
    lowerPath.close();
    canvas.drawPath(lowerPath, lower);
  }

  // Luette
  void _drawUvula(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFAD1457)
      ..style = PaintingStyle.fill;

    // Petit pendentif
    final path = Path();
    path.moveTo(w * 0.65, h * 0.30);
    path.lineTo(w * 0.68, h * 0.30);
    path.quadraticBezierTo(w * 0.70, h * 0.38, w * 0.665, h * 0.42);
    path.quadraticBezierTo(w * 0.645, h * 0.38, w * 0.65, h * 0.30);
    path.close();
    canvas.drawPath(path, paint);
  }

  // Petite flèche vers la zone active
  void _drawArrow(Canvas canvas, double cx, double cy, double r,
      Color color, Size size) {
    // Juste un petit indicateur blanc au centre de la zone
    final dot = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.35, dot);
  }

  // Étiquettes anatomiques discrètes
  void _drawZoneLabels(Canvas canvas, double w, double h) {
    final style = TextStyle(
      fontSize: w * 0.047,
      color: const Color(0xFF9E9E9E),
      fontWeight: FontWeight.w500,
    );

    final labels = <String, Offset>{
      'Lèvres': Offset(w * 0.02, h * 0.20),
      'Palais': Offset(w * 0.40, h * 0.12),
      'Luette': Offset(w * 0.62, h * 0.16),
      'Gorge': Offset(w * 0.76, h * 0.50),
      'Langue': Offset(w * 0.30, h * 0.76),
    };

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, entry.value);
    }
  }

  @override
  bool shouldRepaint(_MouthPainter old) =>
      old.pulseValue != pulseValue || old.zones != zones;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mappings pratiques : lettre isolée → zones d'articulation
// ─────────────────────────────────────────────────────────────────────────────

/// Retourne les zones d'articulation pour un glyph arabe donné.
/// Retourne [] pour les lettres avec un équivalent français évident.
List<ArticulationZone> zonesForGlyph(String glyph) {
  return _glyphZones[glyph] ?? [];
}

const Map<String, List<ArticulationZone>> _glyphZones = {
  // Labiales — équivalent français évident, pas de schéma nécessaire
  'ب': [], // B
  'م': [], // M
  'و': [ArticulationZone.lips], // W/OU

  // Labiodentale
  'ف': [ArticulationZone.labiodental], // F

  // Interdentales (TH) — pas d'équivalent français mais assez visuel
  'ث': [ArticulationZone.interdental], // TH sourd
  'ذ': [ArticulationZone.interdental], // TH sonore

  // Alvéolaires — proches du français
  'ت': [], // T
  'د': [], // D
  'ن': [], // N
  'ل': [], // L
  'ر': [ArticulationZone.alveolar], // R roulé
  'س': [], // S
  'ز': [], // Z

  // Palatales
  'ش': [], // CH — équivalent français
  'ج': [ArticulationZone.palatal], // DJ

  // Vélaire
  'ك': [], // K — équivalent français

  // Uvulaires — schéma important
  'خ': [ArticulationZone.uvular], // KH
  'غ': [ArticulationZone.uvular], // GH / R grasseyé
  'ق': [ArticulationZone.uvular], // Q profond

  // Pharyngales — les plus difficiles
  'ح': [ArticulationZone.pharyngeal], // H profond
  'ع': [ArticulationZone.pharyngeal], // Ayn

  // Glottales
  'ء': [ArticulationZone.glottal], // Hamza
  'ه': [ArticulationZone.glottal], // H léger

  // Emphatiques — schéma sur la langue surélevée
  'ص': [ArticulationZone.emphatic], // S emphatique
  'ض': [ArticulationZone.emphatic], // D emphatique
  'ط': [ArticulationZone.emphatic], // T emphatique
  'ظ': [ArticulationZone.emphatic, ArticulationZone.interdental], // DH emphatique
};

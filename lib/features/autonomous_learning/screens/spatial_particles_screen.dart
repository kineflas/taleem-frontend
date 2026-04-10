import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Spatial Particles interactive learning (Module 2).
/// Shows particles positioned in a scene. Phases: View → Drag & Drop → Verse Exercise
class SpatialParticlesScreen extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int phase;

  const SpatialParticlesScreen({
    super.key,
    required this.moduleNumber,
    required this.phase,
  });

  @override
  ConsumerState<SpatialParticlesScreen> createState() =>
      _SpatialParticlesScreenState();
}

class _SpatialParticlesScreenState extends ConsumerState<SpatialParticlesScreen> {
  // Spatial particles data
  final List<Map<String, dynamic>> _particles = [
    {
      'arabicWord': 'عَلَى',
      'meaning': 'Sur',
      'transliteration': 'ala',
      'position': 'top',
      'alignment': Alignment.topCenter,
    },
    {
      'arabicWord': 'تَحْتَ',
      'meaning': 'Sous',
      'transliteration': 'tahta',
      'position': 'bottom',
      'alignment': Alignment.bottomCenter,
    },
    {
      'arabicWord': 'فِي',
      'meaning': 'Dans',
      'transliteration': 'fi',
      'position': 'center',
      'alignment': Alignment.center,
    },
    {
      'arabicWord': 'أمَام',
      'meaning': 'Devant',
      'transliteration': 'amam',
      'position': 'front',
      'alignment': Alignment.centerRight,
    },
    {
      'arabicWord': 'خَلْف',
      'meaning': 'Derrière',
      'transliteration': 'khalf',
      'position': 'back',
      'alignment': Alignment.centerLeft,
    },
  ];

  late List<Map<String, dynamic>> _draggedParticles;
  int _draggedIndex = -1;

  @override
  void initState() {
    super.initState();
    _draggedParticles = List.from(_particles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Particules spatiales'),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: widget.phase / 3,
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhaseHeader(phase: widget.phase),
                  const SizedBox(height: 20),
                  if (widget.phase == 1)
                    _ViewPhase(particles: _particles)
                  else if (widget.phase == 2)
                    _DragDropPhase(
                      particles: _particles,
                      onDragStart: (index) =>
                          setState(() => _draggedIndex = index),
                    )
                  else
                    _VersePhase(particles: _particles),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final int phase;

  const _PhaseHeader({required this.phase});

  String get title {
    switch (phase) {
      case 1:
        return '👁️ Voir et mémoriser';
      case 2:
        return '✋ Glisser-déposer';
      case 3:
        return '🎯 Trouver dans le verset';
      default:
        return '';
    }
  }

  String get description {
    switch (phase) {
      case 1:
        return 'Observez comment les particules spatiales sont positionnées dans la scène.';
      case 2:
        return 'Glissez chaque particule à sa position correcte dans la scène.';
      case 3:
        return 'Identifiez les particules spatiales dans ce verset coranique.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ViewPhase extends StatelessWidget {
  final List<Map<String, dynamic>> particles;

  const _ViewPhase({required this.particles});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Stack(
        children: [
          // Scene background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🏠 La Scène',
                      style: TextStyle(
                        fontSize: 32,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Particles positioned
          ...particles.asMap().entries.map((entry) {
            final particle = entry.value;
            return Positioned.fill(
              child: Align(
                alignment: particle['alignment'] as Alignment,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _ParticleWidget(particle: particle),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _DragDropPhase extends StatefulWidget {
  final List<Map<String, dynamic>> particles;
  final ValueChanged<int> onDragStart;

  const _DragDropPhase({
    required this.particles,
    required this.onDragStart,
  });

  @override
  State<_DragDropPhase> createState() => _DragDropPhaseState();
}

class _DragDropPhaseState extends State<_DragDropPhase> {
  late Map<int, Offset> _particlePositions;

  @override
  void initState() {
    super.initState();
    _particlePositions = {};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Stack(
            children: [
              // Target scene
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🏠',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),

              // Draggable particles
              ...widget.particles.asMap().entries.map((entry) {
                final index = entry.key;
                final particle = entry.value;
                final position = _particlePositions[index] ??
                    Offset(20.0 + (index * 80).toDouble(), 20.0);

                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: Draggable(
                    data: index,
                    feedback: _ParticleWidget(particle: particle),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _ParticleWidget(particle: particle),
                    ),
                    onDragStarted: () => widget.onDragStart(index),
                    child: _ParticleWidget(particle: particle),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exercice de glisser-déposer en cours... 📍'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text(
            'Vérifier',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _VersePhase extends StatelessWidget {
  final List<Map<String, dynamic>> particles;

  const _VersePhase({required this.particles});

  @override
  Widget build(BuildContext context) {
    const verseText =
        'وَإِذَا دَخَلْتُم بُيُوتًا فَسَلِّمُوا عَلَىٰ أَنفُسِكُمْ تَحِيَّةً مِّنْ عِندِ اللَّهِ مُبَارَكَةً';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Text(
                  'Sourate An-Nur (24:61)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verseText,
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 24,
                    height: 2,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Particules trouvées dans ce verset:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ParticleBadge(particle: particles[0]),
                  _ParticleBadge(particle: particles[3]),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticleWidget extends StatelessWidget {
  final Map<String, dynamic> particle;

  const _ParticleWidget({required this.particle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            particle['arabicWord'],
            style: TextStyle(
              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            particle['meaning'],
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticleBadge extends StatelessWidget {
  final Map<String, dynamic> particle;

  const _ParticleBadge({required this.particle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              particle['arabicWord'],
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          Text(
            particle['meaning'],
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

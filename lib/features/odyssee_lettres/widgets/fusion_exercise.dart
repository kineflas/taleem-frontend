import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Laboratoire de Fusion: Drag letter + vowel → machine produces sound.
class FusionExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const FusionExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<FusionExercise> createState() => _FusionExerciseState();
}

class _FusionExerciseState extends State<FusionExercise> {
  int _currentItem = 0;
  bool _fused = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final isLast = _currentItem >= items.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.exercise.promptFr != null)
            Text(widget.exercise.promptFr!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fusion machine visual
                  if (!_fused) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Letter
                        _FusionSlot(
                          label: 'Lettre',
                          content: item['lettre'] ?? '',
                          color: const Color(0xFF2A9D8F),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.add_rounded,
                              color: Color(0xFF999999), size: 32),
                        ),
                        // Haraka
                        _FusionSlot(
                          label: item['haraka_nom'] ?? '',
                          content: item['haraka'] ?? '',
                          color: const Color(0xFFE76F51),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _fused = true),
                      icon: const Icon(Icons.merge_rounded, color: Colors.white),
                      label: const Text('Fusionner !',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3483),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    // Result
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2A9D8F), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          item['resultat'] ?? '',
                          style: const TextStyle(
                              fontSize: 64, fontFamily: 'Amiri'),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '= ${item['son'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded,
                          color: Color(0xFF2A9D8F), size: 36),
                      onPressed: () {
                        // TODO: play audio item['audio_id']
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_fused)
            ElevatedButton(
              onPressed: () {
                if (isLast) {
                  widget.onComplete(correct: true);
                } else {
                  setState(() {
                    _currentItem++;
                    _fused = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9D8F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isLast ? 'Terminé' : 'Suivant',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _FusionSlot extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _FusionSlot({
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              content,
              style: TextStyle(fontSize: 40, fontFamily: 'Amiri', color: color),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ],
    );
  }
}

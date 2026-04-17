import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';

/// Step 1: Écoute — Audio listening + anatomical zones + repeat prompts.
class OdysseeEcouteStep extends StatefulWidget {
  final OdysseeLessonContent lesson;
  final VoidCallback onComplete;

  const OdysseeEcouteStep({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<OdysseeEcouteStep> createState() => _OdysseeEcouteStepState();
}

class _OdysseeEcouteStepState extends State<OdysseeEcouteStep> {
  int _currentIndex = 0;
  bool _showAnatomie = false;

  EcouteData? get _ecoute => widget.lesson.ecoute;

  @override
  Widget build(BuildContext context) {
    final ecoute = _ecoute;
    if (ecoute == null) {
      // No écoute data — skip step
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
      return const SizedBox.shrink();
    }

    final sequence = ecoute.sequence;
    final isLast = _currentIndex >= sequence.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headphones_rounded,
                      color: Color(0xFF2A9D8F), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ecoute.instruction,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF264653)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current sound card
            if (sequence.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Big syllable display
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A9D8F).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          sequence[_currentIndex].label.split(' = ').first,
                          style: const TextStyle(
                            fontSize: 56,
                            fontFamily: 'Amiri',
                            color: Color(0xFF1A1A2E),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sequence[_currentIndex].label,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 8),
                    // Audio play button
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded,
                          color: Color(0xFF2A9D8F), size: 36),
                      onPressed: () {
                        // TODO: play audio for sequence[_currentIndex].audioId
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentIndex + 1} / ${sequence.length}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),

            // Anatomie toggle
            if (ecoute.anatomie.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _showAnatomie = !_showAnatomie),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_rounded,
                          color: Color(0xFFE76F51), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Conseils anatomiques',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      Icon(
                        _showAnatomie
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showAnatomie) ...[
                const SizedBox(height: 8),
                ...ecoute.anatomie.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                          Expanded(
                            child: Text(
                              '${a.description} (${a.zone})',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
            const SizedBox(height: 16),

            // Next / Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    widget.onComplete();
                  } else {
                    setState(() => _currentIndex++);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLast ? 'Continuer' : 'Son suivant',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

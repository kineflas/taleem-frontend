import 'package:flutter/material.dart';
import '../../models/lesson_models_v2.dart';

/// Step 3: Interactive dialogue with chat-like bubbles.
class DialogueStep extends StatefulWidget {
  final LessonContentV2 lesson;
  final VoidCallback onComplete;

  const DialogueStep({super.key, required this.lesson, required this.onComplete});

  @override
  State<DialogueStep> createState() => _DialogueStepState();
}

class _DialogueStepState extends State<DialogueStep> {
  final Set<int> _revealedLines = {};
  bool _showAll = false;

  DialogueV2? get dialogue => widget.lesson.dialogue;

  void _toggleShowAll() {
    setState(() {
      _showAll = !_showAll;
      if (_showAll) {
        _revealedLines.addAll(
          List.generate(dialogue?.lines.length ?? 0, (i) => i),
        );
      } else {
        _revealedLines.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dialogue == null || dialogue!.lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pas de dialogue pour cette leçon',
                style: TextStyle(color: Color(0xFF999999))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onComplete,
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Situation banner
        if (dialogue!.situation != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D3557).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dialogue!.situation!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF444444),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Toggle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _toggleShowAll,
              icon: Icon(
                _showAll ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              label: Text(_showAll ? 'Masquer' : 'Tout afficher'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF666666),
              ),
            ),
          ),
        ),

        // Dialogue lines
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dialogue!.lines.length,
            itemBuilder: (ctx, i) {
              final line = dialogue!.lines[i];
              final isEven = i % 2 == 0;
              final isRevealed = _revealedLines.contains(i);

              return _DialogueBubble(
                line: line,
                isRight: isEven, // Alternate sides
                isRevealed: isRevealed,
                onTap: () {
                  setState(() {
                    if (_revealedLines.contains(i)) {
                      _revealedLines.remove(i);
                    } else {
                      _revealedLines.add(i);
                    }
                  });
                },
              );
            },
          ),
        ),

        // Continue button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuer', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  final DialogueLineV2 line;
  final bool isRight;
  final bool isRevealed;
  final VoidCallback onTap;

  const _DialogueBubble({
    required this.line,
    required this.isRight,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isRight
        ? const Color(0xFF1D3557).withOpacity(0.08)
        : const Color(0xFF2D6A4F).withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRight) ...[
            // Speaker avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.2),
              child: Text(
                line.speakerAr.isNotEmpty ? line.speakerAr[0] : '?',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isRight ? 16 : 4),
                    bottomRight: Radius.circular(isRight ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isRight
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Speaker name
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        line.speakerAr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Amiri',
                          color: isRight
                              ? const Color(0xFF1D3557)
                              : const Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Arabic text
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        line.arabic,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Amiri',
                          color: Color(0xFF1A1A2E),
                          height: 1.5,
                        ),
                      ),
                    ),

                    // French translation (tap to reveal)
                    AnimatedCrossFade(
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '[ Tap pour voir la traduction ]',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          line.french,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      crossFadeState: isRevealed
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isRight) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1D3557).withOpacity(0.2),
              child: Text(
                line.speakerAr.isNotEmpty ? line.speakerAr[0] : '?',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: Color(0xFF1D3557),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

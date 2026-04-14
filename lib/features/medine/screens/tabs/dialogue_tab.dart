import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/lesson_models.dart';

/// Tab 2: Dialogue practice with structured Arabic/French dialogue lines.
class DialogueTab extends StatefulWidget {
  final int lessonNumber;
  final DialogueContent? dialogue;
  final VoidCallback onComplete;

  const DialogueTab({
    super.key,
    required this.lessonNumber,
    this.dialogue,
    required this.onComplete,
  });

  @override
  State<DialogueTab> createState() => _DialogueTabState();
}

class _DialogueTabState extends State<DialogueTab> {
  bool _completed = false;
  // Track which lines have their French translation revealed
  final Set<int> _revealedLines = {};

  @override
  Widget build(BuildContext context) {
    final dialogue = widget.dialogue;

    if (dialogue == null || dialogue.lines.isEmpty) {
      return _buildPlaceholder();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_completed &&
            notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 50) {
          _completed = true;
          widget.onComplete();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 22, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Mini-Dialogue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Situation context
          if (dialogue.situation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dialogue.situation!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Text(
                  'Touchez une ligne pour voir la traduction',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dialogue lines
          for (int i = 0; i < dialogue.lines.length; i++) ...[
            _DialogueLineCard(
              line: dialogue.lines[i],
              index: i,
              isRevealed: _revealedLines.contains(i),
              onTap: () {
                setState(() {
                  if (_revealedLines.contains(i)) {
                    _revealedLines.remove(i);
                  } else {
                    _revealedLines.add(i);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          // Reveal all / Hide all
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_revealedLines.length == dialogue.lines.length) {
                      _revealedLines.clear();
                    } else {
                      for (int i = 0; i < dialogue.lines.length; i++) {
                        _revealedLines.add(i);
                      }
                    }
                  });
                },
                icon: Icon(
                  _revealedLines.length == dialogue.lines.length
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 18,
                ),
                label: Text(
                  _revealedLines.length == dialogue.lines.length
                      ? 'Masquer tout'
                      : 'Tout afficher',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mark as complete
          if (!_completed)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _completed = true);
                widget.onComplete();
              },
              icon: const Icon(Icons.check),
              label: const Text('Dialogue termine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Termine',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dialogue de la lecon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le dialogue sera disponible prochainement.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (!_completed)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _completed = true);
                  widget.onComplete();
                },
                icon: const Icon(Icons.check),
                label: const Text('Marquer comme termine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(240, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogueLineCard extends StatelessWidget {
  final DialogueLine line;
  final int index;
  final bool isRevealed;
  final VoidCallback onTap;

  const _DialogueLineCard({
    required this.line,
    required this.index,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEven
              ? AppColors.primary.withOpacity(0.04)
              : AppColors.accent.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEven
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.accent.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker label
            Text(
              line.speakerAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEven ? AppColors.primary : AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            // Arabic text (RTL)
            Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  line.arabic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Amiri',
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // French translation (revealed on tap)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  line.french,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
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
    );
  }
}

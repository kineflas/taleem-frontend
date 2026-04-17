import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Mur Invisible: Identify connecting vs non-connecting letters.
class MurInvisibleExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const MurInvisibleExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<MurInvisibleExercise> createState() => _MurInvisibleExerciseState();
}

class _MurInvisibleExerciseState extends State<MurInvisibleExercise> {
  int _currentItem = 0;
  bool? _selectedConnectante;
  bool _showFeedback = false;
  int _correctCount = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final lettre = item['lettre'] ?? '';
    final connectante = item['connectante'] == true;
    final animation = item['animation'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.exercise.promptFr != null)
            Text(widget.exercise.promptFr!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Cette lettre se connecte-t-elle a gauche ?',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Letter display with wall visual
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _showFeedback
                          ? (_selectedConnectante == connectante
                              ? const Color(0xFF2A9D8F).withOpacity(0.15)
                              : const Color(0xFFC0392B).withOpacity(0.1))
                          : const Color(0xFF6C3483).withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showFeedback
                            ? (_selectedConnectante == connectante
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFFC0392B))
                            : const Color(0xFF6C3483),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lettre,
                        style: const TextStyle(
                            fontSize: 72, fontFamily: 'Amiri', color: Color(0xFF1A1A2E)),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  if (animation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(animation,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  ],
                  const SizedBox(height: 12),

                  // Feedback hint
                  if (_showFeedback)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_selectedConnectante == connectante
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFFC0392B))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        connectante
                            ? 'Oui, elle se connecte !'
                            : 'Non, elle ne se connecte pas (mur invisible)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedConnectante == connectante
                              ? const Color(0xFF2A9D8F)
                              : const Color(0xFFC0392B),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Two choice buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceButton(
                          label: 'Connectante',
                          icon: Icons.link_rounded,
                          color: const Color(0xFF2A9D8F),
                          isSelected: _selectedConnectante == true,
                          isCorrect: connectante == true,
                          showFeedback: _showFeedback,
                          onTap: _showFeedback ? null : () => _answer(true, connectante),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ChoiceButton(
                          label: 'Non-connectante',
                          icon: Icons.link_off_rounded,
                          color: const Color(0xFFE76F51),
                          isSelected: _selectedConnectante == false,
                          isCorrect: connectante == false,
                          showFeedback: _showFeedback,
                          onTap: _showFeedback ? null : () => _answer(false, connectante),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Text(
            '${_currentItem + 1}/${items.length}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _answer(bool selected, bool correct) {
    setState(() {
      _selectedConnectante = selected;
      _showFeedback = true;
      if (selected == correct) _correctCount++;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final items = widget.exercise.items;
      if (_currentItem < items.length - 1) {
        setState(() {
          _currentItem++;
          _selectedConnectante = null;
          _showFeedback = false;
        });
      } else {
        widget.onComplete(correct: _correctCount > items.length ~/ 2);
      }
    });
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = color.withOpacity(0.05);
    Color borderColor = color.withOpacity(0.3);

    if (showFeedback) {
      if (isCorrect) {
        bgColor = const Color(0xFF2A9D8F).withOpacity(0.2);
        borderColor = const Color(0xFF2A9D8F);
      } else if (isSelected && !isCorrect) {
        bgColor = const Color(0xFFC0392B).withOpacity(0.1);
        borderColor = const Color(0xFFC0392B);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Energy bar showing 4 segments: Cours, Dialogue, Exercices, Quiz.
/// Each segment fills independently based on completion.
class EnergyBar extends StatelessWidget {
  final bool theoryDone;
  final bool dialogueDone;
  final bool exercisesDone;
  final bool quizDone;

  const EnergyBar({
    super.key,
    this.theoryDone = false,
    this.dialogueDone = false,
    this.exercisesDone = false,
    this.quizDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Segment(label: 'Cours', done: theoryDone, icon: Icons.menu_book),
      _Segment(label: 'Dialogue', done: dialogueDone, icon: Icons.chat_bubble_outline),
      _Segment(label: 'Exercices', done: exercisesDone, icon: Icons.edit_note),
      _Segment(label: 'Quiz', done: quizDone, icon: Icons.quiz_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _SegmentWidget(segment: segments[i])),
          ],
        ],
      ),
    );
  }
}

class _Segment {
  final String label;
  final bool done;
  final IconData icon;
  const _Segment({required this.label, required this.done, required this.icon});
}

class _SegmentWidget extends StatelessWidget {
  final _Segment segment;
  const _SegmentWidget({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          segment.icon,
          size: 18,
          color: segment.done ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: segment.done ? AppColors.success : AppColors.heatmapEmpty,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          segment.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: segment.done ? FontWeight.w600 : FontWeight.normal,
            color: segment.done ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

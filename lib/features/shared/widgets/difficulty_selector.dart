import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DifficultySelector extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onChanged;
  final bool childMode; // no text note allowed

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.childMode = false,
  });

  static const _options = [
    (value: 1, emoji: '😊', label: 'Facile'),
    (value: 2, emoji: '😐', label: 'Moyen'),
    (value: 3, emoji: '😓', label: 'Difficile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _options.map((opt) {
        final isSelected = selected == opt.value;
        return GestureDetector(
          onTap: () => onChanged(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _colorForDifficulty(opt.value).withOpacity(0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _colorForDifficulty(opt.value)
                    : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? _colorForDifficulty(opt.value)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorForDifficulty(int v) {
    switch (v) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.accent;
      case 3:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}

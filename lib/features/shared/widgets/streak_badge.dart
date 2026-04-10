import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool compact;

  const StreakBadge({super.key, required this.streak, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: streak > 0 ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: streak > 0 ? AppColors.primary.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streak > 0 ? '🔥' : '💤',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak jours',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: streak > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class JokerBadge extends StatelessWidget {
  final int jokersLeft;

  const JokerBadge({super.key, required this.jokersLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.joker.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.joker.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$jokersLeft joker${jokersLeft > 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppColors.joker,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

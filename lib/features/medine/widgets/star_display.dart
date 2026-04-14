import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Displays 1-3 stars for a lesson, with filled/unfilled states.
class StarDisplay extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;

  const StarDisplay({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.accent : AppColors.textHint,
            size: size,
          ),
        );
      }),
    );
  }
}

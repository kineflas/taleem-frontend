import 'package:flutter/material.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';

/// Indicateur horizontal des étapes du Wird.
/// Minimaliste : points reliés par une ligne, label en dessous.
class WirdStepIndicator extends StatelessWidget {
  const WirdStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  final List<WirdStep> steps;
  final WirdStep currentStep;

  static const _stepLabels = {
    WirdStep.nour: 'نور',
    WirdStep.tikrar: 'تكرار',
    WirdStep.tamrin: 'تمرين',
    WirdStep.tasmi: 'تسميع',
    WirdStep.natija: 'نتيجة',
  };

  @override
  Widget build(BuildContext context) {
    final currentIdx = steps.indexOf(currentStep);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Ligne entre les points
            final stepBefore = i ~/ 2;
            final isDone = stepBefore < currentIdx;
            return Expanded(
              child: Container(
                height: 1.5,
                color: isDone
                    ? HifzColors.emerald.withOpacity(0.6)
                    : HifzColors.ivoryDark,
              ),
            );
          }

          final stepIdx = i ~/ 2;
          final step = steps[stepIdx];
          final isCurrent = stepIdx == currentIdx;
          final isDone = stepIdx < currentIdx;

          return _StepDot(
            label: _stepLabels[step] ?? '',
            isCurrent: isCurrent,
            isDone: isDone,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.isCurrent,
    required this.isDone,
  });

  final String label;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? HifzColors.gold
        : isDone
            ? HifzColors.emerald
            : HifzColors.textLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 12 : 8,
          height: isCurrent ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? HifzColors.emerald : (isCurrent ? HifzColors.gold : Colors.transparent),
            border: Border.all(
              color: color,
              width: isCurrent ? 2.5 : 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: isCurrent ? 12 : 10,
            color: color,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

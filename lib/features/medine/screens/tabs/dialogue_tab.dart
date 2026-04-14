import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Tab 2: Dialogue practice (placeholder — content will be enriched
/// when dialogue data is added to the lesson seed).
class DialogueTab extends StatefulWidget {
  final int lessonNumber;
  final VoidCallback onComplete;

  const DialogueTab({
    super.key,
    required this.lessonNumber,
    required this.onComplete,
  });

  @override
  State<DialogueTab> createState() => _DialogueTabState();
}

class _DialogueTabState extends State<DialogueTab> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
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
              'Le dialogue interactif sera disponible prochainement.\n'
              'En attendant, marquez cette section comme terminee '
              'apres avoir revu le cours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
          ],
        ),
      ),
    );
  }
}

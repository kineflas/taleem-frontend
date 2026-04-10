import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/task_model.dart';
import '../../auth/models/user_model.dart';
import 'arabic_text.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onComplete;
  final bool showStudent;

  const TaskCard({
    super.key,
    required this.task,
    this.onComplete,
    this.showStudent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final isMissed = task.status == TaskStatus.missed;
    final isSkipped = task.status == TaskStatus.skipped;

    return Opacity(
      opacity: isCompleted ? 0.65 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isMissed
                ? AppColors.danger.withOpacity(0.3)
                : isSkipped
                    ? AppColors.skipped.withOpacity(0.3)
                    : isCompleted
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PillarIcon(pillar: task.pillar),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel(task.taskType),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (task.pillar == TaskPillar.quran && task.surahName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: ArabicText(
                              task.surahName!,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        if (task.verseStart != null && task.verseEnd != null)
                          Text(
                            'Versets ${task.verseStart} → ${task.verseEnd}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        if (task.pillar == TaskPillar.arabic)
                          Text(
                            task.subtitleDisplay,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: task.status, completion: task.completion),
                ],
              ),

              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Consigne : ${task.description}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (isCompleted && task.completion != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.completion!.difficulty != null)
                      Text(
                        task.completion!.difficultyEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (task.completion!.parentValidated)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('👨‍👧', style: TextStyle(fontSize: 16)),
                      ),
                    if (task.completion!.studentNote != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${task.completion!.studentNote}"',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Complete button
              if (!isCompleted && !isSkipped && onComplete != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Text('✅', style: TextStyle(fontSize: 18)),
                    label: const Text("J'ai révisé"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TaskType type) {
    switch (type) {
      case TaskType.memorization:
        return 'Mémorisation';
      case TaskType.revision:
        return 'Révision';
      case TaskType.reading:
        return 'Lecture';
      case TaskType.grammar:
        return 'Grammaire';
      case TaskType.vocabulary:
        return 'Vocabulaire';
    }
  }
}

class _PillarIcon extends StatelessWidget {
  final TaskPillar pillar;
  const _PillarIcon({required this.pillar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: pillar == TaskPillar.quran
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          pillar == TaskPillar.quran ? '📖' : '🔤',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final TaskCompletionModel? completion;

  const _StatusBadge({required this.status, this.completion});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.completed:
        return const Text('✅', style: TextStyle(fontSize: 22));
      case TaskStatus.missed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '⚠️ En retard',
            style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      case TaskStatus.skipped:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.skipped.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Excusé',
            style: TextStyle(color: AppColors.skipped, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      case TaskStatus.pending:
        return const Text('⏳', style: TextStyle(fontSize: 20));
    }
  }
}

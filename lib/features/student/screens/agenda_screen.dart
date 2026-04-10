import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../shared/models/task_model.dart';
import '../../shared/widgets/task_card.dart';
import '../../../core/constants/app_colors.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Agenda')),
      body: agendaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(agendaProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'Aucune tâche à venir.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final grouped = _groupBySection(tasks);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final entry = grouped[i];
              if (entry is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Text(
                    entry,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              } else {
                return TaskCard(task: entry as TaskModel);
              }
            },
          );
        },
      ),
    );
  }

  List<Object> _groupBySection(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    final result = <Object>[];
    String? lastSection;

    for (final task in tasks) {
      final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      String section;

      if (due.isAtSameMomentAs(today)) {
        section = "AUJOURD'HUI";
      } else if (due.isAtSameMomentAs(tomorrow)) {
        section = 'DEMAIN';
      } else if (due.isBefore(endOfWeek)) {
        section = 'CETTE SEMAINE';
      } else {
        section = 'PLUS TARD';
      }

      if (section != lastSection) {
        result.add(section);
        lastSection = section;
      }

      // For "CETTE SEMAINE" and "PLUS TARD", prefix the date in the card header
      result.add(task);
    }

    return result;
  }
}

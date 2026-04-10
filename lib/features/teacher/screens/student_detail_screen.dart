import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/teacher_provider.dart';
import '../../shared/models/task_model.dart';
import '../../shared/widgets/task_card.dart';
import '../../shared/widgets/heatmap_widget.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../../core/constants/app_colors.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(studentDetailProvider(widget.studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: detailAsync.when(
          data: (d) => Text(d.student.fullName),
          loading: () => const Text('Élève'),
          error: (_, __) => const Text('Élève'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Assigner une tâche',
            onPressed: () => context.push(
              '/teacher/create-task',
              extra: {'studentId': widget.studentId},
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: "Aujourd'hui"),
            const Tab(text: 'Agenda'),
            const Tab(text: 'Progression'),
            Tab(
              child: detailAsync.when(
                data: (d) => d.unreadHardFeedback > 0
                    ? Stack(clipBehavior: Clip.none, children: [
                        const Text('Feedback'),
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ])
                    : const Text('Feedback'),
                loading: () => const Text('Feedback'),
                error: (_, __) => const Text('Feedback'),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(studentId: widget.studentId),
          _AgendaTab(studentId: widget.studentId),
          _ProgressTab(studentId: widget.studentId),
          _FeedbackTab(studentId: widget.studentId),
        ],
      ),
    );
  }
}

// ─── Today Tab ───────────────────────────────────────────────────────────────

class _TodayTab extends ConsumerWidget {
  final String studentId;
  const _TodayTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(teacherTasksProvider(studentId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (tasks) {
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final todayTasks = tasks.where((t) => t.dueDate.toIso8601String().startsWith(todayStr)).toList();

        if (todayTasks.isEmpty) {
          return const Center(
            child: Text(
              "Aucune tâche assignée aujourd'hui.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: todayTasks.length,
          itemBuilder: (ctx, i) => TaskCard(
            task: todayTasks[i],
            onComplete: todayTasks[i].status == TaskStatus.pending
                ? () async {
                    await ref.read(taskCreationProvider.notifier).skipTask(todayTasks[i].id);
                    ref.invalidate(teacherTasksProvider(studentId));
                  }
                : null,
          ),
        );
      },
    );
  }
}

// ─── Agenda Tab ───────────────────────────────────────────────────────────────

class _AgendaTab extends ConsumerWidget {
  final String studentId;
  const _AgendaTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(teacherTasksProvider(studentId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (tasks) {
        final sorted = [...tasks]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        if (sorted.isEmpty) {
          return const Center(
            child: Text(
              'Aucune tâche planifiée.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sorted.length,
          itemBuilder: (ctx, i) {
            final task = sorted[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i == 0 ||
                    sorted[i - 1].dueDate.day != task.dueDate.day)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(
                      DateFormat('EEEE d MMMM', 'fr').format(task.dueDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                TaskCard(task: task),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Progress Tab ────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerWidget {
  final String studentId;
  const _ProgressTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder(
        future: Future.value(null),
        builder: (ctx, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Heatmap', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            HeatmapWidget(
              days: const [],
              year: now.year,
              month: now.month,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feedback Tab ────────────────────────────────────────────────────────────

class _FeedbackTab extends ConsumerWidget {
  final String studentId;
  const _FeedbackTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(studentFeedbackProvider(studentId));

    return feedbackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (completions) {
        if (completions.isEmpty) {
          return const Center(
            child: Text('Aucun feedback pour le moment.'),
          );
        }

        final sorted = [...completions]
          ..sort((a, b) {
            if (a.difficulty == 3 && b.difficulty != 3) return -1;
            if (b.difficulty == 3 && a.difficulty != 3) return 1;
            if (!a.teacherRead && b.teacherRead) return -1;
            if (!b.teacherRead && a.teacherRead) return 1;
            return b.completedAt.compareTo(a.completedAt);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sorted.length,
          itemBuilder: (ctx, i) => _FeedbackCard(completion: sorted[i]),
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final TaskCompletionModel completion;
  const _FeedbackCard({required this.completion});

  @override
  Widget build(BuildContext context) {
    final isHard = completion.difficulty == 3;
    final isUnread = !completion.teacherRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHard ? AppColors.danger.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Text(
          completion.difficultyEmoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Row(
          children: [
            Text(
              DateFormat('d MMM', 'fr').format(completion.completedAt),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (completion.parentValidated) ...[
              const SizedBox(width: 8),
              const Text('👨‍👧', style: TextStyle(fontSize: 14)),
            ],
          ],
        ),
        subtitle: completion.studentNote != null
            ? Text(
                '"${completion.studentNote}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              )
            : const Text('Aucune note'),
        trailing: isHard
            ? const Icon(Icons.priority_high, color: AppColors.danger)
            : null,
      ),
    );
  }
}

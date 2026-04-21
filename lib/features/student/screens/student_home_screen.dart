import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../shared/models/task_model.dart';
import '../../shared/widgets/task_card.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../shared/widgets/joker_bottom_sheet.dart';
import '../../shared/widgets/difficulty_selector.dart';
import '../../shared/widgets/parent_pin_dialog.dart';
import '../../shared/widgets/offline_banner.dart';
import '../../hifz_v2/providers/hifz_v2_provider.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Accueil intelligent — reprises rapides + tâches du jour.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final streakAsync = ref.watch(streakProvider);
    final journeyAsync = ref.watch(journeyMapProvider);
    final wirdAsync = ref.watch(wirdTodayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayTasksProvider);
            ref.invalidate(streakProvider);
            ref.invalidate(journeyMapProvider);
            ref.invalidate(wirdTodayProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── En-tête ──
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OfflineBanner(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assalamu Alaykum, ${user?.fullName.split(' ').first ?? ''}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE d MMMM', 'fr').format(DateTime.now()),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          streakAsync.when(
                            data: (s) => s != null
                                ? Row(
                                    children: [
                                      StreakBadge(streak: s.currentStreakDays),
                                      const SizedBox(width: 12),
                                      JokerBadge(jokersLeft: s.jokersLeft),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Joker danger banner ──
              SliverToBoxAdapter(
                child: streakAsync.when(
                  data: (streak) {
                    if (streak == null || !streak.hasJokersLeft) return const SizedBox.shrink();
                    final now = DateTime.now();
                    final isEvening = now.hour >= 20;
                    final tasksDone = tasksAsync.valueOrNull
                            ?.any((t) => t.status == TaskStatus.completed) ??
                        false;
                    if (!isEvening || tasksDone) return const SizedBox.shrink();
                    return _JokerDangerBanner(streak: streak);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Section « Reprendre » ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'REPRENDRE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // ── Card : Wird en cours ──
                      wirdAsync.when(
                        data: (wird) {
                          if (wird.totalVerses == 0) return const SizedBox.shrink();
                          final label = wird.status == 'COMPLETED'
                              ? 'Wird terminé'
                              : '${wird.totalVerses} versets';
                          return _ResumeCard(
                            icon: Icons.auto_stories,
                            color: HifzColors.emerald,
                            title: 'Mon Wird',
                            subtitle: label,
                            onTap: () => context.push('/hifz-v2/ikhtiar'),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // ── Card : Hifz Master V2 ──
                      journeyAsync.when(
                        data: (journey) {
                          final versesMemorized = journey.totalVersesMemorized;
                          return _ResumeCard(
                            icon: Icons.mosque_outlined,
                            color: HifzColors.gold,
                            title: 'Hifz Master',
                            subtitle: '$versesMemorized versets appris',
                            onTap: () => context.go('/student/hifz-v2'),
                          );
                        },
                        loading: () => _ResumeCard(
                          icon: Icons.mosque_outlined,
                          color: HifzColors.gold,
                          title: 'Hifz Master',
                          subtitle: 'Chargement...',
                          onTap: () => context.go('/student/hifz-v2'),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // ── Card : Lecteur Coran rapide ──
                      _ResumeCard(
                        icon: Icons.headphones_outlined,
                        color: const Color(0xFF5C6BC0),
                        title: 'Écouter le Coran',
                        subtitle: 'Lecteur audio',
                        onTap: () => context.go('/student/quran'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section tâches du jour ──
              SliverToBoxAdapter(
                child: tasksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(e.toString()),
                    ),
                  ),
                  data: (tasks) => _TaskList(tasks: tasks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Resume Card ─────────────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResumeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task List (repris de student_today_screen) ──────────────────────────

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = tasks.where((t) => t.status == TaskStatus.pending).toList();
    final missed = tasks.where((t) => t.status == TaskStatus.missed).toList();
    final completed = tasks.where((t) => t.status == TaskStatus.completed).toList();

    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Text(
            'Pas de tâches pour aujourd\'hui. Bonne journée !',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missed.isNotEmpty) ...[
          _SectionHeader(title: 'EN RETARD', color: AppColors.danger),
          ...missed.map((t) => TaskCard(
                task: t,
                onComplete: () => _handleComplete(context, ref, t),
              )),
        ],
        if (pending.isNotEmpty) ...[
          _SectionHeader(title: 'À FAIRE AUJOURD\'HUI'),
          ...pending.map((t) => TaskCard(
                task: t,
                onComplete: () => _handleComplete(context, ref, t),
              )),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(title: 'TERMINÉ', color: AppColors.success),
          ...completed.map((t) => TaskCard(task: t)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _handleComplete(BuildContext ctx, WidgetRef ref, TaskModel task) async {
    final user = ref.read(currentUserProvider);
    final isChild = user?.isChildProfile ?? false;
    final hasPin = user?.hasParentPin ?? false;

    int? difficulty;
    String? note;
    String? parentToken;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CompletionSheet(isChild: isChild),
    );

    if (result == null) return;
    difficulty = result['difficulty'] as int?;
    note = result['note'] as String?;

    if (isChild && hasPin && ctx.mounted) {
      final pinOk = await showParentPinDialog(
        ctx,
        onVerify: (pin) async {
          final token = await ref.read(authStateProvider.notifier).verifyParentPin(pin);
          parentToken = token;
          return token != null;
        },
      );
      if (!pinOk) return;
    }

    await ref.read(todayTasksProvider.notifier).completeTask(
          taskId: task.id,
          difficulty: difficulty,
          note: note,
          parentToken: parentToken,
        );

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Révision validée !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _CompletionSheet extends StatefulWidget {
  final bool isChild;
  const _CompletionSheet({required this.isChild});

  @override
  State<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<_CompletionSheet> {
  int? _difficulty;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Comment ça s\'est passé ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Difficulté (optionnel)',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          DifficultySelector(
            selected: _difficulty,
            onChanged: (v) => setState(() => _difficulty = v),
            childMode: widget.isChild,
          ),
          if (!widget.isChild) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Ex: C\'était long à mémoriser...',
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop({
              'difficulty': _difficulty,
              'note': widget.isChild ? null : _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            }),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("J'ai révisé"),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _JokerDangerBanner extends ConsumerWidget {
  final StreakModel streak;
  const _JokerDangerBanner({required this.streak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.joker.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.joker.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ta série est en danger !',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  'Ta série de ${streak.currentStreakDays} jours est menacée.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showJokerBottomSheet(
              context,
              jokersLeft: streak.jokersLeft,
              onConfirm: (reason, note) =>
                  ref.read(streakProvider.notifier).useJoker(reason: reason, note: note),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.joker,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Joker', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../shared/widgets/heatmap_widget.dart';
import '../../shared/models/task_model.dart';
import '../../shared/widgets/task_card.dart';
import '../../hifz_v2/providers/hifz_v2_provider.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../../../core/constants/app_colors.dart';


/// Onglet Profil — fusionne Progression + Agenda + Réglages.
class ProfileTabScreen extends ConsumerStatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  ConsumerState<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends ConsumerState<ProfileTabScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final streakAsync = ref.watch(streakProvider);
    final progressAsync = ref.watch(progressProvider);
    final heatmapArgs = (year: _year, month: _month);
    final heatmapAsync = ref.watch(heatmapProvider(heatmapArgs));
    final agendaAsync = ref.watch(agendaProvider);
    final journeyAsync = ref.watch(journeyMapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(streakProvider);
            ref.invalidate(progressProvider);
            ref.invalidate(agendaProvider);
            ref.invalidate(journeyMapProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── En-tête profil ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.fullName[0].toUpperCase() ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? '',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            // Titre Hifz si disponible
                            journeyAsync.when(
                              data: (j) => Text(
                                '${j.titleFr} — Niveau ${j.level}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/student/settings'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Streak + stats ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: streakAsync.when(
                    data: (s) {
                      if (s == null) return const SizedBox.shrink();
                      return Row(
                        children: [
                          StreakBadge(streak: s.currentStreakDays),
                          const SizedBox(width: 12),
                          _MiniStat(label: 'Record', value: '${s.longestStreakDays}j'),
                          const SizedBox(width: 12),
                          _MiniStat(label: 'Jokers', value: '${s.jokersLeft}'),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Stats Hifz ──
              SliverToBoxAdapter(
                child: journeyAsync.when(
                  data: (j) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Row(
                      children: [
                        _MiniStat(
                          label: 'Versets appris',
                          value: '${j.totalVersesMemorized}',
                          color: HifzColors.emerald,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label: 'XP',
                          value: '${j.totalXp}',
                          color: HifzColors.gold,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label: 'Étoiles',
                          value: '${j.totalStars}',
                          color: HifzColors.gold,
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Heatmap d'activité ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SectionTitle(title: 'ACTIVITÉ'),
                ),
              ),
              SliverToBoxAdapter(
                child: heatmapAsync.when(
                  data: (days) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HeatmapWidget(
                      days: days,
                      year: _year,
                      month: _month,
                      onMonthChanged: (offset) => _changeMonth(offset),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Agenda à venir ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionTitle(title: 'AGENDA'),
                ),
              ),
              SliverToBoxAdapter(
                child: agendaAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucune tâche à venir.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    // Afficher les 5 prochaines tâches max
                    final upcoming = tasks.take(5).toList();
                    return Column(
                      children: upcoming
                          .map((t) => TaskCard(task: t))
                          .toList(),
                    );
                  },
                ),
              ),

              // ── Progression détaillée ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: _SectionTitle(title: 'PROGRESSION'),
                ),
              ),
              SliverToBoxAdapter(
                child: progressAsync.when(
                  data: (p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _ProgressRow(
                              label: 'Tâches ce mois',
                              value: '${p.tasksThisMonth}',
                            ),
                            const Divider(height: 20),
                            _ProgressRow(
                              label: 'Total complétées',
                              value: '${p.totalTasksThisMonth}',
                            ),
                            const Divider(height: 20),
                            _ProgressRow(
                              label: 'Dernière activité Coran',
                              value: p.lastQuranTask ?? '—',
                            ),
                            const Divider(height: 20),
                            _ProgressRow(
                              label: 'Dernière activité Arabe',
                              value: p.lastArabicTask ?? '—',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Bouton déconnexion ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }
}

// ── Widgets utilitaires ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 1,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color ?? AppColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProgressRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_provider.dart';
import '../../shared/widgets/heatmap_widget.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../../core/constants/app_colors.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(streakProvider);
    final progressAsync = ref.watch(progressProvider);
    final heatmapArgs = (year: _year, month: _month);
    final heatmapAsync = ref.watch(heatmapProvider(heatmapArgs));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ma Progression'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Régularité'),
            Tab(text: 'Coran'),
            Tab(text: 'Arabe'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Tab 1: Régularité ────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                streakAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (streak) {
                    if (streak == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _StatCard(
                              emoji: '🔥',
                              label: 'Série actuelle',
                              value: '${streak.currentStreakDays} jours',
                              color: AppColors.primary,
                            ),
                            _StatCard(
                              emoji: '🏆',
                              label: 'Meilleure série',
                              value: '${streak.longestStreakDays} jours',
                              color: AppColors.accent,
                            ),
                            _StatCard(
                              emoji: '🃏',
                              label: 'Jokers ce mois',
                              value: '${streak.jokersUsedThisMonth} / ${streak.jokersTotal}',
                              color: AppColors.joker,
                            ),
                            _StatCard(
                              emoji: '✅',
                              label: 'Total validées',
                              value: '${streak.totalCompletedTasks}',
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text(
                  'Calendrier d\'activité',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: heatmapAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text(e.toString()),
                      data: (days) => HeatmapWidget(
                        days: days,
                        year: _year,
                        month: _month,
                        onMonthChanged: (offset) {
                          setState(() {
                            _month += offset;
                            if (_month > 12) {
                              _month = 1;
                              _year++;
                            } else if (_month < 1) {
                              _month = 12;
                              _year--;
                            }
                          });
                          ref.invalidate(heatmapProvider(heatmapArgs));
                        },
                        onDayTap: (day) => _showDayDetail(context, day),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Tab 2: Coran ─────────────────────────────────────────────────
          progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (p) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProgressCard(
                  icon: '📖',
                  title: 'Coran',
                  items: [
                    _ProgressItem('Sourates travaillées', '${p.surahsWorked}'),
                    _ProgressItem('Versets mémorisés', '${p.versesMemorized}'),
                    _ProgressItem('Versets révisés', '${p.versesRevised}'),
                    if (p.lastQuranTask != null)
                      _ProgressItem('Dernier verset', p.lastQuranTask!),
                  ],
                ),
              ],
            ),
          ),

          // ─── Tab 3: Arabe ─────────────────────────────────────────────────
          progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (p) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProgressCard(
                  icon: '🔤',
                  title: 'Arabe',
                  items: [
                    if (p.currentBook != null)
                      _ProgressItem('Livre actuel', p.currentBook!),
                    if (p.lessonsCompleted != null)
                      _ProgressItem(
                        'Leçons complétées',
                        '${p.lessonsCompleted} / ${p.totalLessons ?? '?'}',
                      ),
                    if (p.lastArabicTask != null)
                      _ProgressItem('Dernière leçon', p.lastArabicTask!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, HeatmapDay day) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.date.day}/${day.date.month}/${day.date.year}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (day.completedCount > 0)
              Text('✅ ${day.completedCount} tâche(s) validée(s)'),
            if (day.jokerUsed) const Text('🃏 Joker utilisé'),
            if (day.hasMissed) const Text('❌ Tâche(s) manquée(s)'),
            if (day.hasSkipped) const Text('📘 Tâche(s) excusée(s) par le prof'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<_ProgressItem> items;

  const _ProgressCard({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label,
                          style: const TextStyle(color: AppColors.textSecondary)),
                      Text(item.value,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ProgressItem {
  final String label;
  final String value;
  const _ProgressItem(this.label, this.value);
}

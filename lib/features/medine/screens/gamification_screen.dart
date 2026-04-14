import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/flashcard_provider.dart';

/// Gamification hub: XP bar, level display, badge gallery, quick actions.
class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(flashcardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP & Level card (placeholder — reads from auth/user when available)
            _XpLevelCard(),
            const SizedBox(height: 20),

            // SRS Stats
            const _SectionHeader(title: 'Flashcards SRS'),
            const SizedBox(height: 8),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
              data: (stats) => _SrsStatsCard(stats: stats),
            ),
            const SizedBox(height: 20),

            // Badge gallery
            const _SectionHeader(title: 'Mes Badges'),
            const SizedBox(height: 8),
            _BadgeGallery(),
            const SizedBox(height: 20),

            // Quick actions
            const _SectionHeader(title: 'Actions Rapides'),
            const SizedBox(height: 8),
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _XpLevelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: read from user model when XP backend is integrated
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.2),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau 1',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Explorateur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.accent, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '0 XP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // XP progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 XP', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Text('100 XP pour le niveau 2', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SrsStatsCard extends StatelessWidget {
  final dynamic stats;
  const _SrsStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'A reviser',
            value: '${stats.dueToday}',
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
          _StatItem(
            label: 'En cours',
            value: '${stats.learning}',
            icon: Icons.school,
            color: AppColors.primary,
          ),
          _StatItem(
            label: 'Maitrisees',
            value: '${stats.mastered}',
            icon: Icons.verified,
            color: AppColors.success,
          ),
          _StatItem(
            label: 'Total',
            value: '${stats.totalStarted}/${stats.totalAvailable}',
            icon: Icons.layers,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _BadgeGallery extends StatelessWidget {
  // Static badge definitions matching the backend seed
  static const badges = [
    _BadgeDef(code: 'premier_pas', name: 'Premier Pas', icon: Icons.directions_walk, desc: 'Termine ta premiere lecon'),
    _BadgeDef(code: 'detective', name: 'Detective', icon: Icons.search, desc: 'Passe le test diagnostique'),
    _BadgeDef(code: 'maitre_idafa', name: 'Maitre Idafa', icon: Icons.link, desc: 'Maitrise la Partie 3'),
    _BadgeDef(code: 'verbe_en_feu', name: 'Verbe en Feu', icon: Icons.local_fire_department, desc: 'Maitrise la Partie 5'),
    _BadgeDef(code: 'marathonien', name: 'Marathonien', icon: Icons.emoji_events, desc: 'Streak de 7 jours'),
    _BadgeDef(code: 'savant_diptotes', name: 'Savant Diptotes', icon: Icons.school, desc: 'Maitrise la Partie 6'),
    _BadgeDef(code: 'gardien_medine', name: 'Gardien de Medine', icon: Icons.shield, desc: 'Termine les 23 lecons'),
    _BadgeDef(code: 'polyglotte', name: 'Polyglotte', icon: Icons.translate, desc: 'Maitrise 150 flashcards'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) {
        final b = badges[i];
        // TODO: check unlock status from backend
        const isUnlocked = false;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                border: Border.all(
                  color: isUnlocked ? AppColors.accent : AppColors.divider,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                b.icon,
                size: 24,
                color: isUnlocked ? AppColors.accent : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              b.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BadgeDef {
  final String code;
  final String name;
  final IconData icon;
  final String desc;
  const _BadgeDef({required this.code, required this.name, required this.icon, required this.desc});
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.style,
          title: 'Reviser mes flashcards',
          subtitle: 'Revision SRS quotidienne',
          color: AppColors.primary,
          onTap: () => context.push('/medine/flashcards'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.quiz,
          title: 'Test diagnostique',
          subtitle: 'Evaluez votre niveau',
          color: AppColors.accent,
          onTap: () => context.push('/medine/diagnostic'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.menu_book,
          title: 'Continuer les lecons',
          subtitle: 'La Caravane du Savoir',
          color: AppColors.success,
          onTap: () => context.go('/student/medine'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

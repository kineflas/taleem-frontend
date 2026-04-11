import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../providers/hifz_provider.dart';
import '../../shared/widgets/streak_badge.dart';
import '../widgets/hifz_tour.dart';
import 'hifz_goal_create_screen.dart';
import 'hifz_session_screen.dart';
import 'hifz_revision_screen.dart';

class HifzHubScreen extends ConsumerStatefulWidget {
  const HifzHubScreen({super.key});

  @override
  ConsumerState<HifzHubScreen> createState() => _HifzHubScreenState();
}

class _HifzHubScreenState extends ConsumerState<HifzHubScreen> {
  // ── Tour GlobalKeys ─────────────────────────────────────────────────────────
  final _headerKey    = GlobalKey();
  final _focusKey     = GlobalKey();
  final _goalsKey     = GlobalKey();
  final _badgesKey    = GlobalKey();
  final _fabKey       = GlobalKey();

  late final SpotlightTour _tour;

  @override
  void initState() {
    super.initState();
    _tour = SpotlightTour(
      steps: [
        TourStep(
          targetKey: _headerKey,
          emoji: '⚡',
          title: 'Niveau & XP',
          description:
              'Votre niveau et vos points d\'expérience s\'affichent ici. Chaque verset mémorisé vous rapporte de l\'XP et fait monter votre rang.',
          position: TooltipPosition.bottom,
        ),
        TourStep(
          targetKey: _focusKey,
          emoji: '🎯',
          title: 'Tâche Prioritaire',
          description:
              'Cette carte indique votre mission du moment : révisions en attente (orange) ou nouvelle session de mémorisation (bleu). Appuyez pour commencer !',
          position: TooltipPosition.bottom,
        ),
        TourStep(
          targetKey: _goalsKey,
          emoji: '📖',
          title: 'Mes Objectifs',
          description:
              'Chaque objectif correspond à une sourate. Suivez votre progression et reprenez là où vous vous êtes arrêté(e).',
          position: TooltipPosition.bottom,
        ),
        TourStep(
          targetKey: _badgesKey,
          emoji: '🏆',
          title: 'Mes Badges',
          description:
              'Les badges récompensent vos accomplissements : séries de jours consécutifs, sourates complètes, premier juz...',
          position: TooltipPosition.top,
        ),
        TourStep(
          targetKey: _fabKey,
          emoji: '➕',
          title: 'Nouvel Objectif',
          description:
              'Appuyez ici pour choisir une nouvelle sourate à mémoriser et définir votre rythme quotidien.',
          position: TooltipPosition.top,
        ),
      ],
      onComplete: () => TourPrefs.markHubTourDone(),
    );

    // Déclencher le tour après le premier rendu si c'est la première visite
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final done = await TourPrefs.isHubTourDone();
      if (!done && mounted) {
        _tour.start(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(hifzGoalsProvider);
    final xpAsync = ref.watch(hifzStudentXPProvider);
    final dueVersesAsync = ref.watch(hifzDueVersesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hifzGoalsProvider);
            ref.invalidate(hifzStudentXPProvider);
            ref.invalidate(hifzDueVersesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header with XP and Streak
              SliverToBoxAdapter(
                child: _buildHeader(context, xpAsync),
              ),

              // ── FOCUS MODE : tâche prioritaire ─────────────────────────
              SliverToBoxAdapter(
                child: Builder(builder: (ctx) {
                  final goals = goalsAsync.valueOrNull ?? [];
                  final dueVerses = dueVersesAsync.valueOrNull ?? [];
                  final dueCount = dueVerses.where((v) {
                    final next = DateTime.parse(v.nextReviewDate);
                    return next.isBefore(DateTime.now().add(const Duration(days: 1)));
                  }).length;
                  return _buildFocusMode(ctx, ref, goals, dueCount);
                }),
              ),

              // Mes objectifs section
              SliverToBoxAdapter(
                child: goalsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Erreur: $e'),
                    ),
                  ),
                  data: (goals) => _buildGoalsSection(context, ref, goals),
                ),
              ),

              // Mes badges section
              SliverToBoxAdapter(
                child: xpAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (xp) => _buildBadgesSection(context, xp),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        key: _fabKey,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HifzGoalCreateScreen()),
            );
          },
          tooltip: 'Ajouter un objectif',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<StudentXPModel> xpAsync) {
    return Container(
      key: _headerKey,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hifz Master',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          xpAsync.when(
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, __) => const SizedBox.shrink(),
            data: (xp) => Row(
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        xp.level.titleFr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        xp.level.icon.toString().contains('import_contacts')
                            ? '📚'
                            : xp.level.icon.toString().contains('school')
                                ? '🎓'
                                : xp.level.icon.toString().contains('star_half')
                                    ? '⭐'
                                    : xp.level.icon.toString().contains('grade')
                                        ? '👑'
                                        : '🌟',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '⚡',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${xp.totalXp} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Focus Mode ────────────────────────────────────────────────────────────

  Widget _buildFocusMode(
    BuildContext context,
    WidgetRef ref,
    List<HifzGoalModel> goals,
    int dueCount,
  ) {
    // Cas 1 : des révisions sont dues → priorité absolue
    if (dueCount > 0) {
      return Container(
        key: _focusKey,   // only one branch renders at a time — no duplicate key
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HifzRevisionScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('🔁', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tâche Prioritaire',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dueCount verset${dueCount > 1 ? 's' : ''} à réviser',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Réviser maintenant →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Cas 2 : pas de révisions → montrer l'objectif en cours le plus avancé
    // _focusKey is attached to the cas-1 container above; for cas-2 we reuse the same key via a wrapper
    final activeGoal = goals
        .where((g) => !g.isCompleted)
        .fold<HifzGoalModel?>(null, (prev, g) {
      if (prev == null) return g;
      return g.versesMemorized > prev.versesMemorized ? g : prev;
    });

    if (activeGoal == null) return const SizedBox.shrink();

    final surahNames = _getSurahNames();
    final surahName = surahNames[activeGoal.surahNumber - 1]['ar']!;

    return Container(
      key: _focusKey,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HifzSessionScreen(goal: activeGoal)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reprendre la session',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surahName,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: activeGoal.totalVerses > 0
                              ? activeGoal.versesMemorized / activeGoal.totalVerses
                              : 0,
                          minHeight: 5,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeGoal.versesMemorized}/${activeGoal.totalVerses} versets • Continuer →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(
    BuildContext context,
    WidgetRef ref,
    List<HifzGoalModel> goals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          key: _goalsKey,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Mes objectifs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Center(
              child: Text(
                'Aucun objectif. Commencez en cliquant le bouton +',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...goals.map((goal) => _buildGoalCard(context, ref, goal)).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, HifzGoalModel goal) {
    final surahNames = _getSurahNames();
    final surahName = surahNames[goal.surahNumber - 1];
    final double progress = goal.totalVerses > 0 ? goal.versesMemorized / goal.totalVerses : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HifzSessionScreen(goal: goal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Surah name in Arabic
                Text(
                  surahName['ar']!,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.isCompleted ? '✅ Terminé' : '📖 En cours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: goal.isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '${goal.versesMemorized}/${goal.totalVerses}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.heatmapEmpty,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Daily target and days remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cible: ${goal.calculatedDailyTarget} versets/jour',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (goal.mode == GoalMode.temporal)
                  Text(
                    '${goal.targetDate != null ? DateTime.parse(goal.targetDate!).difference(DateTime.now()).inDays : 0} jours',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionSection(BuildContext context, List<VerseProgressModel> verses) {
    final dueCount = verses.where((v) {
      final nextReview = DateTime.parse(v.nextReviewDate);
      return nextReview.isBefore(DateTime.now().add(const Duration(days: 1)));
    }).length;

    if (dueCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Révisions du jour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dueCount versets à revoir',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HifzRevisionScreen()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réviser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, StudentXPModel xp) {
    if (xp.badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: _badgesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Mes badges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: xp.badges.map((badge) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getBadgeEmoji(badge.badgeType),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBadgeLabel(badge.badgeType),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getSurahNames() {
    return [
      {'ar': 'الفاتحة', 'en': 'Al-Fatiha'},
      {'ar': 'البقرة', 'en': 'Al-Baqarah'},
      {'ar': 'آل عمران', 'en': 'Ali-Imran'},
      {'ar': 'النساء', 'en': 'An-Nisa'},
      {'ar': 'المائدة', 'en': 'Al-Maidah'},
      {'ar': 'الأنعام', 'en': 'Al-An\'am'},
      {'ar': 'الأعراف', 'en': 'Al-A\'raf'},
      {'ar': 'الأنفال', 'en': 'Al-Anfal'},
      {'ar': 'التوبة', 'en': 'At-Taubah'},
      {'ar': 'يونس', 'en': 'Yunus'},
      {'ar': 'هود', 'en': 'Hud'},
      {'ar': 'يوسف', 'en': 'Yusuf'},
      {'ar': 'الرعد', 'en': 'Ar-Ra\'d'},
      {'ar': 'إبراهيم', 'en': 'Ibrahim'},
      {'ar': 'الحجر', 'en': 'Al-Hijr'},
      {'ar': 'النحل', 'en': 'An-Nahl'},
      {'ar': 'الإسراء', 'en': 'Al-Isra'},
      {'ar': 'الكهف', 'en': 'Al-Kahf'},
      {'ar': 'مريم', 'en': 'Maryam'},
      {'ar': 'طه', 'en': 'Ta-Ha'},
      {'ar': 'الأنبياء', 'en': 'Al-Anbiya'},
      {'ar': 'الحج', 'en': 'Al-Hajj'},
      {'ar': 'المؤمنون', 'en': 'Al-Mu\'minun'},
      {'ar': 'النور', 'en': 'An-Nur'},
      {'ar': 'الفرقان', 'en': 'Al-Furqan'},
      {'ar': 'الشعراء', 'en': 'Ash-Shu\'ara'},
      {'ar': 'النمل', 'en': 'An-Naml'},
      {'ar': 'القصص', 'en': 'Al-Qasas'},
      {'ar': 'العنكبوت', 'en': 'Al-Ankabut'},
      {'ar': 'الروم', 'en': 'Ar-Rum'},
      {'ar': 'لقمان', 'en': 'Luqman'},
      {'ar': 'السجدة', 'en': 'As-Sajdah'},
      {'ar': 'الأحزاب', 'en': 'Al-Ahzab'},
      {'ar': 'سبأ', 'en': 'Saba'},
      {'ar': 'فاطر', 'en': 'Fatir'},
      {'ar': 'يس', 'en': 'Ya-Sin'},
      {'ar': 'الصافات', 'en': 'As-Saffat'},
      {'ar': 'ص', 'en': 'Sad'},
      {'ar': 'الزمر', 'en': 'Az-Zumar'},
      {'ar': 'غافر', 'en': 'Ghafir'},
      {'ar': 'فصلت', 'en': 'Fussilat'},
      {'ar': 'الشورى', 'en': 'Ash-Shura'},
      {'ar': 'الزخرف', 'en': 'Az-Zukhruf'},
      {'ar': 'الدخان', 'en': 'Ad-Dukhan'},
      {'ar': 'الجاثية', 'en': 'Al-Jathiyah'},
      {'ar': 'الأحقاف', 'en': 'Al-Ahqaf'},
      {'ar': 'محمد', 'en': 'Muhammad'},
      {'ar': 'الفتح', 'en': 'Al-Fath'},
      {'ar': 'الحجرات', 'en': 'Al-Hujurat'},
      {'ar': 'ق', 'en': 'Qaf'},
      {'ar': 'الذاريات', 'en': 'Adh-Dhariyat'},
      {'ar': 'الطور', 'en': 'At-Tur'},
      {'ar': 'النجم', 'en': 'An-Najm'},
      {'ar': 'القمر', 'en': 'Al-Qamar'},
      {'ar': 'الرحمن', 'en': 'Ar-Rahman'},
      {'ar': 'الواقعة', 'en': 'Al-Waqi\'ah'},
      {'ar': 'الحديد', 'en': 'Al-Hadid'},
      {'ar': 'المجادلة', 'en': 'Al-Mujadilah'},
      {'ar': 'الحشر', 'en': 'Al-Hashr'},
      {'ar': 'الممتحنة', 'en': 'Al-Mumtahanah'},
      {'ar': 'الصف', 'en': 'As-Saff'},
      {'ar': 'الجمعة', 'en': 'Al-Jumu\'ah'},
      {'ar': 'المنافقون', 'en': 'Al-Munafiqun'},
      {'ar': 'التغابن', 'en': 'At-Taghabun'},
      {'ar': 'الطلاق', 'en': 'At-Talaq'},
      {'ar': 'التحريم', 'en': 'At-Tahrim'},
      {'ar': 'الملك', 'en': 'Al-Mulk'},
      {'ar': 'القلم', 'en': 'Al-Qalam'},
      {'ar': 'الحاقة', 'en': 'Al-Haqqah'},
      {'ar': 'المعارج', 'en': "Al-Ma'arij"},  // ← Sourate 70 (manquante)
      {'ar': 'نوح', 'en': 'Nuh'},
      {'ar': 'الجن', 'en': 'Al-Jinn'},
      {'ar': 'المزمل', 'en': 'Al-Muzzammil'},
      {'ar': 'المدثر', 'en': 'Al-Muddaththir'},
      {'ar': 'القيامة', 'en': 'Al-Qiyamah'},
      {'ar': 'الإنسان', 'en': 'Al-Insan'},
      {'ar': 'المرسلات', 'en': 'Al-Mursalat'},
      {'ar': 'النبأ', 'en': 'An-Naba'},
      {'ar': 'النازعات', 'en': 'An-Nazi\'at'},
      {'ar': 'عبس', 'en': 'Abasa'},
      {'ar': 'التكوير', 'en': 'At-Takwir'},
      {'ar': 'الإنفطار', 'en': 'Al-Infitar'},
      {'ar': 'المطففين', 'en': 'Al-Mutaffifin'},
      {'ar': 'الانشقاق', 'en': 'Al-Inshiqaq'},
      {'ar': 'البروج', 'en': 'Al-Buruj'},
      {'ar': 'الطارق', 'en': 'At-Tariq'},
      {'ar': 'الأعلى', 'en': 'Al-A\'la'},
      {'ar': 'الغاشية', 'en': 'Al-Ghashiyah'},
      {'ar': 'الفجر', 'en': 'Al-Fajr'},
      {'ar': 'البلد', 'en': 'Al-Balad'},
      {'ar': 'الشمس', 'en': 'Ash-Shams'},
      {'ar': 'الليل', 'en': 'Al-Layl'},
      {'ar': 'الضحى', 'en': 'Ad-Duha'},
      {'ar': 'الشرح', 'en': 'Ash-Sharh'},
      {'ar': 'التين', 'en': 'At-Tin'},
      {'ar': 'العلق', 'en': 'Al-Alaq'},
      {'ar': 'القدر', 'en': 'Al-Qadr'},
      {'ar': 'البينة', 'en': 'Al-Bayyinah'},
      {'ar': 'الزلزلة', 'en': 'Az-Zalzalah'},
      {'ar': 'العاديات', 'en': 'Al-Adiyat'},
      {'ar': 'القارعة', 'en': 'Al-Qari\'ah'},
      {'ar': 'التكاثر', 'en': 'At-Takathur'},
      {'ar': 'العصر', 'en': 'Al-Asr'},
      {'ar': 'الهمزة', 'en': 'Al-Humazah'},
      {'ar': 'الفيل', 'en': 'Al-Fil'},
      {'ar': 'قريش', 'en': 'Quraysh'},
      {'ar': 'الماعون', 'en': 'Al-Ma\'un'},
      {'ar': 'الكوثر', 'en': 'Al-Kawthar'},
      {'ar': 'الكافرون', 'en': 'Al-Kafirun'},
      {'ar': 'النصر', 'en': 'An-Nasr'},
      {'ar': 'المسد', 'en': 'Al-Masad'},
      {'ar': 'الإخلاص', 'en': 'Al-Ikhlas'},
      {'ar': 'الفلق', 'en': 'Al-Falaq'},
      {'ar': 'الناس', 'en': 'An-Nas'},
    ];
  }

  String _getBadgeEmoji(String badgeType) {
    switch (badgeType) {
      case 'HIZB':
        return '📖';
      case 'SURAH_COMPLETE':
        return '🏆';
      case 'STREAK_7':
        return '🔥';
      case 'STREAK_30':
        return '🌟';
      case 'STREAK_100':
        return '👑';
      case 'LEVEL_UP':
        return '⬆️';
      case 'FIRST_JUZ':
        return '📜';
      case 'RECITER_10':
        return '🎙️';
      default:
        return '⭐';
    }
  }

  String _getBadgeLabel(String badgeType) {
    switch (badgeType) {
      case 'HIZB':
        return 'Hizb';
      case 'SURAH_COMPLETE':
        return 'Surah';
      case 'STREAK_7':
        return '7 jours';
      case 'STREAK_30':
        return '30 jours';
      case 'STREAK_100':
        return '100 jours';
      case 'LEVEL_UP':
        return 'Niveau +';
      case 'FIRST_JUZ':
        return 'Juz 1';
      case 'RECITER_10':
        return '10 versets';
      default:
        return badgeType;
    }
  }
}

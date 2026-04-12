import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';
import '../widgets/alphabet_intro_card.dart';
import 'letter_mastery_map_screen.dart';
import 'letter_speed_round_screen.dart';

/// Screen showing all units of an enrolled program + per-unit progress.
/// Route: /student/curriculum/:enrollmentId
class CurriculumProgramScreen extends ConsumerWidget {
  final String enrollmentId;

  const CurriculumProgramScreen({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(enrollmentProgressProvider(enrollmentId));

    return progressAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (progress) {
        final program = progress.enrollment.program;
        final isAlphabet = program.curriculumType == CurriculumType.alphabetArabe;

        // ── Build letter mastery map (glyph → stars) ──────────────────────
        final letterMasteryMap = <String, int>{};
        if (isAlphabet) {
          for (final up in progress.units) {
            if (up.unit.unitType == 'LETTER' && up.unit.titleAr.isNotEmpty) {
              final firstItem = up.itemsProgress.isNotEmpty ? up.itemsProgress.first : null;
              letterMasteryMap[up.unit.titleAr] = firstItem?.masteryLevel ?? 0;
            }
          }
        }

        // ── Compute locked groups (progressive unlocking) ─────────────────
        // Group N unlocks when >= 50% of Group N-1 has stars > 0
        final unlockedGroups = <int>{0}; // group 0 is always unlocked
        for (int g = 1; g < letterGroups.length; g++) {
          final prev = letterGroups[g - 1];
          final started = prev.where((gl) => (letterMasteryMap[gl] ?? 0) > 0).length;
          if (started >= (prev.length * 0.5).ceil()) {
            unlockedGroups.add(g);
          }
        }

        // ── Letters needing speed-round practice (stars < 3 but > 0) ──────
        final reviewGlyphs = letterMasteryMap.entries
            .where((e) => e.value > 0 && e.value < 3)
            .map((e) => e.key)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Text(program.curriculumType.icon,
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          program.titleAr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  title: Text(program.titleFr,
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                actions: [
                  // ── Carte de maîtrise (alphabet only) ────────────────────
                  if (isAlphabet)
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded),
                      tooltip: 'Carte de maîtrise',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LetterMasteryMapScreen(enrollmentId: enrollmentId),
                        ),
                      ),
                    ),
                  // ── Mode vitesse (alphabet only, si des lettres à réviser) ─
                  if (isAlphabet && reviewGlyphs.isNotEmpty)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bolt),
                          tooltip: 'Mode Vitesse',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LetterSpeedRoundScreen(
                                glyphsToReview: reviewGlyphs,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${reviewGlyphs.length}',
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, size: 32),
                    onPressed: () => _continueLesson(context, ref),
                    tooltip: 'Continuer',
                  ),
                ],
              ),

              // Overall progress bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${progress.completedItems} / ${progress.totalItems} éléments',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${progress.completionPct.toStringAsFixed(0)} %',
                            style: TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.completionPct / 100,
                          backgroundColor: Colors.grey[200],
                          color: AppColors.primary,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Intro card (Alphabet only)
              if (isAlphabet)
                const SliverToBoxAdapter(child: AlphabetIntroCard()),

              // ── Group banners + letter tiles (alphabet) or plain list ────
              if (isAlphabet)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final unitProgress = progress.units[i];
                        final glyph = unitProgress.unit.titleAr;
                        // Find which group this glyph belongs to
                        int groupIdx = -1;
                        for (int g = 0; g < letterGroups.length; g++) {
                          if (letterGroups[g].contains(glyph)) {
                            groupIdx = g;
                            break;
                          }
                        }
                        final isLocked = groupIdx >= 0 && !unlockedGroups.contains(groupIdx);
                        // Show group header when it's the first letter of a group
                        final isGroupStart = groupIdx >= 0 &&
                            letterGroups[groupIdx].first == glyph;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isGroupStart) ...[
                              const SizedBox(height: 8),
                              _GroupHeader(
                                groupIdx: groupIdx,
                                isLocked: isLocked,
                                unlockedGroups: unlockedGroups,
                                letterMasteryMap: letterMasteryMap,
                              ),
                              const SizedBox(height: 6),
                            ],
                            _UnitProgressTile(
                              unitProgress: unitProgress,
                              enrollmentId: enrollmentId,
                              isLocked: isLocked,
                            ),
                          ],
                        );
                      },
                      childCount: progress.units.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final unitProgress = progress.units[i];
                        return _UnitProgressTile(
                          unitProgress: unitProgress,
                          enrollmentId: enrollmentId,
                        );
                      },
                      childCount: progress.units.length,
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
    );
  }

  void _continueLesson(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(curriculumApiProvider);
      final next = await api.fetchNextItem(enrollmentId);
      if (context.mounted) {
        if (next['item'] != null) {
          final item = CurriculumItem.fromJson(next['item']);
          context.push('/student/curriculum/$enrollmentId/item/${item.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Programme complété ! 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}

// ── Group header for alphabet progressive unlocking ──────────────────────────
class _GroupHeader extends StatelessWidget {
  final int groupIdx;
  final bool isLocked;
  final Set<int> unlockedGroups;
  final Map<String, int> letterMasteryMap;

  const _GroupHeader({
    required this.groupIdx,
    required this.isLocked,
    required this.unlockedGroups,
    required this.letterMasteryMap,
  });

  @override
  Widget build(BuildContext context) {
    final group = letterGroups[groupIdx];
    final name = letterGroupNames[groupIdx];
    final mastered = group.where((g) => (letterMasteryMap[g] ?? 0) > 0).length;

    // Unlock hint: show how many letters of previous group to complete
    String? hint;
    if (isLocked && groupIdx > 0) {
      final prev = letterGroups[groupIdx - 1];
      final needed = (prev.length * 0.5).ceil();
      final startedInPrev = prev.where((g) => (letterMasteryMap[g] ?? 0) > 0).length;
      final remaining = needed - startedInPrev;
      if (remaining > 0) {
        hint = 'Complétez encore $remaining lettre${remaining > 1 ? 's' : ''} du groupe précédent';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.08)
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock_outline : Icons.lock_open_rounded,
            size: 16,
            color: isLocked ? Colors.grey : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Groupe ${groupIdx + 1} — $name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLocked ? Colors.grey : AppColors.primary,
                  ),
                ),
                if (hint != null)
                  Text(hint, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (!isLocked)
            Text(
              '$mastered/${group.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: mastered == group.length ? AppColors.success : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitProgressTile extends StatelessWidget {
  final UnitProgress unitProgress;
  final String enrollmentId;
  final bool isLocked;

  const _UnitProgressTile({
    required this.unitProgress,
    required this.enrollmentId,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final unit = unitProgress.unit;
    final pct = unitProgress.completionPct;
    final isComplete = pct >= 100;
    final familyIdx = glyphToFamilyIndex[unit.titleAr];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isLocked ? Colors.grey.shade100 : null,
      child: InkWell(
        onTap: isLocked
            ? null
            : () => context.push('/student/curriculum/$enrollmentId/unit/${unit.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isLocked ? 0.45 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Family color dot + number badge / lock icon
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.shade300
                            : isComplete
                                ? AppColors.success
                                : AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isLocked
                            ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                            : isComplete
                                ? const Icon(Icons.check, color: Colors.white, size: 22)
                                : Text(
                                    '${unit.number}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                      ),
                    ),
                    if (familyIdx != null && !isLocked) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: letterFamilies[familyIdx].color,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.titleFr ?? unit.titleAr,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isLocked ? Colors.grey : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          unit.titleAr,
                          style: TextStyle(
                              color: isLocked ? Colors.grey : AppColors.primary,
                              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                              fontSize: 16),
                        ),
                      ),
                      if (!isLocked) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: isComplete ? AppColors.success : AppColors.accent,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${unitProgress.completedItems}/${unitProgress.totalItems}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

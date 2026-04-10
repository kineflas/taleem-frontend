import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../../autonomous_learning/providers/learning_provider.dart';

// Export convenience providers for Hifz features
// These are thin wrappers around the core learning providers

/// Get all Hifz goals for the current student
final hifzGoalsProvider = FutureProvider<List<HifzGoalModel>>((ref) {
  return ref.read(learningApiProvider).fetchHifzGoals();
});

/// Get a specific Hifz goal by ID
final hifzGoalDetailProvider = FutureProvider.family<HifzGoalModel, String>(
  (ref, goalId) {
    return ref.read(learningApiProvider).fetchHifzGoalDetail(goalId);
  },
);

/// Get verses due for review today
final hifzDueVersesProvider = FutureProvider<List<VerseProgressModel>>((ref) {
  return ref.read(learningApiProvider).fetchDueVerses();
});

/// Get student XP, level, and badges
final hifzStudentXPProvider = FutureProvider<StudentXPModel>((ref) {
  return ref.read(learningApiProvider).fetchStudentXP();
});

/// Get heatmap for a specific surah
final hifzSurahHeatmapProvider = FutureProvider.family<SurahHeatmapModel, int>(
  (ref, surah) {
    return ref.read(learningApiProvider).fetchSurahHeatmap(surah);
  },
);

/// Get available reciters
final hifzRecitersProvider = FutureProvider<List<ReciterModel>>((ref) {
  return ref.read(learningApiProvider).fetchReciters();
});

// Count of verses due for revision today
final hifzDueVersesCountProvider = FutureProvider<int>((ref) async {
  final verses = await ref.read(learningApiProvider).fetchDueVerses();
  final now = DateTime.now();
  return verses
      .where((v) {
        final nextReview = DateTime.parse(v.nextReviewDate);
        return nextReview.isBefore(now.add(const Duration(days: 1)));
      })
      .length;
});

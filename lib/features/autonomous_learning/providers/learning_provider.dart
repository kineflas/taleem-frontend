import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_models.dart';

/// Mock API provider for learning features
/// In production, this would call actual backend endpoints via HTTP client
final learningApiProvider = Provider((ref) {
  return LearningApiService();
});

class LearningApiService {
  /// Fetch all words for a given module
  Future<List<LearningWord>> getModuleWords(int moduleNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  /// Fetch due cards for today (Leitner box system)
  Future<List<LeitnerCard>> getDueCards() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  /// Submit exercise result and update Leitner card
  Future<void> submitExerciseResult(ExerciseResult result) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Fetch module progress
  Future<ModuleProgress> getModuleProgress(int moduleNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ModuleProgress(
      moduleNumber: moduleNumber,
      percentComplete: 0,
      currentPhase: 0,
      masteryLevel: 0,
      masteredCount: 0,
      totalCount: 50,
      accuracy: 0,
      leitnerDistribution: {},
    );
  }

  /// Start a new learning session
  Future<LearningSession> startSession(
    int moduleNumber,
    int phase,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return LearningSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      studentId: 'student_1',
      moduleNumber: moduleNumber,
      phase: phase,
      startedAt: DateTime.now(),
      totalCards: 10,
      correctAnswers: 0,
      accuracy: 0,
      cardIds: [],
    );
  }

  // ============ HIFZ MASTER API ============

  Future<List<HifzGoalModel>> fetchHifzGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  Future<HifzGoalModel> fetchHifzGoalDetail(String goalId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return HifzGoalModel(
      id: goalId,
      surahNumber: 1,
      mode: 'QUANTITATIVE',
      versesPerDay: 5,
      reciterFolder: 'Alafasy_128kbps',
      totalVerses: 7,
      versesMemorized: 0,
      calculatedDailyTarget: 5,
      isCompleted: false,
    );
  }

  Future<List<VerseProgressModel>> fetchDueVerses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  Future<StudentXPModel> fetchStudentXP() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const StudentXPModel(
      totalXp: 0,
      level: StudentLevel.debutant,
      badges: [],
    );
  }

  Future<SurahHeatmapModel> fetchSurahHeatmap(int surah) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return SurahHeatmapModel(surahNumber: surah, verses: []);
  }

  Future<List<ReciterModel>> fetchReciters() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      const ReciterModel(id: 'Alafasy_128kbps', nameEn: 'Mishary Alafasy', nameAr: 'مشاري العفاسي'),
      const ReciterModel(id: 'Husary_128kbps', nameEn: 'Mahmoud Al-Husary', nameAr: 'محمود الحصري'),
      const ReciterModel(id: 'Abdul_Basit_Murattal_192kbps', nameEn: 'Abdul Basit', nameAr: 'عبد الباسط'),
      const ReciterModel(id: 'Menshawi_16kbps', nameEn: 'Mohamed Menshawi', nameAr: 'محمد المنشاوي'),
      const ReciterModel(id: 'Muhammad_Jibreel_128kbps', nameEn: 'Muhammad Jibreel', nameAr: 'محمد جبريل'),
    ];
  }
}

/// Provider: All words for a module
final wordsProvider = FutureProvider.family<List<LearningWord>, int>((ref, moduleNumber) async {
  final api = ref.watch(learningApiProvider);
  return api.getModuleWords(moduleNumber);
});

/// Provider: Due cards for Leitner review
final dueCardsProvider = FutureProvider<List<LeitnerCard>>((ref) async {
  final api = ref.watch(learningApiProvider);
  return api.getDueCards();
});

/// Provider: Module progress for all 5 modules
final moduleProgressProvider = FutureProvider<Map<int, dynamic>>((ref) async {
  final api = ref.watch(learningApiProvider);
  final progressMap = <int, dynamic>{};

  for (int i = 1; i <= 5; i++) {
    final progress = await api.getModuleProgress(i);
    progressMap[i] = {
      'percentComplete': progress.percentComplete,
      'currentPhase': progress.currentPhase,
      'masteryLevel': progress.masteryLevel,
      'masteredCount': progress.masteredCount,
      'totalCount': progress.totalCount,
      'accuracy': progress.accuracy,
      'leitnerDistribution': progress.leitnerDistribution,
    };
  }

  return progressMap;
});

/// Provider: Current learning session
final currentSessionProvider = StateProvider<LearningSession?>((ref) {
  return null;
});

/// Provider: Exercise results for current session
final sessionResultsProvider = StateProvider<List<ExerciseResult>>((ref) {
  return [];
});

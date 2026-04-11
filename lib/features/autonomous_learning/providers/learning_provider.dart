import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

/// API provider for learning features — uses Dio for real HTTP calls
final learningApiProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return LearningApiService(dio);
});

class LearningApiService {
  final Dio _dio;

  LearningApiService(this._dio);

  /// Fetch all words for a given module
  Future<List<LearningWord>> getModuleWords(int moduleNumber) async {
    // TODO: wire to real endpoint when backend is ready
    await Future.delayed(const Duration(milliseconds: 300));
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
  Future<LearningSession> startSession(int moduleNumber, int phase) async {
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

  // ============ HIFZ MASTER API (real HTTP calls) ============

  Future<List<HifzGoalModel>> fetchHifzGoals() async {
    try {
      final response = await _dio.get(ApiConstants.studentHifzGoals);
      final data = response.data as List<dynamic>;
      return data.map((j) => HifzGoalModel.fromJson(Map<String, dynamic>.from(j))).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) rethrow;
      return [];
    }
  }

  Future<HifzGoalModel> createHifzGoal({
    required int surahNumber,
    required String mode,
    int? versesPerDay,
    String? targetDate,
    String? reciterId,
  }) async {
    final response = await _dio.post(
      ApiConstants.studentHifzGoals,
      data: {
        'surah_number': surahNumber,
        'mode': mode,
        if (versesPerDay != null) 'verses_per_day': versesPerDay,
        if (targetDate != null) 'target_date': targetDate,
        if (reciterId != null) 'reciter_id': reciterId,
      },
    );
    return HifzGoalModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> deleteHifzGoal(String goalId) async {
    await _dio.delete('${ApiConstants.studentHifzGoals}/$goalId');
  }

  Future<HifzGoalModel> fetchHifzGoalDetail(String goalId) async {
    final response = await _dio.get('${ApiConstants.studentHifzGoals}/$goalId');
    return HifzGoalModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<VerseProgressModel>> fetchDueVerses() async {
    try {
      final response = await _dio.get(ApiConstants.studentHifzVersesDue);
      final data = response.data as List<dynamic>;
      return data.map((j) => VerseProgressModel.fromJson(Map<String, dynamic>.from(j))).toList();
    } on DioException {
      return [];
    }
  }

  Future<StudentXPModel> fetchStudentXP() async {
    try {
      final response = await _dio.get(ApiConstants.studentHifzXp);
      return StudentXPModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException {
      return const StudentXPModel(
        totalXp: 0,
        level: StudentLevel.debutant,
        badges: [],
      );
    }
  }

  Future<SurahHeatmapModel> fetchSurahHeatmap(int surah) async {
    try {
      final response = await _dio.get('/student/hifz/heatmap/$surah');
      return SurahHeatmapModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException {
      return SurahHeatmapModel(surahNumber: surah, verses: []);
    }
  }

  Future<List<ReciterModel>> fetchReciters() async {
    try {
      final response = await _dio.get(ApiConstants.studentHifzReciters);
      final data = response.data as List<dynamic>;
      return data.map((j) => ReciterModel.fromJson(Map<String, dynamic>.from(j))).toList();
    } on DioException {
      return [
        const ReciterModel(id: 'Alafasy_128kbps', nameEn: 'Mishary Alafasy', nameAr: 'مشاري العفاسي'),
        const ReciterModel(id: 'Al-Husary_128kbps', nameEn: 'Ali Al-Husary', nameAr: 'علي الحصري'),
        const ReciterModel(id: 'Abdul_Basit_128kbps', nameEn: 'Abdul Basit', nameAr: 'عبد الباسط'),
      ];
    }
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

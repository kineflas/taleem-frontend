import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_models.dart';
import '../data/quran_vocabulary_data.dart';
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

  // ── Vocabulary / Module words ──────────────────────────────────────────────

  /// Fetch all words for a given module.
  /// Tente l'API backend → fallback sur le dataset local.
  Future<List<LearningWord>> getModuleWords(int moduleNumber) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.studentLearnModules}/$moduleNumber/words',
      );
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        return data
            .map((j) => LearningWord.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      }
    } on DioException {
      // Pas de backend encore — utiliser les données locales
    }
    // Fallback : dataset local
    return _localWordsToLearningWords(wordsForModule(moduleNumber));
  }

  List<LearningWord> _localWordsToLearningWords(List<QuranWord> words) {
    return words.map((w) => LearningWord(
      id: w.id.toString(),
      arabicWord: w.arabicWord,
      meaning: w.meaningFr,
      transliteration: w.transliteration,
      audioUrl: w.audioUrl,
      moduleNumber: w.moduleNumber,
      frequency: w.frequency,
    )).toList();
  }

  // ── Leitner SRS (état local — backend non encore implémenté) ──────────────

  /// Retourne les cards dues aujourd'hui selon le SRS local.
  Future<List<LeitnerCard>> getDueCards() async {
    try {
      final response = await _dio.get(ApiConstants.studentLearnSrsDue);
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        return data
            .map((j) => LeitnerCard.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      }
    } on DioException {
      // Pas de backend — retourner toutes les cards de la boite 1
    }
    // Fallback : toutes les words module 1 en box level 1 (nouvelles)
    return wordsForModule(1).take(10).map((w) => LeitnerCard(
      id: 'card_${w.id}',
      wordId: w.id.toString(),
      boxLevel: 1,
      lastReviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewCount: 0,
      isCorrect: false,
      nextReviewAt: DateTime.now(),
    )).toList();
  }

  /// Soumet le résultat d'un exercice et met à jour la box Leitner.
  Future<void> submitExerciseResult(ExerciseResult result) async {
    try {
      await _dio.post(
        '${ApiConstants.studentLearnModules}/${result.sessionId}/attempt',
        data: result.toJson(),
      );
    } on DioException {
      // Silently fail — état local géré côté widget
    }
  }

  // ── Module progress ────────────────────────────────────────────────────────

  /// Fetch module progress, avec fallback zéro.
  Future<ModuleProgress> getModuleProgress(int moduleNumber) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.studentLearnModules}/$moduleNumber',
      );
      return ModuleProgress.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException {
      // Calcul local : total = taille du dataset
      final total = wordsForModule(moduleNumber).length;
      return ModuleProgress(
        moduleNumber: moduleNumber,
        percentComplete: 0,
        currentPhase: 1,
        masteryLevel: 0,
        masteredCount: 0,
        totalCount: total > 0 ? total : 50,
        accuracy: 0,
        leitnerDistribution: {'1': total, '2': 0, '3': 0, '4': 0, '5': 0},
      );
    }
  }

  /// Start a new learning session
  Future<LearningSession> startSession(int moduleNumber, int phase) async {
    try {
      final response = await _dio.post(
        ApiConstants.studentLearnModules,
        data: {'module_number': moduleNumber, 'phase': phase},
      );
      return LearningSession.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException {
      return LearningSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        studentId: 'student_1',
        moduleNumber: moduleNumber,
        phase: phase,
        startedAt: DateTime.now(),
        totalCards: wordsForModule(moduleNumber).length,
        correctAnswers: 0,
        accuracy: 0,
        cardIds: [],
      );
    }
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
        const ReciterModel(id: 'Husary_128kbps', nameEn: 'Mahmoud Al-Husary', nameAr: 'محمود خليل الحصري'),
        const ReciterModel(id: 'Abdul_Basit_Murattal_192kbps', nameEn: 'Abdul Basit Murattal', nameAr: 'عبد الباسط عبد الصمد'),
      ];
    }
  }
}

/// Provider: All words for a module (API + fallback local)
final wordsProvider = FutureProvider.family<List<LearningWord>, int>((ref, moduleNumber) async {
  final api = ref.watch(learningApiProvider);
  return api.getModuleWords(moduleNumber);
});

/// Provider synchrone : vocabulaire local du module (toujours disponible)
final localWordsProvider = Provider.family<List<QuranWord>, int>((ref, moduleNumber) {
  return wordsForModule(moduleNumber);
});

/// Provider : toutes les racines pour le module 4
final localRootsProvider = Provider<List<ArabicRoot>>((ref) => kModule4Roots);

/// Provider : tous les blocs sémantiques pour le module 3
final localChunksProvider = Provider<List<QuranChunk>>((ref) => kModule3Chunks);

/// Provider : versets du module 5
final localVersesProvider = Provider<List<Map<String, dynamic>>>((ref) => kModule5Verses);

/// Provider : mots du module 2 (particules spatiales)
final localSpatialWordsProvider = Provider<List<QuranWord>>((ref) => kModule2Words);

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

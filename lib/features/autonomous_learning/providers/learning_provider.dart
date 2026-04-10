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

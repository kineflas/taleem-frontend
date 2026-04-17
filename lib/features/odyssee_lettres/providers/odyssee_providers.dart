import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/odyssee_models.dart';

// ── API Service ─────────────────────────────────────────────────────────────

class OdysseeLettresApi {
  final Dio _client;
  OdysseeLettresApi(this._client);

  Future<List<OdysseeLessonListItem>> fetchLessons() async {
    final res = await _client.get('/api/odyssee/lessons');
    return (res.data as List)
        .map((j) => OdysseeLessonListItem.fromJson(j))
        .toList();
  }

  Future<OdysseeLessonContent> fetchLesson(int lessonNumber) async {
    final res = await _client.get('/api/odyssee/lessons/$lessonNumber');
    return OdysseeLessonContent.fromJson(res.data);
  }

  Future<OdysseeLessonProgress> fetchProgress(int lessonNumber) async {
    final res = await _client.get('/api/odyssee/lessons/$lessonNumber/progress');
    return OdysseeLessonProgress.fromJson(res.data);
  }

  Future<void> updateProgress(
    int lessonNumber,
    String step, {
    double value = 1.0,
  }) async {
    await _client.post(
      '/api/odyssee/lessons/$lessonNumber/progress',
      data: {'step': step, 'value': value},
    );
  }

  Future<OdysseeQuizResult> submitQuiz(
    int lessonNumber, {
    required List<Map<String, dynamic>> answers,
    int timeMs = 0,
  }) async {
    final res = await _client.post(
      '/api/odyssee/lessons/$lessonNumber/quiz/submit',
      data: {'answers': answers, 'time_ms': timeMs},
    );
    return OdysseeQuizResult.fromJson(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchFlashcards() async {
    final res = await _client.get('/api/odyssee/flashcards');
    return (res.data as List)
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  Future<OdysseeStats> fetchStats() async {
    final res = await _client.get('/api/odyssee/stats');
    return OdysseeStats.fromJson(res.data);
  }

  Future<List<LetterData>> fetchAllLetters() async {
    final res = await _client.get('/api/odyssee/letters');
    return (res.data as List)
        .map((j) => LetterData.fromJson(j))
        .toList();
  }

  Future<LetterData> fetchLetter(String letterId) async {
    final res = await _client.get('/api/odyssee/letters/$letterId');
    return LetterData.fromJson(res.data);
  }

  Future<OdysseeBossQuizContent> fetchBossQuiz(int phaseNumber) async {
    final res = await _client.get('/api/odyssee/phases/$phaseNumber/quiz');
    return OdysseeBossQuizContent.fromJson(res.data);
  }

  Future<OdysseeBossQuizResult> submitBossQuiz(
    int phaseNumber, {
    required List<Map<String, dynamic>> answers,
    int timeMs = 0,
  }) async {
    final res = await _client.post(
      '/api/odyssee/phases/$phaseNumber/quiz/submit',
      data: {'answers': answers, 'time_ms': timeMs},
    );
    return OdysseeBossQuizResult.fromJson(res.data);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final odysseeLettresApiProvider = Provider<OdysseeLettresApi>(
  (ref) => OdysseeLettresApi(ref.read(dioProvider)),
);

final odysseeLessonsProvider =
    FutureProvider.autoDispose<List<OdysseeLessonListItem>>((ref) {
  return ref.read(odysseeLettresApiProvider).fetchLessons();
});

final odysseeLessonProvider =
    FutureProvider.family<OdysseeLessonContent, int>((ref, lessonNumber) {
  return ref.read(odysseeLettresApiProvider).fetchLesson(lessonNumber);
});

final odysseeProgressProvider =
    FutureProvider.family<OdysseeLessonProgress, int>((ref, lessonNumber) {
  return ref.read(odysseeLettresApiProvider).fetchProgress(lessonNumber);
});

final odysseeStatsProvider = FutureProvider.autoDispose<OdysseeStats>((ref) {
  return ref.read(odysseeLettresApiProvider).fetchStats();
});

final odysseeAllLettersProvider =
    FutureProvider.autoDispose<List<LetterData>>((ref) {
  return ref.read(odysseeLettresApiProvider).fetchAllLetters();
});

final odysseeBossQuizProvider =
    FutureProvider.family<OdysseeBossQuizContent, int>((ref, phaseNumber) {
  return ref.read(odysseeLettresApiProvider).fetchBossQuiz(phaseNumber);
});

// ── Phase metadata ─────────────────────────────────────────────────────────

/// Lesson → Phase mapping
const lessonToPhase = <int, int>{
  1: 1, 2: 1, 3: 1, 4: 1, 5: 1,
  6: 2, 7: 2, 8: 2, 9: 2, 10: 2,
  11: 3, 12: 3, 13: 3, 14: 3, 15: 3,
  16: 4, 17: 4, 18: 4,
};

/// Phase theme data
class PhaseTheme {
  final String name;
  final String icon;
  final int color; // hex color
  final String description;

  const PhaseTheme(this.name, this.icon, this.color, this.description);
}

const phaseThemes = <int, PhaseTheme>{
  1: PhaseTheme(
    'Les Familières',
    '🏠',
    0xFF2A9D8F,
    'Sons déjà connus des francophones',
  ),
  2: PhaseTheme(
    'Les Nouvelles',
    '🌟',
    0xFFE76F51,
    'Sons nouveaux mais accessibles',
  ),
  3: PhaseTheme(
    'Les Profondes',
    '🏔️',
    0xFF264653,
    'Sons gutturaux et emphatiques',
  ),
  4: PhaseTheme(
    'Le Grand Voyage',
    '🚀',
    0xFF6C3483,
    'Révision finale et lecture',
  ),
};

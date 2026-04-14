import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/lesson_models.dart';

// ── API Service ───────────────────────────────────────────────────────────

class MedineLessonApi {
  final Dio _client;
  MedineLessonApi(this._client);

  /// Fetch all 23 lessons (list with unlock/star status)
  Future<List<LessonListItem>> fetchLessons() async {
    final res = await _client.get(ApiConstants.lessons);
    return (res.data as List)
        .map((j) => LessonListItem.fromJson(j))
        .toList();
  }

  /// Fetch full detail for a single lesson
  Future<LessonDetail> fetchLessonDetail(int lessonNumber) async {
    final res = await _client.get(ApiConstants.lessonDetail(lessonNumber));
    return LessonDetail.fromJson(res.data);
  }

  /// Update progress on a specific segment
  Future<Map<String, dynamic>> updateProgress(
    int lessonNumber, {
    required String segment,
    required double value,
  }) async {
    final res = await _client.post(
      ApiConstants.lessonProgress(lessonNumber),
      data: {'segment': segment, 'value': value},
    );
    return Map<String, dynamic>.from(res.data);
  }

  /// Submit quiz answers
  Future<QuizResult> submitQuiz(
    int lessonNumber, {
    required List<Map<String, dynamic>> answers,
    int timeMs = 0,
  }) async {
    final res = await _client.post(
      ApiConstants.lessonQuizSubmit(lessonNumber),
      data: {'answers': answers, 'time_ms': timeMs},
    );
    return QuizResult.fromJson(res.data);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final medineLessonApiProvider = Provider<MedineLessonApi>(
  (ref) => MedineLessonApi(ref.read(dioProvider)),
);

/// All 23 lessons (list view)
final medineLessonsProvider = FutureProvider<List<LessonListItem>>((ref) {
  return ref.read(medineLessonApiProvider).fetchLessons();
});

/// Lesson detail by number
final medineLessonDetailProvider =
    FutureProvider.family<LessonDetail, int>((ref, lessonNumber) {
  return ref.read(medineLessonApiProvider).fetchLessonDetail(lessonNumber);
});

/// Part number mapping (mirrors backend LESSON_TO_PART)
const lessonToPart = <int, int>{
  1: 1, 2: 1, 3: 1, 4: 1,
  5: 2, 6: 2, 7: 2, 8: 2,
  9: 3, 10: 3, 11: 3,
  12: 4, 13: 4, 14: 4, 15: 4,
  16: 5, 17: 5, 18: 5,
  19: 6, 20: 6, 21: 6,
  22: 7, 23: 7,
};

/// Part titles in French
const partTitles = <int, String>{
  1: 'Les Fondations',
  2: 'Les Pronoms Démonstratifs',
  3: "L'Annexion (Idafa)",
  4: 'Les Adjectifs et Prépositions',
  5: 'Le Verbe et ses Formes',
  6: 'Le Pluriel et les Diptotes',
  7: 'La Maîtrise du Présent et du Pluriel',
};

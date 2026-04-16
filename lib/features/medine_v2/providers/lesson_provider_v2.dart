import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/lesson_models_v2.dart';

// ── API Service ─────────────────────────────────────────────────────────────

class MedineV2Api {
  final Dio _client;
  MedineV2Api(this._client);

  Future<List<LessonListItemV2>> fetchLessons() async {
    final res = await _client.get('/api/v2/lessons');
    return (res.data as List)
        .map((j) => LessonListItemV2.fromJson(j))
        .toList();
  }

  Future<LessonContentV2> fetchLesson(int lessonNumber) async {
    final res = await _client.get('/api/v2/lessons/$lessonNumber');
    return LessonContentV2.fromJson(res.data);
  }

  Future<void> updateProgress(int lessonNumber, String step, {double value = 1.0}) async {
    await _client.post(
      '/api/v2/lessons/$lessonNumber/progress',
      data: {'step': step, 'value': value},
    );
  }

  Future<QuizResultV2> submitQuiz(
    int lessonNumber, {
    required List<Map<String, dynamic>> answers,
    int timeMs = 0,
  }) async {
    final res = await _client.post(
      '/api/v2/lessons/$lessonNumber/quiz/submit',
      data: {'answers': answers, 'time_ms': timeMs},
    );
    return QuizResultV2.fromJson(res.data);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final medineV2ApiProvider = Provider<MedineV2Api>(
  (ref) => MedineV2Api(ref.read(dioProvider)),
);

final medineV2LessonsProvider = FutureProvider.autoDispose<List<LessonListItemV2>>((ref) {
  return ref.read(medineV2ApiProvider).fetchLessons();
});

final medineV2LessonProvider =
    FutureProvider.family<LessonContentV2, int>((ref, lessonNumber) {
  return ref.read(medineV2ApiProvider).fetchLesson(lessonNumber);
});

/// Part number mapping
const lessonToPartV2 = <int, int>{
  1: 1, 2: 1, 3: 1, 4: 1,
  5: 2, 6: 2, 7: 2, 8: 2,
  9: 3, 10: 3, 11: 3,
  12: 4, 13: 4, 14: 4, 15: 4,
  16: 5, 17: 5, 18: 5,
  19: 6, 20: 6, 21: 6,
  22: 7, 23: 7,
};

/// Part theme data
class PartTheme {
  final String name;
  final String icon;
  final int color; // hex color

  const PartTheme(this.name, this.icon, this.color);
}

const partThemes = <int, PartTheme>{
  1: PartTheme('Le Camp des Novices', '🏕️', 0xFFE76F51),
  2: PartTheme("L'Oasis Marchande", '🌴', 0xFF2A9D8F),
  3: PartTheme('La Bibliothèque Secrète', '📚', 0xFF264653),
  4: PartTheme('La Forteresse', '🏰', 0xFF6C3483),
  5: PartTheme('Le Grand Bazar', '🪔', 0xFFF4A261),
  6: PartTheme("L'Observatoire", '🔭', 0xFF1D3557),
  7: PartTheme('Les Portes de Médine', '🕌', 0xFF1B4332),
};

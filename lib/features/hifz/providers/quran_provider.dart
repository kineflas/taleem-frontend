import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Fetches all verse texts for a given surah from alquran.cloud (Hafs narration).
/// Returns Map<verseNumber, arabicText> — cached by Riverpod per surahNumber.
///
/// API: GET https://api.alquran.cloud/v1/surah/{surahNumber}/ar.alafasy
final quranSurahProvider =
    FutureProvider.family<Map<int, String>, int>((ref, surahNumber) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final response = await dio.get(
    'https://api.alquran.cloud/v1/surah/$surahNumber/ar.alafasy',
  );

  final ayahs = response.data['data']['ayahs'] as List<dynamic>;
  final map = <int, String>{};
  for (final a in ayahs) {
    final num = a['numberInSurah'] as int;
    final text = (a['text'] as String).trim();
    map[num] = text;
  }
  return map;
});

/// Fetches a single verse text.
/// Uses [quranSurahProvider] internally so the full surah is cached.
final quranVerseProvider =
    FutureProvider.family<String, ({int surah, int verse})>((ref, params) async {
  final surahMap = await ref.watch(
    quranSurahProvider(params.surah).future,
  );
  return surahMap[params.verse] ?? '';
});

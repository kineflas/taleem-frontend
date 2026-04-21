import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/player_models.dart';
import '../services/quran_audio_service.dart';

// ── Service audio (singleton via ChangeNotifierProvider) ────────

final quranAudioServiceProvider =
    ChangeNotifierProvider<QuranAudioService>((ref) {
  final service = QuranAudioService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Liste des 114 sourates ─────────────────────────────────────

final surahListProvider =
    FutureProvider<List<SurahInfo>>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth?.accessToken == null) return [];

  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {'Authorization': 'Bearer ${auth!.accessToken}'},
  ));

  final response = await dio.get('/quran/surahs');
  final list = response.data as List<dynamic>;
  return list.map((e) => SurahInfo.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Texte arabe d'une sourate (via alquran.cloud) ──────────────

final surahTextProvider =
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
    map[a['numberInSurah'] as int] = (a['text'] as String).trim();
  }
  return map;
});

// ── Traduction française ───────────────────────────────────────

final surahTranslationProvider =
    FutureProvider.family<Map<int, String>, int>((ref, surahNumber) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
  ));
  final response = await dio.get(
    'https://api.alquran.cloud/v1/surah/$surahNumber/fr.hamidullah',
  );
  final ayahs = response.data['data']['ayahs'] as List<dynamic>;
  final map = <int, String>{};
  for (final a in ayahs) {
    map[a['numberInSurah'] as int] = (a['text'] as String).trim();
  }
  return map;
});

// ── Playlist de révision SRS ───────────────────────────────────

final revisionPlaylistProvider =
    FutureProvider<List<RevisionVerse>>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth?.accessToken == null) return [];

  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {'Authorization': 'Bearer ${auth!.accessToken}'},
  ));

  final response = await dio.get('/student/hifz/v2/revision/audio-playlist');
  final list = response.data['verses'] as List<dynamic>;
  return list
      .map((e) => RevisionVerse.fromJson(e as Map<String, dynamic>))
      .toList();
});

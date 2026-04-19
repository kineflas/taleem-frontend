/// Providers Riverpod pour Hifz V2 — state management du Wird.
///
/// Expose :
///  - hifzV2ServiceProvider  → instance du service API
///  - wirdTodayProvider      → Wird du jour (FutureProvider, auto-refresh)
///  - surahContentProvider   → Contenu enrichi d'une sourate (family)
///  - journeyMapProvider     → Carte du voyage
///  - wirdSessionNotifier    → État mutable de la session en cours
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/hifz_v2_service.dart';
import '../models/wird_models.dart';
import '../services/asr_service.dart';

// ── Service Provider ────────────────────────────────────────────────

final hifzV2ServiceProvider = Provider<HifzV2Service>((ref) {
  final dio = ref.watch(dioProvider);
  return HifzV2Service(dio);
});

// ── ASR Service Provider ────────────────────────────────────────────

final asrServiceProvider = Provider<AsrService>((ref) {
  final service = AsrService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Sourates suggérées (Ikhtiar) ────────────────────────────────────

final suggestedSurahsProvider = FutureProvider<SuggestedSurahsResponse>((ref) {
  return ref.read(hifzV2ServiceProvider).fetchSuggestedSurahs();
});

// ── Wird du jour ────────────────────────────────────────────────────

/// Provider pour le Wird du jour. Peut être paramétré par sourate.
final wirdTodayProvider = FutureProvider<WirdTodayResponse>((ref) {
  return ref.read(hifzV2ServiceProvider).fetchWirdToday();
});

/// Provider paramétré pour le Wird d'une sourate spécifique.
final wirdForSurahProvider =
    FutureProvider.family<WirdTodayResponse, int>((ref, surahNumber) {
  return ref.read(hifzV2ServiceProvider).fetchWirdToday(surahNumber: surahNumber);
});

// ── Contenu enrichi d'une sourate (par numéro) ─────────────────────

final surahContentProvider =
    FutureProvider.family<EnrichedSurahResponse, int>((ref, surahNumber) {
  return ref.read(hifzV2ServiceProvider).fetchSurahContent(surahNumber);
});

// ── Carte du voyage ─────────────────────────────────────────────────

final journeyMapProvider = FutureProvider<JourneyMapResponse>((ref) {
  return ref.read(hifzV2ServiceProvider).fetchJourneyMap();
});

// ── Progression d'un verset ─────────────────────────────────────────

final verseProgressProvider = FutureProvider.family<VerseProgressV2Response,
    ({int surah, int verse})>((ref, params) {
  return ref
      .read(hifzV2ServiceProvider)
      .fetchVerseProgress(params.surah, params.verse);
});

// ── Session Wird active (état mutable) ──────────────────────────────

class WirdSessionState {
  WirdSessionState({
    this.wirdSessionId,
    this.isStarted = false,
    this.currentBlocIndex = 0,
    this.currentVerseIndex = 0,
    this.totalExercises = 0,
    this.correctExercises = 0,
    this.totalXpEarned = 0,
    this.startedAt,
  });

  final String? wirdSessionId;
  final bool isStarted;
  final int currentBlocIndex;
  final int currentVerseIndex;
  final int totalExercises;
  final int correctExercises;
  final int totalXpEarned;
  final DateTime? startedAt;

  WirdSessionState copyWith({
    String? wirdSessionId,
    bool? isStarted,
    int? currentBlocIndex,
    int? currentVerseIndex,
    int? totalExercises,
    int? correctExercises,
    int? totalXpEarned,
    DateTime? startedAt,
  }) =>
      WirdSessionState(
        wirdSessionId: wirdSessionId ?? this.wirdSessionId,
        isStarted: isStarted ?? this.isStarted,
        currentBlocIndex: currentBlocIndex ?? this.currentBlocIndex,
        currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
        totalExercises: totalExercises ?? this.totalExercises,
        correctExercises: correctExercises ?? this.correctExercises,
        totalXpEarned: totalXpEarned ?? this.totalXpEarned,
        startedAt: startedAt ?? this.startedAt,
      );
}

class WirdSessionNotifier extends StateNotifier<WirdSessionState> {
  WirdSessionNotifier(this._service) : super(WirdSessionState());

  final HifzV2Service _service;

  /// Démarre le Wird du jour. Si [surahNumber] est fourni, cible cette sourate.
  Future<void> start({int? surahNumber}) async {
    final id = await _service.startWird(surahNumber: surahNumber);
    state = state.copyWith(
      wirdSessionId: id,
      isStarted: true,
      startedAt: DateTime.now(),
    );
  }

  /// Soumet un résultat d'exercice et met à jour les compteurs.
  Future<ExerciseAnswerResponse> submitExercise({
    required int surahNumber,
    required int verseNumber,
    required String exerciseType,
    required bool isCorrect,
    int? responseTimeMs,
  }) async {
    final result = await _service.submitExerciseAnswer(
      wirdSessionId: state.wirdSessionId,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      exerciseType: exerciseType,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );

    state = state.copyWith(
      totalExercises: state.totalExercises + 1,
      correctExercises:
          state.correctExercises + (isCorrect ? 1 : 0),
      totalXpEarned: state.totalXpEarned + result.xpEarned,
    );

    return result;
  }

  /// Soumet un résultat d'étape.
  Future<StepResultResponse> submitStep({
    required int surahNumber,
    required int verseNumber,
    required String step,
    required int score,
    required int durationSeconds,
  }) async {
    final result = await _service.submitStepResult(
      wirdSessionId: state.wirdSessionId,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      step: step,
      score: score,
      durationSeconds: durationSeconds,
    );

    state = state.copyWith(
      totalXpEarned: state.totalXpEarned + result.xpEarned,
    );

    return result;
  }

  /// Avance au verset suivant dans le bloc.
  void nextVerse() {
    state = state.copyWith(
      currentVerseIndex: state.currentVerseIndex + 1,
    );
  }

  /// Avance au bloc suivant.
  void nextBloc() {
    state = state.copyWith(
      currentBlocIndex: state.currentBlocIndex + 1,
      currentVerseIndex: 0,
    );
  }

  /// Termine le Wird.
  Future<void> complete() async {
    if (state.wirdSessionId == null) return;

    final duration = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inSeconds
        : 0;

    await _service.completeWird(
      wirdId: state.wirdSessionId!,
      durationSeconds: duration,
      totalExercises: state.totalExercises,
      correctExercises: state.correctExercises,
    );
  }

  /// Réinitialise l'état.
  void reset() {
    state = WirdSessionState();
  }
}

final wirdSessionProvider =
    StateNotifierProvider<WirdSessionNotifier, WirdSessionState>((ref) {
  final service = ref.watch(hifzV2ServiceProvider);
  return WirdSessionNotifier(service);
});

/// Service API pour Hifz V2 — appels HTTP vers le backend.
///
/// Utilise Dio (via dioProvider) pour tous les appels réseau.
/// Gère : Wird, exercices, contenu enrichi, carte du voyage.
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/wird_models.dart';

class HifzV2Service {
  HifzV2Service(this._dio);
  final Dio _dio;

  // ── Wird ─────────────────────────────────────────────────────────

  /// Récupère le Wird du jour (composé par l'algorithme backend).
  Future<WirdTodayResponse> fetchWirdToday() async {
    final response = await _dio.get(ApiConstants.studentHifzWirdToday);
    return WirdTodayResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Démarre (ou reprend) le Wird du jour. Retourne l'ID de session.
  Future<String> startWird() async {
    final response = await _dio.post(ApiConstants.studentHifzWirdStart);
    return response.data['id'] as String;
  }

  /// Termine le Wird.
  Future<void> completeWird({
    required String wirdId,
    required int durationSeconds,
    required int totalExercises,
    required int correctExercises,
  }) async {
    await _dio.patch(
      ApiConstants.studentHifzWirdComplete(wirdId),
      data: {
        'duration_seconds': durationSeconds,
        'total_exercises': totalExercises,
        'correct_exercises': correctExercises,
      },
    );
  }

  // ── Exercices ────────────────────────────────────────────────────

  /// Soumet une réponse d'exercice. Retourne le delta mastery + XP.
  Future<ExerciseAnswerResponse> submitExerciseAnswer({
    String? wirdSessionId,
    required int surahNumber,
    required int verseNumber,
    required String exerciseType,
    required bool isCorrect,
    int? responseTimeMs,
    int attemptNumber = 1,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      ApiConstants.studentHifzExerciseAnswer,
      data: {
        if (wirdSessionId != null) 'wird_session_id': wirdSessionId,
        'surah_number': surahNumber,
        'verse_number': verseNumber,
        'exercise_type': exerciseType,
        'is_correct': isCorrect,
        if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
        'attempt_number': attemptNumber,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return ExerciseAnswerResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Soumet le résultat d'une étape (NOUR, TIKRAR, TAMRIN, TASMI, NATIJA).
  Future<StepResultResponse> submitStepResult({
    String? wirdSessionId,
    required int surahNumber,
    required int verseNumber,
    required String step,
    required int score,
    required int durationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      ApiConstants.studentHifzStepResult,
      data: {
        if (wirdSessionId != null) 'wird_session_id': wirdSessionId,
        'surah_number': surahNumber,
        'verse_number': verseNumber,
        'step': step,
        'score': score,
        'duration_seconds': durationSeconds,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return StepResultResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── Contenu enrichi ──────────────────────────────────────────────

  /// Récupère le contenu enrichi d'une sourate (texte, traductions, timings).
  Future<EnrichedSurahResponse> fetchSurahContent(int surahNumber) async {
    final response =
        await _dio.get(ApiConstants.studentHifzSurahContent(surahNumber));
    return EnrichedSurahResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── Carte du voyage ──────────────────────────────────────────────

  /// Récupère la carte du voyage (progression par sourate).
  Future<JourneyMapResponse> fetchJourneyMap() async {
    final response = await _dio.get(ApiConstants.studentHifzMap);
    return JourneyMapResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── Progression verset ───────────────────────────────────────────

  /// Récupère la progression V2 d'un verset spécifique.
  Future<VerseProgressV2Response> fetchVerseProgress(
      int surahNumber, int verseNumber) async {
    final response = await _dio.get(
      ApiConstants.studentHifzVerseProgress(surahNumber, verseNumber),
    );
    return VerseProgressV2Response.fromJson(
        response.data as Map<String, dynamic>);
  }
}

// ── Response Models ──────────────────────────────────────────────────

class WirdTodayResponse {
  WirdTodayResponse({
    this.wirdSessionId,
    required this.date,
    required this.blocs,
    required this.estimatedDurationMinutes,
    required this.totalVerses,
    required this.reciterFolder,
    required this.status,
    required this.progressPercent,
  });

  final String? wirdSessionId;
  final String date;
  final List<WirdBlocResponse> blocs;
  final int estimatedDurationMinutes;
  final int totalVerses;
  final String reciterFolder;
  final String status;
  final int progressPercent;

  factory WirdTodayResponse.fromJson(Map<String, dynamic> json) =>
      WirdTodayResponse(
        wirdSessionId: json['wird_session_id'] as String?,
        date: json['date'] as String,
        blocs: (json['blocs'] as List)
            .map((b) =>
                WirdBlocResponse.fromJson(b as Map<String, dynamic>))
            .toList(),
        estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
        totalVerses: json['total_verses'] as int,
        reciterFolder: json['reciter_folder'] as String? ?? 'Alafasy_128kbps',
        status: json['status'] as String? ?? 'NOT_STARTED',
        progressPercent: json['progress_percent'] as int? ?? 0,
      );
}

class WirdBlocResponse {
  WirdBlocResponse({
    required this.blocType,
    required this.labelAr,
    required this.verses,
  });

  final String blocType;
  final String labelAr;
  final List<WirdVerseResponse> verses;

  WirdBloc get bloc {
    switch (blocType) {
      case 'JADID':
        return WirdBloc.jadid;
      case 'QARIB':
        return WirdBloc.qarib;
      case 'BAID':
        return WirdBloc.baid;
      default:
        return WirdBloc.jadid;
    }
  }

  factory WirdBlocResponse.fromJson(Map<String, dynamic> json) =>
      WirdBlocResponse(
        blocType: json['bloc_type'] as String,
        labelAr: json['label_ar'] as String? ?? '',
        verses: (json['verses'] as List)
            .map((v) =>
                WirdVerseResponse.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class WirdVerseResponse {
  WirdVerseResponse({
    required this.surahNumber,
    required this.verseNumber,
    this.textAr = '',
    this.masteryScore = 0,
    this.srsTier = 1,
    this.stars = 0,
  });

  final int surahNumber;
  final int verseNumber;
  final String textAr;
  final int masteryScore;
  final int srsTier;
  final int stars;

  factory WirdVerseResponse.fromJson(Map<String, dynamic> json) =>
      WirdVerseResponse(
        surahNumber: json['surah_number'] as int,
        verseNumber: json['verse_number'] as int,
        textAr: json['text_ar'] as String? ?? '',
        masteryScore: json['mastery_score'] as int? ?? 0,
        srsTier: json['srs_tier'] as int? ?? 1,
        stars: json['stars'] as int? ?? 0,
      );
}

class ExerciseAnswerResponse {
  ExerciseAnswerResponse({
    required this.masteryScoreBefore,
    required this.masteryScoreAfter,
    required this.srsTierBefore,
    required this.srsTierAfter,
    required this.xpEarned,
    required this.nextReviewDate,
    required this.stars,
  });

  final int masteryScoreBefore;
  final int masteryScoreAfter;
  final int srsTierBefore;
  final int srsTierAfter;
  final int xpEarned;
  final String nextReviewDate;
  final int stars;

  factory ExerciseAnswerResponse.fromJson(Map<String, dynamic> json) =>
      ExerciseAnswerResponse(
        masteryScoreBefore: json['mastery_score_before'] as int,
        masteryScoreAfter: json['mastery_score_after'] as int,
        srsTierBefore: json['srs_tier_before'] as int,
        srsTierAfter: json['srs_tier_after'] as int,
        xpEarned: json['xp_earned'] as int,
        nextReviewDate: json['next_review_date'] as String,
        stars: json['stars'] as int,
      );
}

class StepResultResponse {
  StepResultResponse({
    required this.masteryScore,
    required this.srsTier,
    required this.stars,
    required this.xpEarned,
    required this.nextReviewDate,
  });

  final int masteryScore;
  final int srsTier;
  final int stars;
  final int xpEarned;
  final String nextReviewDate;

  factory StepResultResponse.fromJson(Map<String, dynamic> json) =>
      StepResultResponse(
        masteryScore: json['mastery_score'] as int,
        srsTier: json['srs_tier'] as int,
        stars: json['stars'] as int,
        xpEarned: json['xp_earned'] as int,
        nextReviewDate: json['next_review_date'] as String,
      );
}

class EnrichedSurahResponse {
  EnrichedSurahResponse({
    required this.surahNumber,
    required this.nameAr,
    required this.nameFr,
    required this.verseCount,
    required this.verses,
    this.nameTransliteration = '',
    this.revelation = '',
    this.themeFr = '',
    this.introFr = '',
  });

  final int surahNumber;
  final String nameAr;
  final String nameFr;
  final String nameTransliteration;
  final String revelation;
  final int verseCount;
  final String themeFr;
  final String introFr;
  final List<EnrichedVerse> verses;

  factory EnrichedSurahResponse.fromJson(Map<String, dynamic> json) =>
      EnrichedSurahResponse(
        surahNumber: json['surah_number'] as int,
        nameAr: json['name_ar'] as String,
        nameFr: json['name_fr'] as String,
        nameTransliteration: json['name_transliteration'] as String? ?? '',
        revelation: json['revelation'] as String? ?? '',
        verseCount: json['verse_count'] as int,
        themeFr: json['theme_fr'] as String? ?? '',
        introFr: json['intro_fr'] as String? ?? '',
        verses: (json['verses'] as List)
            .map((v) {
              final m = v as Map<String, dynamic>;
              // Inject surah_number for EnrichedVerse.fromJson
              m['surah_number'] = json['surah_number'];
              return EnrichedVerse.fromJson(m);
            })
            .toList(),
      );
}

class JourneyMapResponse {
  JourneyMapResponse({
    required this.surahs,
    this.totalVersesMemorized = 0,
    this.totalStars = 0,
    this.currentStreak = 0,
    this.totalXp = 0,
    this.level = 'DEBUTANT',
    this.titleAr = 'طالب',
    this.titleFr = 'Talib',
  });

  final List<SurahMapEntry> surahs;
  final int totalVersesMemorized;
  final int totalStars;
  final int currentStreak;
  final int totalXp;
  final String level;
  final String titleAr;
  final String titleFr;

  factory JourneyMapResponse.fromJson(Map<String, dynamic> json) =>
      JourneyMapResponse(
        surahs: (json['surahs'] as List)
            .map((s) => SurahMapEntry.fromJson(s as Map<String, dynamic>))
            .toList(),
        totalVersesMemorized: json['total_verses_memorized'] as int? ?? 0,
        totalStars: json['total_stars'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        totalXp: json['total_xp'] as int? ?? 0,
        level: json['level'] as String? ?? 'DEBUTANT',
        titleAr: json['title_ar'] as String? ?? 'طالب',
        titleFr: json['title_fr'] as String? ?? 'Talib',
      );
}

class SurahMapEntry {
  SurahMapEntry({
    required this.surahNumber,
    required this.nameAr,
    required this.nameFr,
    required this.totalVerses,
    this.versesStarted = 0,
    this.versesMastered = 0,
    this.totalStars = 0,
    this.maxStars = 0,
    this.averageScore = 0.0,
    this.isCompleted = false,
    this.hasGoal = false,
  });

  final int surahNumber;
  final String nameAr;
  final String nameFr;
  final int totalVerses;
  final int versesStarted;
  final int versesMastered;
  final int totalStars;
  final int maxStars;
  final double averageScore;
  final bool isCompleted;
  final bool hasGoal;

  factory SurahMapEntry.fromJson(Map<String, dynamic> json) => SurahMapEntry(
        surahNumber: json['surah_number'] as int,
        nameAr: json['name_ar'] as String? ?? '',
        nameFr: json['name_fr'] as String? ?? '',
        totalVerses: json['total_verses'] as int,
        versesStarted: json['verses_started'] as int? ?? 0,
        versesMastered: json['verses_mastered'] as int? ?? 0,
        totalStars: json['total_stars'] as int? ?? 0,
        maxStars: json['max_stars'] as int? ?? 0,
        averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
        isCompleted: json['is_completed'] as bool? ?? false,
        hasGoal: json['has_goal'] as bool? ?? false,
      );
}

class VerseProgressV2Response {
  VerseProgressV2Response({
    required this.surahNumber,
    required this.verseNumber,
    required this.masteryScore,
    required this.srsTier,
    required this.srsTierLabel,
    required this.srsTierColor,
    required this.stars,
    required this.nextReviewDate,
    required this.reviewCount,
    this.totalExercisesPlayed = 0,
  });

  final int surahNumber;
  final int verseNumber;
  final int masteryScore;
  final int srsTier;
  final String srsTierLabel;
  final String srsTierColor;
  final int stars;
  final String nextReviewDate;
  final int reviewCount;
  final int totalExercisesPlayed;

  factory VerseProgressV2Response.fromJson(Map<String, dynamic> json) =>
      VerseProgressV2Response(
        surahNumber: json['surah_number'] as int,
        verseNumber: json['verse_number'] as int,
        masteryScore: json['mastery_score'] as int,
        srsTier: json['srs_tier'] as int,
        srsTierLabel: json['srs_tier_label'] as String,
        srsTierColor: json['srs_tier_color'] as String,
        stars: json['stars'] as int,
        nextReviewDate: json['next_review_date'] as String,
        reviewCount: json['review_count'] as int,
        totalExercisesPlayed: json['total_exercises_played'] as int? ?? 0,
      );
}

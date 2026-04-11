import 'package:flutter/material.dart';

/// Learning models for Autonomous Learning feature
/// Includes Word, LearningSession, ModuleProgress, etc.

class LearningWord {
  final String id;
  final String arabicWord;
  final String meaning;
  final String? transliteration;
  final String? audioUrl;
  final int moduleNumber;
  final int frequency;

  const LearningWord({
    required this.id,
    required this.arabicWord,
    required this.meaning,
    this.transliteration,
    this.audioUrl,
    required this.moduleNumber,
    required this.frequency,
  });

  factory LearningWord.fromJson(Map<String, dynamic> json) {
    return LearningWord(
      id: json['id'] ?? '',
      arabicWord: json['arabicWord'] ?? '',
      meaning: json['meaning'] ?? '',
      transliteration: json['transliteration'],
      audioUrl: json['audioUrl'],
      moduleNumber: json['moduleNumber'] ?? 1,
      frequency: json['frequency'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabicWord': arabicWord,
        'meaning': meaning,
        'transliteration': transliteration,
        'audioUrl': audioUrl,
        'moduleNumber': moduleNumber,
        'frequency': frequency,
      };
}

class LeitnerCard {
  final String id;
  final String wordId;
  final int boxLevel; // 1-5 (Box system levels)
  final DateTime lastReviewedAt;
  final int reviewCount;
  final bool isCorrect;
  final DateTime nextReviewAt;

  const LeitnerCard({
    required this.id,
    required this.wordId,
    required this.boxLevel,
    required this.lastReviewedAt,
    required this.reviewCount,
    required this.isCorrect,
    required this.nextReviewAt,
  });

  factory LeitnerCard.fromJson(Map<String, dynamic> json) {
    return LeitnerCard(
      id: json['id'] ?? '',
      wordId: json['wordId'] ?? '',
      boxLevel: json['boxLevel'] ?? 1,
      lastReviewedAt: DateTime.parse(json['lastReviewedAt'] ?? DateTime.now().toIso8601String()),
      reviewCount: json['reviewCount'] ?? 0,
      isCorrect: json['isCorrect'] ?? false,
      nextReviewAt: DateTime.parse(json['nextReviewAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wordId': wordId,
        'boxLevel': boxLevel,
        'lastReviewedAt': lastReviewedAt.toIso8601String(),
        'reviewCount': reviewCount,
        'isCorrect': isCorrect,
        'nextReviewAt': nextReviewAt.toIso8601String(),
      };
}

class LearningSession {
  final String id;
  final String studentId;
  final int moduleNumber;
  final int phase;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalCards;
  final int correctAnswers;
  final int accuracy;
  final List<String> cardIds;

  const LearningSession({
    required this.id,
    required this.studentId,
    required this.moduleNumber,
    required this.phase,
    required this.startedAt,
    this.completedAt,
    required this.totalCards,
    required this.correctAnswers,
    required this.accuracy,
    required this.cardIds,
  });

  factory LearningSession.fromJson(Map<String, dynamic> json) {
    return LearningSession(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      moduleNumber: json['moduleNumber'] ?? 1,
      phase: json['phase'] ?? 1,
      startedAt: DateTime.parse(json['startedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      totalCards: json['totalCards'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      accuracy: json['accuracy'] ?? 0,
      cardIds: List<String>.from(json['cardIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'moduleNumber': moduleNumber,
        'phase': phase,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'totalCards': totalCards,
        'correctAnswers': correctAnswers,
        'accuracy': accuracy,
        'cardIds': cardIds,
      };
}

class ModuleProgress {
  final int moduleNumber;
  final int percentComplete;
  final int currentPhase;
  final int masteryLevel;
  final int masteredCount;
  final int totalCount;
  final int accuracy;
  final Map<String, int> leitnerDistribution; // box level -> count

  const ModuleProgress({
    required this.moduleNumber,
    required this.percentComplete,
    required this.currentPhase,
    required this.masteryLevel,
    required this.masteredCount,
    required this.totalCount,
    required this.accuracy,
    required this.leitnerDistribution,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleNumber: json['moduleNumber'] ?? 1,
      percentComplete: json['percentComplete'] ?? 0,
      currentPhase: json['currentPhase'] ?? 0,
      masteryLevel: json['masteryLevel'] ?? 0,
      masteredCount: json['masteredCount'] ?? 0,
      totalCount: json['totalCount'] ?? 50,
      accuracy: json['accuracy'] ?? 0,
      leitnerDistribution: Map<String, int>.from(json['leitnerDistribution'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'moduleNumber': moduleNumber,
        'percentComplete': percentComplete,
        'currentPhase': currentPhase,
        'masteryLevel': masteryLevel,
        'masteredCount': masteredCount,
        'totalCount': totalCount,
        'accuracy': accuracy,
        'leitnerDistribution': leitnerDistribution,
      };
}

class ExerciseResult {
  final String sessionId;
  final String cardId;
  final bool correct;
  final int responseTimeMs;
  final DateTime answeredAt;

  const ExerciseResult({
    required this.sessionId,
    required this.cardId,
    required this.correct,
    required this.responseTimeMs,
    required this.answeredAt,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      sessionId: json['sessionId'] ?? '',
      cardId: json['cardId'] ?? '',
      correct: json['correct'] ?? false,
      responseTimeMs: json['responseTimeMs'] ?? 0,
      answeredAt: DateTime.parse(json['answeredAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'cardId': cardId,
        'correct': correct,
        'responseTimeMs': responseTimeMs,
        'answeredAt': answeredAt.toIso8601String(),
      };
}

// ============ HIFZ MASTER MODELS ============

enum GoalMode {
  quantitative,
  temporal;

  factory GoalMode.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'TEMPORAL':
        return GoalMode.temporal;
      default:
        return GoalMode.quantitative;
    }
  }

  String get apiValue => name.toUpperCase();
}

enum VerseMastery {
  red,
  orange,
  green;

  factory VerseMastery.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ORANGE':
        return VerseMastery.orange;
      case 'GREEN':
        return VerseMastery.green;
      default:
        return VerseMastery.red;
    }
  }

  Color get color {
    switch (this) {
      case VerseMastery.red:
        return Colors.red;
      case VerseMastery.orange:
        return Colors.orange;
      case VerseMastery.green:
        return Colors.green;
    }
  }
}

enum StudentLevel {
  debutant,
  apprenti,
  hafizEnHerbe,
  hafizConfirme,
  hafizExpert;

  factory StudentLevel.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'APPRENTI':
        return StudentLevel.apprenti;
      case 'HAFIZ_EN_HERBE':
        return StudentLevel.hafizEnHerbe;
      case 'HAFIZ_CONFIRME':
        return StudentLevel.hafizConfirme;
      case 'HAFIZ_EXPERT':
        return StudentLevel.hafizExpert;
      default:
        return StudentLevel.debutant;
    }
  }

  String get titleFr {
    switch (this) {
      case StudentLevel.debutant:
        return 'Débutant';
      case StudentLevel.apprenti:
        return 'Apprenti';
      case StudentLevel.hafizEnHerbe:
        return 'Hafiz en herbe';
      case StudentLevel.hafizConfirme:
        return 'Hafiz confirmé';
      case StudentLevel.hafizExpert:
        return 'Hafiz expert';
    }
  }

  IconData get icon {
    switch (this) {
      case StudentLevel.debutant:
        return Icons.import_contacts;
      case StudentLevel.apprenti:
        return Icons.school;
      case StudentLevel.hafizEnHerbe:
        return Icons.star_half;
      case StudentLevel.hafizConfirme:
        return Icons.grade;
      case StudentLevel.hafizExpert:
        return Icons.emoji_events;
    }
  }
}

class HifzGoalModel {
  final String id;
  final int surahNumber;
  final String mode;
  final int versesPerDay;
  final String? targetDate;
  final String reciterFolder;
  final int totalVerses;
  final int versesMemorized;
  final int calculatedDailyTarget;
  final bool isCompleted;

  const HifzGoalModel({
    required this.id,
    required this.surahNumber,
    required this.mode,
    required this.versesPerDay,
    this.targetDate,
    required this.reciterFolder,
    required this.totalVerses,
    required this.versesMemorized,
    required this.calculatedDailyTarget,
    required this.isCompleted,
  });

  factory HifzGoalModel.fromJson(Map<String, dynamic> json) {
    return HifzGoalModel(
      id: json['id']?.toString() ?? '',
      surahNumber: json['surah_number'] ?? 1,
      mode: json['mode'] ?? 'QUANTITATIVE',
      versesPerDay: json['verses_per_day'] ?? 5,
      targetDate: json['target_date'],
      reciterFolder: json['reciter_folder'] ?? 'Alafasy_128kbps',
      totalVerses: json['total_verses'] ?? 0,
      versesMemorized: json['verses_memorized'] ?? 0,
      calculatedDailyTarget: json['calculated_daily_target'] ?? 5,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class VerseProgressModel {
  final String id;
  final int surahNumber;
  final int verseNumber;
  final VerseMastery mastery;
  final int masteryScore;
  final String nextReviewDate;
  final int totalListens;
  final int consecutiveSuccesses;
  final int reviewCount;

  const VerseProgressModel({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.mastery,
    required this.masteryScore,
    required this.nextReviewDate,
    required this.totalListens,
    required this.consecutiveSuccesses,
    required this.reviewCount,
  });

  factory VerseProgressModel.fromJson(Map<String, dynamic> json) {
    return VerseProgressModel(
      id: json['id']?.toString() ?? '',
      surahNumber: json['surah_number'] ?? 1,
      verseNumber: json['verse_number'] ?? 1,
      mastery: VerseMastery.fromApi(json['mastery'] ?? 'RED'),
      masteryScore: json['mastery_score'] ?? 0,
      nextReviewDate: json['next_review_date'] ?? DateTime.now().toIso8601String(),
      totalListens: json['total_listens'] ?? 0,
      consecutiveSuccesses: json['consecutive_successes'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
    );
  }
}

class BadgeModel {
  final String id;
  final String badgeType;
  final String earnedAt;

  const BadgeModel({
    required this.id,
    required this.badgeType,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      badgeType: json['badge_type'] ?? '',
      earnedAt: json['earned_at'] ?? '',
    );
  }
}

class StudentXPModel {
  final int totalXp;
  final StudentLevel level;
  final List<BadgeModel> badges;

  const StudentXPModel({
    required this.totalXp,
    required this.level,
    required this.badges,
  });

  factory StudentXPModel.fromJson(Map<String, dynamic> json) {
    return StudentXPModel(
      totalXp: json['total_xp'] ?? 0,
      level: StudentLevel.fromApi(json['level'] ?? 'DEBUTANT'),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => BadgeModel.fromJson(b))
              .toList() ??
          [],
    );
  }
}

class ReciterModel {
  final String id;
  final String nameEn;
  final String nameAr;

  const ReciterModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
    );
  }
}

class VerseHeatmapEntry {
  final int verseNumber;
  final String mastery;
  final int masteryScore;
  final bool needsReview;

  const VerseHeatmapEntry({
    required this.verseNumber,
    required this.mastery,
    required this.masteryScore,
    required this.needsReview,
  });

  factory VerseHeatmapEntry.fromJson(Map<String, dynamic> json) {
    return VerseHeatmapEntry(
      verseNumber: json['verse_number'] ?? 1,
      mastery: json['mastery'] ?? 'RED',
      masteryScore: json['mastery_score'] ?? 0,
      needsReview: json['needs_review'] ?? false,
    );
  }
}

class SurahHeatmapModel {
  final int surahNumber;
  final List<VerseHeatmapEntry> verses;

  const SurahHeatmapModel({
    required this.surahNumber,
    required this.verses,
  });

  factory SurahHeatmapModel.fromJson(Map<String, dynamic> json) {
    return SurahHeatmapModel(
      surahNumber: json['surah_number'] ?? 1,
      verses: (json['verses'] as List<dynamic>?)
              ?.map((v) => VerseHeatmapEntry.fromJson(v))
              .toList() ??
          [],
    );
  }
}

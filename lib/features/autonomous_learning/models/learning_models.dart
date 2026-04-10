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

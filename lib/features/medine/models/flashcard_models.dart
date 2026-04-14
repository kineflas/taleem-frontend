import 'package:equatable/equatable.dart';

/// A single flashcard (front Arabic / back French).
class FlashcardCard extends Equatable {
  final String id;
  final String cardIdStr;
  final int lessonNumber;
  final int partNumber;
  final String frontAr;
  final String backFr;
  final String? category;
  final String? arabicExample;
  final String? frenchExample;

  const FlashcardCard({
    required this.id,
    required this.cardIdStr,
    required this.lessonNumber,
    required this.partNumber,
    required this.frontAr,
    required this.backFr,
    this.category,
    this.arabicExample,
    this.frenchExample,
  });

  factory FlashcardCard.fromJson(Map<String, dynamic> json) => FlashcardCard(
        id: json['id'] ?? '',
        cardIdStr: json['card_id_str'] ?? '',
        lessonNumber: json['lesson_number'] ?? 0,
        partNumber: json['part_number'] ?? 0,
        frontAr: json['front_ar'] ?? '',
        backFr: json['back_fr'] ?? '',
        category: json['category'],
        arabicExample: json['arabic_example'],
        frenchExample: json['french_example'],
      );

  @override
  List<Object?> get props => [id, cardIdStr, lessonNumber, partNumber, frontAr, backFr];
}

/// A flashcard with its SRS progress state.
class FlashcardWithProgress extends Equatable {
  final FlashcardCard card;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final int? lastQuality;
  final int reviewCount;

  const FlashcardWithProgress({
    required this.card,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReview,
    this.lastQuality,
    required this.reviewCount,
  });

  factory FlashcardWithProgress.fromJson(Map<String, dynamic> json) =>
      FlashcardWithProgress(
        card: FlashcardCard.fromJson(json['card'] ?? {}),
        easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['interval_days'] ?? 0,
        repetitions: json['repetitions'] ?? 0,
        nextReview: DateTime.tryParse(json['next_review'] ?? '') ?? DateTime.now(),
        lastQuality: json['last_quality'],
        reviewCount: json['review_count'] ?? 0,
      );

  @override
  List<Object?> get props => [card, easeFactor, intervalDays, repetitions];
}

/// Response after reviewing a card.
class ReviewResult extends Equatable {
  final String cardId;
  final double newEaseFactor;
  final int newIntervalDays;
  final DateTime nextReview;
  final int xpEarned;

  const ReviewResult({
    required this.cardId,
    required this.newEaseFactor,
    required this.newIntervalDays,
    required this.nextReview,
    required this.xpEarned,
  });

  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
        cardId: json['card_id'] ?? '',
        newEaseFactor: (json['new_ease_factor'] as num?)?.toDouble() ?? 2.5,
        newIntervalDays: json['new_interval_days'] ?? 0,
        nextReview: DateTime.tryParse(json['next_review'] ?? '') ?? DateTime.now(),
        xpEarned: json['xp_earned'] ?? 0,
      );

  @override
  List<Object?> get props => [cardId, newEaseFactor, newIntervalDays, xpEarned];
}

/// SRS statistics summary.
class SrsStats extends Equatable {
  final int totalStarted;
  final int totalAvailable;
  final int dueToday;
  final int mastered;
  final int learning;

  const SrsStats({
    this.totalStarted = 0,
    this.totalAvailable = 0,
    this.dueToday = 0,
    this.mastered = 0,
    this.learning = 0,
  });

  factory SrsStats.fromJson(Map<String, dynamic> json) => SrsStats(
        totalStarted: json['total_started'] ?? 0,
        totalAvailable: json['total_available'] ?? 0,
        dueToday: json['due_today'] ?? 0,
        mastered: json['mastered'] ?? 0,
        learning: json['learning'] ?? 0,
      );

  @override
  List<Object?> get props => [totalStarted, totalAvailable, dueToday, mastered, learning];
}

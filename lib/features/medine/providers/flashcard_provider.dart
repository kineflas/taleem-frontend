import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/flashcard_models.dart';

// ── API Service ───────────────────────────────────────────────────────────

class FlashcardApi {
  final Dio _client;
  FlashcardApi(this._client);

  /// Get due flashcards (max 50)
  Future<List<FlashcardWithProgress>> fetchDueCards() async {
    final res = await _client.get(ApiConstants.flashcardsDue);
    return (res.data as List)
        .map((j) => FlashcardWithProgress.fromJson(j))
        .toList();
  }

  /// Get new cards for a lesson (max 15)
  Future<List<FlashcardCard>> fetchNewCards(int lessonNumber) async {
    final res = await _client.get(ApiConstants.flashcardsNew(lessonNumber));
    return (res.data as List)
        .map((j) => FlashcardCard.fromJson(j))
        .toList();
  }

  /// Review a card (quality: 1=Again, 3=Hard, 4=Good, 5=Easy)
  Future<ReviewResult> reviewCard(String cardId, int quality) async {
    final res = await _client.post(
      ApiConstants.flashcardReview(cardId),
      data: {'quality': quality},
    );
    return ReviewResult.fromJson(res.data);
  }

  /// Get SRS stats
  Future<SrsStats> fetchStats() async {
    final res = await _client.get(ApiConstants.flashcardsStats);
    return SrsStats.fromJson(res.data);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final flashcardApiProvider = Provider<FlashcardApi>(
  (ref) => FlashcardApi(ref.read(dioProvider)),
);

/// Due cards for review
final flashcardsDueProvider = FutureProvider<List<FlashcardWithProgress>>((ref) {
  return ref.read(flashcardApiProvider).fetchDueCards();
});

/// New cards for a specific lesson
final flashcardsNewProvider =
    FutureProvider.family<List<FlashcardCard>, int>((ref, lessonNumber) {
  return ref.read(flashcardApiProvider).fetchNewCards(lessonNumber);
});

/// SRS stats
final flashcardStatsProvider = FutureProvider<SrsStats>((ref) {
  return ref.read(flashcardApiProvider).fetchStats();
});

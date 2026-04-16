import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Flashcard review screen for Médine V2.
/// Shows cards from completed lessons in a swipeable stack.
class FlashcardReviewScreenV2 extends ConsumerStatefulWidget {
  const FlashcardReviewScreenV2({super.key});

  @override
  ConsumerState<FlashcardReviewScreenV2> createState() =>
      _FlashcardReviewScreenV2State();
}

class _FlashcardReviewScreenV2State
    extends ConsumerState<FlashcardReviewScreenV2> {
  int _currentIndex = 0;
  bool _showBack = false;
  int _knownCount = 0;
  int _reviewCount = 0;
  List<FlashcardV2> _allCards = [];
  String _currentLesson = '';

  void _buildDeck(List<FlashcardGroupV2> groups) {
    if (_allCards.isNotEmpty) return; // already built
    final cards = <FlashcardV2>[];
    for (final g in groups) {
      cards.addAll(g.cards);
    }
    // Shuffle for variety
    cards.shuffle(Random());
    _allCards = cards;
  }

  String _findLessonTitle(List<FlashcardGroupV2> groups, FlashcardV2 card) {
    for (final g in groups) {
      if (g.cards.contains(card)) return 'Leçon ${g.lessonNumber}';
    }
    return '';
  }

  void _markKnown() {
    setState(() {
      _knownCount++;
      _advance();
    });
  }

  void _markReview() {
    setState(() {
      _reviewCount++;
      // Put it back at the end for another pass
      if (_currentIndex < _allCards.length) {
        _allCards.add(_allCards[_currentIndex]);
      }
      _advance();
    });
  }

  void _advance() {
    _showBack = false;
    if (_currentIndex < _allCards.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = _allCards.length; // triggers completion
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashcardsAsync = ref.watch(medineV2FlashcardsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Révision Flashcards',
          style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: flashcardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erreur de chargement'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(medineV2FlashcardsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState();
          }
          _buildDeck(groups);
          if (_allCards.isEmpty) return _buildEmptyState();

          // Check if done
          if (_currentIndex >= _allCards.length) {
            return _buildCompletionState();
          }

          final card = _allCards[_currentIndex];
          _currentLesson = _findLessonTitle(groups, card);

          return _buildCardView(card);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📇', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Aucune flashcard disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Termine des leçons pour débloquer des flashcards à réviser.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/student/medine-v2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retour à la carte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionState() {
    final total = _knownCount + _reviewCount;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Session terminée !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.check_circle,
                  color: const Color(0xFF2D6A4F),
                  label: '$_knownCount maîtrisées',
                ),
                const SizedBox(width: 16),
                _StatChip(
                  icon: Icons.refresh,
                  color: const Color(0xFFE76F51),
                  label: '$_reviewCount à revoir',
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _allCards = [];
                  _currentIndex = 0;
                  _knownCount = 0;
                  _reviewCount = 0;
                  _showBack = false;
                });
                ref.invalidate(medineV2FlashcardsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Nouvelle session'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/student/medine-v2'),
              child: const Text(
                'Retour à la carte',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(FlashcardV2 card) {
    final remaining = _allCards.length - _currentIndex;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentLesson,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
                Text(
                  '$remaining cartes restantes',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              ],
            ),
            if (card.category != null) ...[
              const SizedBox(height: 4),
              Text(
                card.category!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F)),
              ),
            ],
            const SizedBox(height: 16),

            // Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showBack
                      ? _CardFace(
                          key: const ValueKey('back'),
                          text: card.backFr,
                          subtitle: 'Traduction / Réponse',
                          color: const Color(0xFF2D6A4F),
                          isArabic: false,
                        )
                      : _CardFace(
                          key: const ValueKey('front'),
                          text: card.frontAr,
                          subtitle: 'Touche pour retourner',
                          color: const Color(0xFF1A1A2E),
                          isArabic: true,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons (only visible after flip)
            if (_showBack)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markReview,
                      icon: const Icon(Icons.refresh),
                      label: const Text('À revoir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE76F51),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markKnown,
                      icon: const Icon(Icons.check),
                      label: const Text('Je sais'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Touche la carte pour voir la réponse',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String subtitle;
  final Color color;
  final bool isArabic;

  const _CardFace({
    super.key,
    required this.text,
    required this.subtitle,
    required this.color,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: isArabic ? 26 : 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

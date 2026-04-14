import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/flashcard_models.dart';
import '../providers/flashcard_provider.dart';

/// Flashcard review session: shows due cards one by one with flip animation.
/// After flipping, user rates: Again(1) / Hard(3) / Good(4) / Easy(5).
class FlashcardReviewScreen extends ConsumerStatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen> {
  List<FlashcardWithProgress> _cards = [];
  int _currentIndex = 0;
  bool _flipped = false;
  bool _loading = true;
  int _totalXp = 0;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await ref.read(flashcardApiProvider).fetchDueCards();
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _rate(int quality) async {
    if (_currentIndex >= _cards.length) return;
    final card = _cards[_currentIndex];

    try {
      final result = await ref.read(flashcardApiProvider).reviewCard(
            card.card.id,
            quality,
          );
      setState(() {
        _totalXp += result.xpEarned;
        _reviewed++;
        _currentIndex++;
        _flipped = false;
      });
    } catch (_) {
      // Skip on error
      setState(() {
        _currentIndex++;
        _flipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Revision', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_cards.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${_cards.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _EmptyState()
              : _currentIndex >= _cards.length
                  ? _SessionComplete(reviewed: _reviewed, xpEarned: _totalXp)
                  : _CardView(
                      card: _cards[_currentIndex].card,
                      flipped: _flipped,
                      onFlip: () => setState(() => _flipped = true),
                      onRate: _rate,
                    ),
    );
  }
}

class _CardView extends StatelessWidget {
  final FlashcardCard card;
  final bool flipped;
  final VoidCallback onFlip;
  final Future<void> Function(int quality) onRate;

  const _CardView({
    required this.card,
    required this.flipped,
    required this.onFlip,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Flip card
          Expanded(
            child: GestureDetector(
              onTap: flipped ? null : onFlip,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: pi / 2, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    listenable: rotate,
                    builder: (_, child) => Transform(
                      transform: Matrix4.identity()..rotateY(rotate.value),
                      alignment: Alignment.center,
                      child: child,
                    ),
                    child: child,
                  );
                },
                child: flipped
                    ? _BackSide(key: const ValueKey('back'), card: card)
                    : _FrontSide(key: const ValueKey('front'), card: card),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rating buttons (visible only when flipped)
          if (flipped) ...[
            const Text(
              'Comment etait-ce ?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _RatingButton(
                  label: 'A revoir',
                  color: AppColors.danger,
                  onTap: () => onRate(1),
                ),
                const SizedBox(width: 8),
                _RatingButton(
                  label: 'Difficile',
                  color: AppColors.warning,
                  onTap: () => onRate(3),
                ),
                const SizedBox(width: 8),
                _RatingButton(
                  label: 'Bien',
                  color: AppColors.success,
                  onTap: () => onRate(4),
                ),
                const SizedBox(width: 8),
                _RatingButton(
                  label: 'Facile',
                  color: AppColors.primary,
                  onTap: () => onRate(5),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Appuyez sur la carte pour la retourner',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _FrontSide extends StatelessWidget {
  const _FrontSide({super.key, required this.card});
  final FlashcardCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.category!,
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              card.frontAr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                height: 1.5,
              ),
            ),
          ),
          if (card.arabicExample != null) ...[
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                card.arabicExample!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Amiri',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const Spacer(),
          const Icon(Icons.touch_app, color: AppColors.textHint, size: 28),
        ],
      ),
    );
  }
}

class _BackSide extends StatelessWidget {
  const _BackSide({super.key, required this.card});
  final FlashcardCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 2),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Arabic (reminder)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              card.frontAr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'Amiri',
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // French translation
          Text(
            card.backFr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (card.frenchExample != null) ...[
            const SizedBox(height: 12),
            Text(
              card.frenchExample!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Aucune carte a reviser !',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Revenez plus tard pour vos prochaines revisions.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SessionComplete extends StatelessWidget {
  final int reviewed;
  final int xpEarned;

  const _SessionComplete({required this.reviewed, required this.xpEarned});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Session terminee !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$reviewed cartes revisees',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper: AnimatedBuilder is just AnimatedWidget with a builder —
/// Flutter doesn't have this by name, so we define it inline.
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}

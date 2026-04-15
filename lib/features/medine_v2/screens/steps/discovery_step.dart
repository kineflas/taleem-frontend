import 'package:flutter/material.dart';
import '../../models/lesson_models_v2.dart';
import '../../providers/lesson_provider_v2.dart';

/// Step 2: Swipable discovery cards (theory, expert corner, pronunciation, etc.)
class DiscoveryStep extends StatefulWidget {
  final LessonContentV2 lesson;
  final VoidCallback onComplete;

  const DiscoveryStep({super.key, required this.lesson, required this.onComplete});

  @override
  State<DiscoveryStep> createState() => _DiscoveryStepState();
}

class _DiscoveryStepState extends State<DiscoveryStep> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<DiscoveryCard> get cards => widget.lesson.discoveryCards;
  bool get isLastCard => _currentPage >= cards.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (isLastCard) {
      widget.onComplete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: widget.onComplete,
          child: const Text('Continuer'),
        ),
      );
    }

    return Column(
      children: [
        // ── Card counter header ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              // Back arrow (if not first card)
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _goBack,
                  child: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF666666)),
                )
              else
                const SizedBox(width: 18),
              const Spacer(),
              // Card counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${cards.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 18),
            ],
          ),
        ),

        // ── Page dots ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _currentPage ? 24 : 8,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? const Color(0xFF2D6A4F)
                    : i < _currentPage
                        ? const Color(0xFF2D6A4F).withOpacity(0.4)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
        ),

        // ── Card content (PageView) ──────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _buildCard(cards[i]),
          ),
        ),

        // ── Bottom navigation bar (always visible) ──────────────────
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8F0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastCard
                      ? const Color(0xFF1B4332)
                      : const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastCard ? 'Continuer' : 'Suivant',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastCard ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DiscoveryCard card) {
    switch (card.type) {
      case 'rule':
        return _RuleCard(card: card);
      case 'expert_corner':
        return _ExpertCornerCard(card: card);
      case 'pronunciation':
        return _PronunciationCard(card: card);
      case 'examples_table':
        return _ExamplesTableCard(card: card);
      case 'mise_en_situation':
        return _MiseEnSituationCard(card: card);
      default:
        return _RuleCard(card: card);
    }
  }
}

// ── Card Widgets ────────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  final DiscoveryCard card;
  const _RuleCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    card.titleFr ?? 'Règle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          if (card.contentFr != null)
            _MarkdownishText(text: card.contentFr!),

          // Inline examples
          if (card.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...card.examples.map((ex) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8F3DC)),
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ex.ar,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Amiri',
                        color: Color(0xFF1D3557),
                      ),
                    ),
                  ),
                  if (ex.translit != null && ex.translit!.isNotEmpty)
                    Text(
                      ex.translit!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF666666),
                      ),
                    ),
                  Text(
                    ex.fr,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _ExpertCornerCard extends StatefulWidget {
  final DiscoveryCard card;
  const _ExpertCornerCard({required this.card});

  @override
  State<_ExpertCornerCard> createState() => _ExpertCornerCardState();
}

class _ExpertCornerCardState extends State<_ExpertCornerCard> {
  bool _expanded = true; // Start expanded so user sees content

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Le coin des experts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          'Pour aller plus loin',
                          style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFE65100),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _MarkdownishText(
                text: widget.card.contentFr ?? '',
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PronunciationCard extends StatelessWidget {
  final DiscoveryCard card;
  const _PronunciationCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔊', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'Prononciation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...card.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((item['ar'] as String? ?? '').isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            item['ar'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontFamily: 'Amiri',
                              color: Color(0xFF1D3557),
                            ),
                          ),
                        ),
                      Text(
                        item['note'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ExamplesTableCard extends StatelessWidget {
  final DiscoveryCard card;
  const _ExamplesTableCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📝', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'Exemples',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...card.rows.map((row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    row['ar'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontFamily: 'Amiri',
                      color: Color(0xFF1D3557),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row['fr'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                ),
                if ((row['analysis'] as String? ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      row['analysis'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MiseEnSituationCard extends StatelessWidget {
  final DiscoveryCard card;
  const _MiseEnSituationCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎬', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'Mise en situation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF283593),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC5CAE9)),
            ),
            child: _MarkdownishText(text: card.contentFr ?? ''),
          ),
        ],
      ),
    );
  }
}

// ── Utility widget for rendering markdown-ish text ─────────────────────────

class _MarkdownishText extends StatelessWidget {
  final String text;
  const _MarkdownishText({required this.text});

  @override
  Widget build(BuildContext context) {
    // Split into paragraphs and render with basic styling
    final paragraphs = text.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) {
        final trimmed = p.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();

        // Check for bullet points
        if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(fontSize: 14, color: Color(0xFF2D6A4F))),
                Expanded(
                  child: _RichText(text: trimmed.substring(2)),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RichText(text: trimmed),
        );
      }).toList(),
    );
  }
}

class _RichText extends StatelessWidget {
  final String text;
  const _RichText({required this.text});

  @override
  Widget build(BuildContext context) {
    // Simple bold/italic parsing for **bold** and *italic*
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      if (match.group(1) != null) {
        // Bold — check if it contains Arabic
        final content = match.group(1)!;
        final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(content);
        spans.add(TextSpan(
          text: content,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: hasArabic ? 'Amiri' : null,
            fontSize: hasArabic ? 18 : null,
            color: hasArabic ? const Color(0xFF1D3557) : null,
          ),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF333333),
          height: 1.6,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}

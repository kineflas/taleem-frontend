import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/lesson_models.dart';

/// Tab 1: Theory content (sections, examples, vocab, illustrations).
class TheoryTab extends StatefulWidget {
  final LessonTheory theory;
  final VoidCallback onComplete;

  const TheoryTab({
    super.key,
    required this.theory,
    required this.onComplete,
  });

  @override
  State<TheoryTab> createState() => _TheoryTabState();
}

class _TheoryTabState extends State<TheoryTab> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theory;
    final hasContent = t.sections.isNotEmpty ||
        t.examples.isNotEmpty ||
        t.vocab.isNotEmpty;

    if (!hasContent) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Contenu en cours de preparation',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Auto-mark complete when user scrolls to bottom
        if (!_completed &&
            notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 50) {
          _completed = true;
          widget.onComplete();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grammar summary
          if (t.grammarSummary != null) ...[
            _GrammarSummaryCard(summary: t.grammarSummary!),
            const SizedBox(height: 16),
          ],

          // Theory sections
          for (final section in t.sections) ...[
            _SectionCard(section: section),
            const SizedBox(height: 12),
          ],

          // Examples
          if (t.examples.isNotEmpty) ...[
            const _SectionTitle(title: 'Exemples'),
            const SizedBox(height: 8),
            for (final ex in t.examples) ...[
              _ExampleCard(example: ex),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],

          // Vocabulary
          if (t.vocab.isNotEmpty) ...[
            const _SectionTitle(title: 'Vocabulaire'),
            const SizedBox(height: 8),
            _VocabGrid(vocab: t.vocab),
            const SizedBox(height: 12),
          ],

          // Illustrations
          for (final illus in t.illustrations) ...[
            _IllustrationCard(illustration: illus),
            const SizedBox(height: 12),
          ],

          // Mark as read button
          if (!_completed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _completed = true);
                  widget.onComplete();
                },
                icon: const Icon(Icons.check),
                label: const Text("J'ai lu cette lecon"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    );
  }
}

class _GrammarSummaryCard extends StatelessWidget {
  final String summary;
  const _GrammarSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final TheorySection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.titleFr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.contentFr,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (section.contentAr != null) ...[
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.contentAr!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Amiri',
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ],
            if (section.tipFr != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.tipFr!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final ExampleItem example;
  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arabic text (RTL)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              example.arabic,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Amiri',
                color: AppColors.primary,
              ),
            ),
          ),
          if (example.transliteration != null) ...[
            const SizedBox(height: 4),
            Text(
              example.transliteration!,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            example.translationFr,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          if (example.breakdownFr != null) ...[
            const SizedBox(height: 6),
            Text(
              example.breakdownFr!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (example.grammaticalNoteFr != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                example.grammaticalNoteFr!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VocabGrid extends StatelessWidget {
  final List<VocabItem> vocab;
  const _VocabGrid({required this.vocab});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vocab.map((v) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  v.arabic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Amiri',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                v.translationFr,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (v.transliteration != null) ...[
                Text(
                  v.transliteration!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final IllustrationItem illustration;
  const _IllustrationCard({required this.illustration});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  illustration.type == 'table' ? Icons.table_chart : Icons.schema,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  illustration.titleFr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (illustration.data is String)
              Text(illustration.data, style: const TextStyle(fontSize: 14)),
            if (illustration.data is Map)
              Text(
                illustration.data.toString(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

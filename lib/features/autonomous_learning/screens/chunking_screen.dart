import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Chunking screen (Module 3).
/// Phases: Flash cards → Reorder chunks → Full verse reconstruction
class ChunkingScreen extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int phase;

  const ChunkingScreen({
    super.key,
    required this.moduleNumber,
    required this.phase,
  });

  @override
  ConsumerState<ChunkingScreen> createState() => _ChunkingScreenState();
}

class _ChunkingScreenState extends ConsumerState<ChunkingScreen> {
  int _currentChunkIndex = 0;
  final List<Map<String, dynamic>> _chunks = [
    {
      'text': 'الحمد لله',
      'meaning': 'Louange à Allah',
      'context': 'Sourate Al-Fatiha (1:1)',
      'audio': '/audio/chunks/alhamd.mp3',
    },
    {
      'text': 'رب العالمين',
      'meaning': 'Seigneur des mondes',
      'context': 'Sourate Al-Fatiha (1:2)',
      'audio': '/audio/chunks/rab.mp3',
    },
    {
      'text': 'الرحمن الرحيم',
      'meaning': 'Le Miséricordieux, le Très Miséricordieux',
      'context': 'Sourate Al-Fatiha (1:3)',
      'audio': '/audio/chunks/rahman.mp3',
    },
  ];

  late List<Map<String, dynamic>> _reorderedChunks;

  @override
  void initState() {
    super.initState();
    _reorderedChunks = List.from(_chunks)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Blocs de sens'),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: widget.phase / 3,
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.phase == 1)
                    _FlashCardPhase(
                      chunks: _chunks,
                      currentIndex: _currentChunkIndex,
                      onNext: () => setState(() {
                        if (_currentChunkIndex < _chunks.length - 1) {
                          _currentChunkIndex++;
                        }
                      }),
                      onPrevious: () => setState(() {
                        if (_currentChunkIndex > 0) {
                          _currentChunkIndex--;
                        }
                      }),
                    )
                  else if (widget.phase == 2)
                    _ReorderPhase(chunks: _reorderedChunks)
                  else
                    _VerseReconstructionPhase(chunks: _chunks),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashCardPhase extends StatelessWidget {
  final List<Map<String, dynamic>> chunks;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _FlashCardPhase({
    required this.chunks,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final chunk = chunks[currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '👁️ Voir et mémoriser',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Observez et écoutez chaque bloc de sens.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Chunk card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  chunk['text'],
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chunk['meaning'],
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                chunk['context'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.volume_up, size: 20),
                label: const Text(
                  'Écouter',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Progress counter
        Center(
          child: Text(
            'Bloc ${currentIndex + 1} / ${chunks.length}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: currentIndex < chunks.length - 1 ? onNext : null,
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  'Suivant',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReorderPhase extends StatefulWidget {
  final List<Map<String, dynamic>> chunks;

  const _ReorderPhase({required this.chunks});

  @override
  State<_ReorderPhase> createState() => _ReorderPhaseState();
}

class _ReorderPhaseState extends State<_ReorderPhase> {
  late List<Map<String, dynamic>> _reorderedItems;

  @override
  void initState() {
    super.initState();
    _reorderedItems = List.from(widget.chunks);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '✋ Réordonner les blocs',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Faites glisser les blocs pour les réordonner correctement.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _reorderedItems.removeAt(oldIndex);
              _reorderedItems.insert(newIndex, item);
            });
          },
          children: _reorderedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final chunk = entry.value;
            return Container(
              key: ValueKey(chunk['text']),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      chunk['text'],
                      style: TextStyle(
                        fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    chunk['meaning'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.drag_handle,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ordre vérifié! ✓'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text(
            'Vérifier l\'ordre',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _VerseReconstructionPhase extends StatelessWidget {
  final List<Map<String, dynamic>> chunks;

  const _VerseReconstructionPhase({required this.chunks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🎯 Reconstruire le verset',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Assemblez les blocs pour former le verset complet.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Verse display area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Text(
                  'Verset complet:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...chunks.map((chunk) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      chunk['text'],
                      style: TextStyle(
                        fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                        fontSize: 20,
                        color: AppColors.primary,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Chunks to place (mock)
        Text(
          'Blocs à placer:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chunks.map((chunk) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  chunk['text'],
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verset reconstitué! 🎉'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text(
            'Valider',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

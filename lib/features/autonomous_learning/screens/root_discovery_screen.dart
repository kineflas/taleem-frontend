import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Root Discovery screen (Module 4).
/// Phases: Tree visualization → Find intruder → Guess meaning
class RootDiscoveryScreen extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int phase;

  const RootDiscoveryScreen({
    super.key,
    required this.moduleNumber,
    required this.phase,
  });

  @override
  ConsumerState<RootDiscoveryScreen> createState() => _RootDiscoveryScreenState();
}

class _RootDiscoveryScreenState extends ConsumerState<RootDiscoveryScreen> {
  int _selectedIntruderIndex = -1;
  int _selectedMeaningIndex = -1;
  bool _answered = false;

  final List<Map<String, dynamic>> _rootExamples = [
    {
      'root': 'ك-ت-ب',
      'meaning': 'Écrire',
      'derivations': [
        {'word': 'كتاب', 'meaning': 'Livre'},
        {'word': 'كاتب', 'meaning': 'Écrivain'},
        {'word': 'مكتب', 'meaning': 'Bureau'},
        {'word': 'كتب', 'meaning': 'Écrit'},
      ],
      'intruder': {'word': 'سفر', 'meaning': 'Voyager', 'root': 'س-ف-ر'},
    },
    {
      'root': 'ع-ل-م',
      'meaning': 'Savoir, Science',
      'derivations': [
        {'word': 'علم', 'meaning': 'Science, Drapeau'},
        {'word': 'عالم', 'meaning': 'Savant'},
        {'word': 'علامة', 'meaning': 'Signe'},
        {'word': 'تعليم', 'meaning': 'Enseignement'},
      ],
      'intruder': {'word': 'نور', 'meaning': 'Lumière', 'root': 'ن-و-ر'},
    },
  ];

  late int _currentExampleIndex;

  @override
  void initState() {
    super.initState();
    _currentExampleIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text("L'ADN des mots"),
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
                    _TreePhase(example: _rootExamples[0])
                  else if (widget.phase == 2)
                    _IntruderPhase(
                      example: _rootExamples[0],
                      selectedIndex: _selectedIntruderIndex,
                      onSelect: (index) {
                        if (!_answered) {
                          setState(() => _selectedIntruderIndex = index);
                          _checkIntruderAnswer(index, _rootExamples[0]);
                        }
                      },
                      answered: _answered,
                    )
                  else
                    _GuessMeaningPhase(
                      example: _rootExamples[1],
                      selectedIndex: _selectedMeaningIndex,
                      onSelect: (index) {
                        if (!_answered) {
                          setState(() => _selectedMeaningIndex = index);
                          _checkMeaningAnswer(index);
                        }
                      },
                      answered: _answered,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkIntruderAnswer(int index, Map<String, dynamic> example) {
    final derivations = List<Map<String, dynamic>>.from(example['derivations']);
    final isCorrect = index == derivations.length; // Intruder is last

    setState(() => _answered = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? '✅ Correct!' : '❌ Essayez encore'),
        backgroundColor: isCorrect ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkMeaningAnswer(int index) {
    final correctIndex = 0;
    final isCorrect = index == correctIndex;

    setState(() => _answered = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? '✅ Correct!' : '❌ Essayez encore'),
        backgroundColor: isCorrect ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TreePhase extends StatelessWidget {
  final Map<String, dynamic> example;

  const _TreePhase({required this.example});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '👁️ Voir l\'arbre des racines',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Observez comment la racine génère une famille de mots.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Root (trunk)
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        example['root'],
                        style: TextStyle(
                          fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      example['meaning'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tree trunk visual
              Container(
                width: 4,
                height: 30,
                color: AppColors.primary.withOpacity(0.3),
              ),

              const SizedBox(height: 20),

              // Branches (derivations)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: (example['derivations'] as List)
                    .map((derivation) {
                      return _DerivationBranch(
                        word: derivation['word'],
                        meaning: derivation['meaning'],
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Remarquez: Tous les mots dérivés contiennent les mêmes lettres de racine (${example['root']}) dans le même ordre.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _DerivationBranch extends StatelessWidget {
  final String word;
  final String meaning;

  const _DerivationBranch({required this.word, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              word,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meaning,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IntruderPhase extends StatelessWidget {
  final Map<String, dynamic> example;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool answered;

  const _IntruderPhase({
    required this.example,
    required this.selectedIndex,
    required this.onSelect,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final derivations = List<Map<String, dynamic>>.from(example['derivations']);
    final intruder = example['intruder'] as Map<String, dynamic>;

    // Shuffle the order with intruder
    final allWords = [...derivations, intruder];
    allWords.shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '✋ Trouvez l\'intrus',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '3 mots partagent la racine ${example['root']}, 1 ne l\'a pas. Lequel est l\'intrus?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Word cards
        ...allWords.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          final isIntruder = word == intruder;
          final isSelected = selectedIndex == index;
          final revealed = answered && isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: answered ? null : () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: revealed && isIntruder
                      ? AppColors.danger.withOpacity(0.15)
                      : revealed && !isIntruder
                          ? AppColors.success.withOpacity(0.15)
                          : Colors.white,
                  border: Border.all(
                    color: revealed
                        ? (isIntruder ? AppColors.danger : AppColors.success)
                        : (isSelected
                            ? AppColors.accent
                            : AppColors.divider),
                    width: revealed || isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              word['word'],
                              style: TextStyle(
                                fontFamily:
                                    GoogleFonts.scheherazadeNew().fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word['meaning'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (revealed)
                      Icon(
                        isIntruder ? Icons.close : Icons.check,
                        color: isIntruder ? AppColors.danger : AppColors.success,
                        size: 28,
                      )
                    else
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.accent : AppColors.textHint,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _GuessMeaningPhase extends StatelessWidget {
  final Map<String, dynamic> example;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool answered;

  const _GuessMeaningPhase({
    required this.example,
    required this.selectedIndex,
    required this.onSelect,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    const newWord = {
      'word': 'تعليم',
      'correctMeaning': 'Enseignement',
    };
    final wrongMeanings = ['Voyage', 'Nourriture', 'Combat'];
    final allMeanings = [newWord['correctMeaning'], ...wrongMeanings];
    allMeanings.shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🎯 Devinez le sens',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Basé sur la racine ${example['root']}, devinez le sens de ce nouveau mot:',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Target word
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              newWord['word']!,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Quelle est la meilleure traduction?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Meaning options
        ...allMeanings.asMap().entries.map((entry) {
          final index = entry.key;
          final meaning = entry.value;
          final isCorrect = meaning == newWord['correctMeaning'];
          final isSelected = selectedIndex == index;
          final revealed = answered && isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: answered ? null : () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: revealed
                      ? (isCorrect
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.danger.withOpacity(0.15))
                      : Colors.white,
                  border: Border.all(
                    color: revealed
                        ? (isCorrect ? AppColors.success : AppColors.danger)
                        : (isSelected
                            ? AppColors.accent
                            : AppColors.divider),
                    width: revealed || isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        meaning ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: revealed
                              ? (isCorrect
                                  ? AppColors.success
                                  : AppColors.danger)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (revealed)
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? AppColors.success : AppColors.danger,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

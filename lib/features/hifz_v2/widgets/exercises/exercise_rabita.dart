/// ExerciseRabita — Test des enchaînements entre versets (Phase 3).
///
/// Principe : L'utilisateur voit la fin du verset N et doit identifier
/// le début du verset N+1 parmi 3 choix (MCQ).
///
/// Pour N versets, il y a N-1 transitions à tester.
/// Score = % de transitions correctement identifiées.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

class ExerciseRabita extends StatefulWidget {
  const ExerciseRabita({
    super.key,
    required this.verses,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final void Function(int score) onComplete;

  @override
  State<ExerciseRabita> createState() => _ExerciseRabitaState();
}

class _ExerciseRabitaState extends State<ExerciseRabita> {
  late List<_Transition> _transitions;
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedChoice;

  @override
  void initState() {
    super.initState();
    _buildTransitions();
  }

  void _buildTransitions() {
    final rng = Random();
    _transitions = [];

    for (var i = 0; i < widget.verses.length - 1; i++) {
      final current = widget.verses[i];
      final next = widget.verses[i + 1];

      // Fin du verset courant : les 3-4 derniers mots
      final endWords = current.words;
      final endCount = min(4, endWords.length);
      final endText = endWords.sublist(endWords.length - endCount).join(' ');

      // Début du verset suivant : les 3-4 premiers mots
      final startWords = next.words;
      final startCount = min(4, startWords.length);
      final correctAnswer = startWords.sublist(0, startCount).join(' ');

      // Générer 2 distracteurs à partir d'autres versets
      final distractors = <String>[];
      final candidates = widget.verses
          .where((v) => v.verseNumber != next.verseNumber)
          .toList()
        ..shuffle(rng);

      for (final c in candidates) {
        if (distractors.length >= 2) break;
        final cWords = c.words;
        final cCount = min(4, cWords.length);
        final distractor = cWords.sublist(0, cCount).join(' ');
        if (distractor != correctAnswer && !distractors.contains(distractor)) {
          distractors.add(distractor);
        }
      }

      // Si pas assez de distracteurs (< 3 versets), générer des fragments uniques
      int fallbackAttempts = 0;
      while (distractors.length < 2 && fallbackAttempts < 20) {
        fallbackAttempts++;
        final fallback = widget.verses[rng.nextInt(widget.verses.length)];
        final fWords = fallback.words;
        String candidate;
        if (fWords.length > 4) {
          final start = rng.nextInt(fWords.length - 3);
          candidate = fWords.sublist(start, start + 3).join(' ');
        } else if (fWords.length > 2) {
          // Take middle portion or reversed to create variety
          final start = rng.nextInt(max(1, fWords.length - 2));
          candidate = fWords.sublist(start, min(start + 3, fWords.length)).join(' ');
        } else {
          candidate = fWords.join(' ') + ' ...';
        }
        // Only add if truly different from correct answer and other distractors
        if (candidate != correctAnswer && !distractors.contains(candidate)) {
          distractors.add(candidate);
        }
      }
      // Ultimate fallback: use verse number reference as distractor
      while (distractors.length < 2) {
        distractors.add('...');
      }

      // Mélanger les choix
      final choices = [correctAnswer, ...distractors]..shuffle(rng);
      final correctIdx = choices.indexOf(correctAnswer);

      _transitions.add(_Transition(
        verseEndRef: current.reference,
        endText: endText,
        nextVerseRef: next.reference,
        choices: choices,
        correctIndex: correctIdx,
      ));
    }
  }

  void _onChoiceSelected(int choiceIndex) {
    if (_answered) return;

    final isCorrect = choiceIndex == _transitions[_currentIndex].correctIndex;
    if (isCorrect) _correctCount++;

    setState(() {
      _selectedChoice = choiceIndex;
      _answered = true;
    });

    // Avancer après un court délai
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (_currentIndex + 1 < _transitions.length) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedChoice = null;
        });
      } else {
        // Terminé — calculer le score
        final score = _transitions.isNotEmpty
            ? (_correctCount * 100 / _transitions.length).round()
            : 100;
        widget.onComplete(score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_transitions.isEmpty) {
      // Moins de 2 versets → pas de transitions
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pas assez de versets pour tester les enchaînements',
                style: HifzTypo.body(color: HifzColors.textMedium)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.onComplete(100),
              style: HifzDecor.primaryButton,
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    }

    final t = _transitions[_currentIndex];
    final progress = (_currentIndex + 1) / _transitions.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Titre ──
          Text(
            'رابطة',
            style: HifzTypo.verse(size: 24, color: HifzColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            'Transition ${_currentIndex + 1}/${_transitions.length}',
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),

          const SizedBox(height: 12),

          // ── Barre de progression ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: HifzColors.ivoryDark,
              valueColor: const AlwaysStoppedAnimation(HifzColors.emerald),
              minHeight: 5,
            ),
          ),

          const SizedBox(height: 24),

          // ── Fin du verset courant ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HifzColors.ivoryWarm,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HifzColors.gold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Fin du verset ${t.verseEndRef}',
                  style: HifzTypo.body(color: HifzColors.textLight)
                      .copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  '... ${t.endText}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: HifzTypo.verse(size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Question ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded,
                  color: HifzColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quel est le début du verset suivant ?',
                style: HifzTypo.body(color: HifzColors.textDark)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Choix ──
          Expanded(
            child: ListView.separated(
              itemCount: t.choices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                Color bgColor = HifzColors.ivory;
                Color borderColor = HifzColors.ivoryDark;

                if (_answered) {
                  if (i == t.correctIndex) {
                    bgColor = HifzColors.correct.withOpacity(0.12);
                    borderColor = HifzColors.correct;
                  } else if (i == _selectedChoice) {
                    bgColor = HifzColors.wrong.withOpacity(0.12);
                    borderColor = HifzColors.wrong;
                  }
                } else if (i == _selectedChoice) {
                  bgColor = HifzColors.goldMuted;
                  borderColor = HifzColors.gold;
                }

                return GestureDetector(
                  onTap: () => _onChoiceSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // Numéro du choix
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _answered && i == t.correctIndex
                                ? HifzColors.correct
                                : _answered && i == _selectedChoice
                                    ? HifzColors.wrong
                                    : HifzColors.ivoryDark,
                          ),
                          alignment: Alignment.center,
                          child: _answered
                              ? Icon(
                                  i == t.correctIndex
                                      ? Icons.check
                                      : i == _selectedChoice
                                          ? Icons.close
                                          : null,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: HifzTypo.body(
                                      color: HifzColors.textMedium),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Texte arabe
                        Expanded(
                          child: Text(
                            t.choices[i],
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: HifzTypo.verse(size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Score en cours ──
          const SizedBox(height: 8),
          Text(
            '$_correctCount/${_currentIndex + (_answered ? 1 : 0)} correct${_correctCount > 1 ? 's' : ''}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
        ],
      ),
    );
  }
}

/// Représente une transition entre deux versets consécutifs.
class _Transition {
  const _Transition({
    required this.verseEndRef,
    required this.endText,
    required this.nextVerseRef,
    required this.choices,
    required this.correctIndex,
  });

  final String verseEndRef;
  final String endText;
  final String nextVerseRef;
  final List<String> choices;
  final int correctIndex;
}

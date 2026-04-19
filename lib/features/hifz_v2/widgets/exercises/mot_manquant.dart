import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

/// Le Mot Manquant (إكمال) — QCM : trouver le mot qui complète le verset.
///
/// Le verset s'affiche avec 1 à 2 mots remplacés par un blanc.
/// Pour chaque blanc, 4 options sont proposées (le bon mot + 3 distracteurs).
class MotManquant extends StatefulWidget {
  const MotManquant({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(ExerciseResult result) onComplete;

  @override
  State<MotManquant> createState() => _MotManquantState();
}

class _MotManquantState extends State<MotManquant> {
  late List<int> _blankIndices;
  late List<List<String>> _options; // Options pour chaque blanc
  final Map<int, String?> _answers = {};
  final Map<int, bool?> _feedback = {}; // true=correct, false=wrong, null=pending
  final _startTime = DateTime.now();
  int _errors = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _setupBlanks();
  }

  void _setupBlanks() {
    final words = widget.verse.words;
    final rng = Random(widget.verse.surahNumber * 100 + widget.verse.verseNumber);

    // Choisir 1-2 mots à masquer (pas le premier ni le dernier)
    final candidates = List.generate(words.length, (i) => i);
    if (candidates.length > 2) {
      candidates.removeAt(0);
      candidates.removeLast();
    }
    candidates.shuffle(rng);
    final blankCount = words.length <= 4 ? 1 : 2;
    _blankIndices = candidates.take(blankCount).toList()..sort();

    // Générer les options pour chaque blanc
    _options = _blankIndices.map((idx) {
      final correct = words[idx];
      // Distracteurs : mots du même verset ou mots proches
      final distractors = <String>[];
      final available = List<String>.from(words)..remove(correct);
      available.shuffle(rng);
      distractors.addAll(available.take(3));

      // Compléter avec des mots génériques si pas assez de distracteurs
      final fallbacks = ['هُوَ', 'الَّذِي', 'مِنْ', 'فِي', 'عَلَى', 'إِلَى', 'لَهُ'];
      fallbacks.shuffle(rng);
      while (distractors.length < 3) {
        final fb = fallbacks.removeAt(0);
        if (fb != correct && !distractors.contains(fb)) {
          distractors.add(fb);
        }
      }

      final opts = [correct, ...distractors.take(3)];
      opts.shuffle(rng);
      return opts;
    }).toList();
  }

  void _onOptionSelected(int blankIdx, String word) {
    if (_feedback[blankIdx] != null) return; // Déjà répondu

    final correct = widget.verse.words[_blankIndices[blankIdx]];
    final isCorrect = word == correct;

    HapticFeedback.lightImpact();
    setState(() {
      _answers[blankIdx] = word;
      _feedback[blankIdx] = isCorrect;
      if (!isCorrect) _errors++;
    });

    // Vérifier si tous les blancs sont remplis
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_feedback.length == _blankIndices.length &&
          _feedback.values.every((f) => f != null)) {
        _complete();
      }
    });
  }

  void _complete() {
    setState(() => _isComplete = true);
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    final correctCount = _feedback.values.where((f) => f == true).length;
    final score = (correctCount / _blankIndices.length * 100).round();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      widget.onComplete(ExerciseResult(
        type: ExerciseType.motManquant,
        isCorrect: _errors == 0,
        responseTimeMs: ms,
        score: score,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Titre
          Text(
            'Le Mot Manquant',
            style: HifzTypo.sectionTitle(color: HifzColors.emeraldDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Complète le verset',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 20),

          // ── Verset avec trous ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: HifzDecor.card,
            child: Wrap(
              alignment: WrapAlignment.center,
              textDirection: TextDirection.rtl,
              spacing: 6,
              runSpacing: 14,
              children: List.generate(widget.verse.words.length, (i) {
                final blankPos = _blankIndices.indexOf(i);
                if (blankPos >= 0) {
                  return _buildBlank(blankPos, i);
                }
                return Text(
                  widget.verse.words[i],
                  style: HifzTypo.verse(size: 24),
                  textDirection: TextDirection.rtl,
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Options pour chaque blanc ──
          ..._blankIndices.asMap().entries.map((entry) {
            final blankIdx = entry.key;
            if (_feedback[blankIdx] != null) return const SizedBox.shrink();

            return Column(
              children: [
                Text(
                  'Mot ${blankIdx + 1}',
                  style: HifzTypo.body(color: HifzColors.textLight),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _options[blankIdx].map((opt) {
                    return GestureDetector(
                      onTap: () => _onOptionSelected(blankIdx, opt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: HifzColors.ivory,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HifzColors.gold.withOpacity(0.4)),
                        ),
                        child: Text(
                          opt,
                          style: HifzTypo.verse(size: 20),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBlank(int blankIdx, int wordIdx) {
    final fb = _feedback[blankIdx];
    final answer = _answers[blankIdx];
    final correct = widget.verse.words[wordIdx];

    if (fb == true) {
      // Correct — afficher en vert
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: HifzColors.correct.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          correct,
          style: HifzTypo.verse(size: 24, color: HifzColors.correct),
          textDirection: TextDirection.rtl,
        ),
      );
    } else if (fb == false) {
      // Faux — afficher le bon mot en vert avec la réponse barrée
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            correct,
            style: HifzTypo.verse(size: 24, color: HifzColors.correct),
            textDirection: TextDirection.rtl,
          ),
          Text(
            answer ?? '',
            style: HifzTypo.verse(size: 14, color: HifzColors.wrong).copyWith(
              decoration: TextDecoration.lineThrough,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      );
    }

    // Blanc non répondu
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: HifzColors.gold, width: 2)),
      ),
      child: Text(
        '   ?   ',
        style: HifzTypo.verse(size: 24, color: HifzColors.gold),
      ),
    );
  }
}

/// ExerciseTakamul — Complétion multi-versets avec trous (QCM).
///
/// Affiche tous les versets du groupe avec des mots manquants
/// répartis sur l'ensemble. L'utilisateur tape sur un trou pour
/// choisir le bon mot parmi 4 propositions.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

class ExerciseTakamul extends StatefulWidget {
  const ExerciseTakamul({
    super.key,
    required this.verses,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final void Function(int score) onComplete;

  @override
  State<ExerciseTakamul> createState() => _ExerciseTakamulState();
}

class _ExerciseTakamulState extends State<ExerciseTakamul> {
  final _rng = Random();

  /// Each gap: which verse index, which word index, correct word, user answer
  late List<_Gap> _gaps;
  int _currentGapIndex = 0;
  bool _allDone = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _gaps = _generateGaps();
    // If no gaps could be generated (all verses too short), auto-complete
    if (_gaps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onComplete(100);
        }
      });
    }
  }

  List<_Gap> _generateGaps() {
    final gaps = <_Gap>[];

    for (var vi = 0; vi < widget.verses.length; vi++) {
      final verse = widget.verses[vi];
      final words = verse.words;
      if (words.length < 3) continue;

      // 1-2 gaps per verse, never the first word
      final gapCount = words.length >= 8 ? 2 : 1;
      final candidates = List.generate(words.length - 1, (i) => i + 1);
      candidates.shuffle(_rng);

      for (var g = 0; g < min(gapCount, candidates.length); g++) {
        gaps.add(_Gap(
          verseIndex: vi,
          wordIndex: candidates[g],
          correctWord: words[candidates[g]],
        ));
      }
    }

    // Shuffle gaps so they don't appear in verse order
    gaps.shuffle(_rng);
    return gaps;
  }

  /// Generate 4 choices for the current gap (1 correct + 3 distractors)
  List<String> _choicesFor(_Gap gap) {
    final correctWord = gap.correctWord;
    final allWords = <String>{};

    // Collect words from all verses as potential distractors
    for (final v in widget.verses) {
      for (final w in v.words) {
        if (w != correctWord && w.length > 1) {
          allWords.add(w);
        }
      }
    }

    final distractors = allWords.toList()..shuffle(_rng);
    final choices = [correctWord, ...distractors.take(3)];

    // Pad if not enough distractors
    while (choices.length < 4) {
      choices.add('ـــ');
    }

    choices.shuffle(_rng);
    return choices;
  }

  void _selectAnswer(String word) {
    final gap = _gaps[_currentGapIndex];
    final isCorrect = word == gap.correctWord;

    setState(() {
      gap.userAnswer = word;
      gap.isCorrect = isCorrect;
      if (isCorrect) _correctCount++;

      if (_currentGapIndex + 1 < _gaps.length) {
        _currentGapIndex++;
      } else {
        _allDone = true;
        final score = (_correctCount / _gaps.length * 100).round();
        Future.delayed(const Duration(seconds: 2), () {
          widget.onComplete(score);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final score =
        _allDone ? (_correctCount / _gaps.length * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'أكمل الفراغات',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: HifzTypo.verse(size: 22, color: HifzColors.gold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Comble les trous dans les versets (${_currentGapIndex + 1}/${_gaps.length})',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),
        ),
        const SizedBox(height: 12),

        // ── Progress bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _gaps.isEmpty
                  ? 0
                  : (_currentGapIndex + (_allDone ? 1 : 0)) / _gaps.length,
              minHeight: 6,
              backgroundColor: HifzColors.ivoryDark,
              valueColor:
                  const AlwaysStoppedAnimation(HifzColors.emerald),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_allDone)
          // ── Score final ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: HifzTypo.score(
                      color: score >= 70
                          ? HifzColors.correct
                          : HifzColors.wrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_correctCount/${_gaps.length} correct',
                    style: HifzTypo.body(color: HifzColors.textMedium),
                  ),
                ],
              ),
            ),
          )
        else
          // ── Current verse with gap + choices ──
          Expanded(child: _buildCurrentGap()),
      ],
    );
  }

  Widget _buildCurrentGap() {
    if (_gaps.isEmpty) return const SizedBox.shrink();
    final gap = _gaps[_currentGapIndex];
    final verse = widget.verses[gap.verseIndex];
    final words = verse.words;
    final choices = _choicesFor(gap);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Verse reference ──
          Text(
            'Verset ${verse.verseNumber}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
          const SizedBox(height: 12),

          // ── Verse text with gap ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: HifzDecor.card,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 10,
                children: List.generate(words.length, (wi) {
                  if (wi == gap.wordIndex) {
                    // This is the gap
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: HifzColors.goldMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HifzColors.gold.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '؟',
                        style: HifzTypo.verse(
                            size: 20, color: HifzColors.gold),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      words[wi],
                      style: HifzTypo.verse(size: 20),
                    ),
                  );
                }),
              ),
            ),
          ),

          const Spacer(),

          // ── 4 choices ──
          ...choices.map((word) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _selectAnswer(word),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HifzColors.textDark,
                      side: const BorderSide(color: HifzColors.ivoryDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      word,
                      textDirection: TextDirection.rtl,
                      style: HifzTypo.verse(size: 18),
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Internal model for a gap in the exercise.
class _Gap {
  _Gap({
    required this.verseIndex,
    required this.wordIndex,
    required this.correctWord,
    this.userAnswer,
    this.isCorrect,
  });

  final int verseIndex;
  final int wordIndex;
  final String correctWord;
  String? userAnswer;
  bool? isCorrect;
}

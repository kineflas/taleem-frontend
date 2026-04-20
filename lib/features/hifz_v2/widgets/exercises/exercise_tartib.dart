/// ExerciseTartib — Ordonnancement des versets par drag-and-drop.
///
/// L'utilisateur reçoit N versets dans le désordre et doit les
/// remettre dans le bon ordre. Score = % de versets bien placés.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

class ExerciseTartib extends StatefulWidget {
  const ExerciseTartib({
    super.key,
    required this.verses,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final void Function(int score) onComplete;

  @override
  State<ExerciseTartib> createState() => _ExerciseTartibState();
}

class _ExerciseTartibState extends State<ExerciseTartib> {
  late List<EnrichedVerse> _shuffled;
  late List<int> _correctOrder;
  bool _submitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _correctOrder =
        List.generate(widget.verses.length, (i) => i); // 0,1,2,...

    // Shuffle until actually different from correct
    _shuffled = List.of(widget.verses);
    final rng = Random();
    do {
      _shuffled.shuffle(rng);
    } while (_shuffled.length > 1 && _isAlreadyCorrect());
  }

  bool _isAlreadyCorrect() {
    for (var i = 0; i < _shuffled.length; i++) {
      if (_shuffled[i].verseNumber != widget.verses[i].verseNumber) {
        return false;
      }
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_submitted) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _shuffled.removeAt(oldIndex);
      _shuffled.insert(newIndex, item);
    });
  }

  void _submit() {
    int correct = 0;
    for (var i = 0; i < _shuffled.length; i++) {
      if (_shuffled[i].verseNumber == widget.verses[i].verseNumber) {
        correct++;
      }
    }
    final score = (correct / _shuffled.length * 100).round();

    setState(() {
      _submitted = true;
      _score = score;
    });

    // Delay to show feedback before completing
    Future.delayed(const Duration(seconds: 2), () {
      widget.onComplete(score);
    });
  }

  /// Tronque le texte arabe aux N premiers mots + "..."
  String _truncateAr(String text, {int maxWords = 5}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')} …';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Text(
            'رتّب الآيات',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: HifzTypo.verse(size: 22, color: HifzColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            'Remets les versets dans le bon ordre',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),
          const SizedBox(height: 16),

          // ── Reorderable list ──
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: !_submitted,
              onReorder: _onReorder,
              itemCount: _shuffled.length,
              proxyDecorator: (child, index, anim) {
                return AnimatedBuilder(
                  animation: anim,
                  builder: (ctx, child) => Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    color: HifzColors.goldMuted,
                    child: child,
                  ),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final verse = _shuffled[index];
                final isCorrectPosition = _submitted &&
                    verse.verseNumber == widget.verses[index].verseNumber;
                final isWrongPosition = _submitted && !isCorrectPosition;

                return Container(
                  key: ValueKey(verse.verseNumber),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _submitted
                        ? (isCorrectPosition
                            ? HifzColors.correct.withOpacity(0.1)
                            : HifzColors.wrong.withOpacity(0.1))
                        : HifzColors.ivoryWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _submitted
                          ? (isCorrectPosition
                              ? HifzColors.correct.withOpacity(0.5)
                              : HifzColors.wrong.withOpacity(0.5))
                          : HifzColors.ivoryDark,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Numéro de position
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _submitted
                                ? (isCorrectPosition
                                    ? HifzColors.correct
                                    : HifzColors.wrong)
                                : HifzColors.emerald.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: HifzTypo.body(
                              color: _submitted
                                  ? HifzColors.ivory
                                  : HifzColors.emerald,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Texte du verset (tronqué)
                        Expanded(
                          child: Text(
                            _truncateAr(verse.textAr),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: HifzTypo.verse(size: 16),
                          ),
                        ),

                        // Drag handle or status icon
                        if (!_submitted)
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.drag_handle,
                                  color: HifzColors.textLight),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              isCorrectPosition
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isCorrectPosition
                                  ? HifzColors.correct
                                  : HifzColors.wrong,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Score ou bouton ──
          if (_submitted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '$_score%',
                textAlign: TextAlign.center,
                style: HifzTypo.score(
                  color: _score >= 70 ? HifzColors.correct : HifzColors.wrong,
                ).copyWith(fontSize: 36),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                onPressed: _submit,
                style: HifzDecor.primaryButton,
                child: const Text('Valider l\'ordre'),
              ),
            ),
        ],
      ),
    );
  }
}

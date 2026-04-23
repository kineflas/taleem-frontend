import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';

/// Le Puzzle de Lumière (ترتيب) — Remettre les mots du verset dans l'ordre.
///
/// Les mots sont affichés en désordre dans une zone "source".
/// L'élève les tap pour les placer dans la zone "résultat" (ordre de lecture RTL).
/// Feedback immédiat : vert si bon placement, retour en source si erreur.
class PuzzleLumiere extends StatefulWidget {
  const PuzzleLumiere({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(ExerciseResult result) onComplete;

  @override
  State<PuzzleLumiere> createState() => _PuzzleLumiereState();
}

class _PuzzleLumiereState extends State<PuzzleLumiere> {
  late List<String> _correctOrder;
  /// Indices into _correctOrder, shuffled. Each entry is a unique index.
  late List<int> _shuffledIndices;
  final List<String> _placedWords = [];
  int _errors = 0;
  final _startTime = DateTime.now();
  bool _isComplete = false;
  int? _lastErrorIdx; // Index erroné pour feedback

  @override
  void initState() {
    super.initState();
    _correctOrder = List.from(widget.verse.words);
    _shuffledIndices = List.generate(_correctOrder.length, (i) => i);
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    // Assurer que l'ordre mélangé est différent de l'original
    do {
      _shuffledIndices.shuffle(rng);
    } while (_shuffledIndices.length > 2 &&
        _listEquals(_shuffledIndices, List.generate(_correctOrder.length, (i) => i)));
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onWordTap(int originalIndex) {
    if (_isComplete) return;

    // The next expected original index is simply the count of placed words
    final nextExpectedIdx = _placedWords.length;

    if (originalIndex == nextExpectedIdx) {
      // Correct
      HapticFeedback.lightImpact();
      setState(() {
        _placedWords.add(_correctOrder[originalIndex]);
        _shuffledIndices.remove(originalIndex);
        _lastErrorIdx = null;
      });

      if (_placedWords.length == _correctOrder.length) {
        _complete();
      }
    } else {
      // Erreur
      HapticFeedback.mediumImpact();
      setState(() {
        _errors++;
        _lastErrorIdx = originalIndex;
      });
      // Réinitialiser le feedback après 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _lastErrorIdx = null);
      });
    }
  }

  void _complete() {
    setState(() => _isComplete = true);
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    final total = _correctOrder.length;
    final score = (((total - _errors) / total) * 100).round().clamp(0, 100);

    // Petite pause pour montrer le résultat complet
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      widget.onComplete(ExerciseResult(
        type: ExerciseType.puzzleLumiere,
        isCorrect: _errors == 0,
        responseTimeMs: ms,
        score: score,
        details: '$_errors erreur(s) sur $total mots',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Titre ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: HifzColors.gold.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Le Puzzle de Lumière',
                style: HifzTypo.sectionTitle(color: HifzColors.emeraldDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Remets les mots dans le bon ordre',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 20),

          // ── Zone résultat (mots placés) ──
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HifzColors.ivoryWarm,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isComplete ? HifzColors.correct : HifzColors.ivoryDark,
                width: _isComplete ? 2 : 1,
              ),
            ),
            child: _placedWords.isEmpty
                ? Center(
                    child: Text(
                      'Appuie sur les mots ci-dessous',
                      style: HifzTypo.body(color: HifzColors.textLight),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 8,
                    children: _placedWords.map((w) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HifzColors.emeraldMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: HifzColors.emerald.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          w,
                          style: HifzTypo.verse(size: 22, color: HifzColors.emerald),
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // ── Indicateur de position ──
          if (!_isComplete && _placedWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_placedWords.length}/${_correctOrder.length}',
                style: HifzTypo.body(color: HifzColors.textLight),
              ),
            ),

          const SizedBox(height: 20),

          // ── Zone source (mots mélangés) ──
          if (!_isComplete)
            Wrap(
              alignment: WrapAlignment.center,
              textDirection: TextDirection.rtl,
              spacing: 10,
              runSpacing: 12,
              children: _shuffledIndices.map((origIdx) {
                final w = _correctOrder[origIdx];
                final isError = origIdx == _lastErrorIdx;
                return GestureDetector(
                  onTap: () => _onWordTap(origIdx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isError
                          ? HifzColors.wrong.withOpacity(0.12)
                          : HifzColors.ivory,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isError ? HifzColors.wrong : HifzColors.gold.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      w,
                      style: HifzTypo.verse(
                        size: 24,
                        color: isError ? HifzColors.wrong : HifzColors.textDark,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              }).toList(),
            ),

          // ── Résultat ──
          if (_isComplete) ...[
            const SizedBox(height: 24),
            Icon(
              _errors == 0 ? Icons.check_circle : Icons.info_outline,
              color: _errors == 0 ? HifzColors.correct : HifzColors.close,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _errors == 0 ? 'Parfait !' : '$_errors erreur${_errors > 1 ? 's' : ''}',
              style: HifzTypo.sectionTitle(
                color: _errors == 0 ? HifzColors.correct : HifzColors.close,
              ),
            ),
          ],

          // ── Compteur d'erreurs ──
          if (_errors > 0 && !_isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$_errors erreur${_errors > 1 ? 's' : ''}',
                style: HifzTypo.body(color: HifzColors.wrong),
              ),
            ),
        ],
      ),
    );
  }
}

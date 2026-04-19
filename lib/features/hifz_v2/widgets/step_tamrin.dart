import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import 'exercises/puzzle_lumiere.dart';
import 'exercises/verset_miroir.dart';
import 'exercises/mot_manquant.dart';

/// Étape 3 — TAMRIN (تمرين) : Exercices interactifs.
///
/// Sélectionne 3 exercices parmi les types disponibles pour ce verset.
/// Les exercices se succèdent inline, pas de nouvel écran.
class StepTamrin extends StatefulWidget {
  const StepTamrin({
    super.key,
    required this.verse,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final void Function(StepResult result) onComplete;

  @override
  State<StepTamrin> createState() => _StepTamrinState();
}

class _StepTamrinState extends State<StepTamrin> {
  late List<ExerciseType> _selectedExercises;
  int _currentExerciseIdx = 0;
  final List<ExerciseResult> _results = [];
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectExercises();
  }

  void _selectExercises() {
    // Toujours inclure le Puzzle de Lumière et le Verset Miroir
    // + un exercice aléatoire supplémentaire
    final rng = Random(
      widget.verse.surahNumber * 1000 + widget.verse.verseNumber + DateTime.now().day,
    );

    final extra = [
      ExerciseType.motManquant,
      ExerciseType.vraiOuFaux,
      ExerciseType.debutFin,
    ];
    extra.shuffle(rng);

    _selectedExercises = [
      ExerciseType.puzzleLumiere,
      extra.first,
      ExerciseType.versetMiroir, // Toujours en dernier — le plus exigeant
    ];
  }

  void _onExerciseComplete(ExerciseResult result) {
    _results.add(result);

    if (_currentExerciseIdx + 1 < _selectedExercises.length) {
      setState(() => _currentExerciseIdx++);
    } else {
      _finishStep();
    }
  }

  void _finishStep() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    final scores = _results.map((r) => r.score).toList();
    final avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) ~/ scores.length;

    widget.onComplete(StepResult(
      step: WirdStep.tamrin,
      score: avgScore,
      exerciseResults: _results,
      durationSeconds: duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _selectedExercises[_currentExerciseIdx];

    return Column(
      children: [
        // ── Label ──
        Text('TAMRIN', style: HifzTypo.stepLabel()),
        const SizedBox(height: 4),
        Text(
          'Exercice ${_currentExerciseIdx + 1}/${_selectedExercises.length}',
          style: HifzTypo.body(color: HifzColors.textLight),
        ),

        const SizedBox(height: 4),

        // ── Mini progression ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            children: List.generate(_selectedExercises.length, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < _currentExerciseIdx
                        ? HifzColors.emerald
                        : i == _currentExerciseIdx
                            ? HifzColors.gold
                            : HifzColors.ivoryDark,
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        // ── Exercice inline ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildExercise(exercise),
          ),
        ),
      ],
    );
  }

  Widget _buildExercise(ExerciseType type) {
    return switch (type) {
      ExerciseType.puzzleLumiere => PuzzleLumiere(
          key: ValueKey('puzzle_${_currentExerciseIdx}'),
          verse: widget.verse,
          onComplete: _onExerciseComplete,
        ),
      ExerciseType.versetMiroir => VersetMiroir(
          key: ValueKey('miroir_${_currentExerciseIdx}'),
          verse: widget.verse,
          onComplete: _onExerciseComplete,
        ),
      ExerciseType.motManquant => MotManquant(
          key: ValueKey('manquant_${_currentExerciseIdx}'),
          verse: widget.verse,
          onComplete: _onExerciseComplete,
        ),
      // Exercices supplémentaires — fallback vers Puzzle
      _ => PuzzleLumiere(
          key: ValueKey('fallback_${_currentExerciseIdx}'),
          verse: widget.verse,
          onComplete: _onExerciseComplete,
        ),
    };
  }
}

import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';
import 'fusion_exercise.dart';
import 'points_exercise.dart';
import 'audio_quiz_exercise.dart';
import 'completer_syllabe_exercise.dart';
import 'cameleon_exercise.dart';
import 'ecoute_comparative_exercise.dart';
import 'classifier_exercise.dart';
import 'mur_invisible_exercise.dart';
import 'thermometre_exercise.dart';
import 'speed_round_exercise.dart';
import 'dictee_exercise.dart';
import 'karaoke_exercise.dart';

/// Routes an [OdysseeExercise] to the correct widget based on its type.
class ExerciseRouter extends StatelessWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const ExerciseRouter({
    super.key,
    required this.exercise,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (exercise.type) {
      case 'FUSION':
        return FusionExercise(exercise: exercise, onComplete: onComplete);
      case 'POINTS':
        return PointsExercise(exercise: exercise, onComplete: onComplete);
      case 'AUDIO_QUIZ':
        return AudioQuizExercise(exercise: exercise, onComplete: onComplete);
      case 'COMPLETER_SYLLABE':
        return CompleterSyllabeExercise(exercise: exercise, onComplete: onComplete);
      case 'CAMELEON':
        return CameleonExercise(exercise: exercise, onComplete: onComplete);
      case 'ECOUTE_COMPARATIVE':
        return EcouteComparativeExercise(exercise: exercise, onComplete: onComplete);
      case 'CLASSIFIER':
        return ClassifierExercise(exercise: exercise, onComplete: onComplete);
      case 'MUR_INVISIBLE':
        return MurInvisibleExercise(exercise: exercise, onComplete: onComplete);
      case 'THERMOMETRE':
        return ThermometreExercise(exercise: exercise, onComplete: onComplete);
      case 'SPEED_ROUND':
        return SpeedRoundExercise(exercise: exercise, onComplete: onComplete);
      case 'DICTEE':
        return DicteeExercise(exercise: exercise, onComplete: onComplete);
      case 'KARAOKE':
        return KaraokeExercise(exercise: exercise, onComplete: onComplete);
      default:
        return _UnknownExercise(type: exercise.type, onComplete: onComplete);
    }
  }
}

class _UnknownExercise extends StatelessWidget {
  final String type;
  final void Function({bool correct}) onComplete;

  const _UnknownExercise({required this.type, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text('Type d\'exercice inconnu: $type',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => onComplete(correct: true),
            child: const Text('Passer'),
          ),
        ],
      ),
    );
  }
}

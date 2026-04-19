import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../services/audio_orchestrator.dart';
import '../widgets/step_nour.dart';
import '../widgets/step_tikrar.dart';
import '../widgets/step_tamrin.dart';
import '../widgets/step_tasmi.dart';
import '../widgets/step_natija.dart';
import '../widgets/wird_step_indicator.dart';

/// Écran principal du flow d'un verset — les 5 étapes séquentielles.
///
/// Pas de navigation entre écrans : les étapes se succèdent en place,
/// avec une transition douce (fade + slide vertical léger).
class WirdVerseFlowScreen extends ConsumerStatefulWidget {
  const WirdVerseFlowScreen({
    super.key,
    required this.verse,
    required this.reciterFolder,
    this.bloc = WirdBloc.jadid,
    this.onComplete,
  });

  final EnrichedVerse verse;
  final String reciterFolder;
  final WirdBloc bloc;
  final void Function(VerseSessionResult result)? onComplete;

  @override
  ConsumerState<WirdVerseFlowScreen> createState() => _WirdVerseFlowScreenState();
}

class _WirdVerseFlowScreenState extends ConsumerState<WirdVerseFlowScreen> {
  late WirdStep _currentStep;
  late AudioOrchestrator _orchestrator;
  final List<StepResult> _stepResults = [];
  final _startTime = DateTime.now();

  // ── Étapes disponibles selon le bloc ──
  late List<WirdStep> _steps;

  @override
  void initState() {
    super.initState();

    // Le flow complet pour JADID, raccourci pour les révisions
    switch (widget.bloc) {
      case WirdBloc.jadid:
        _steps = WirdStep.values.toList(); // 5 étapes
      case WirdBloc.qarib:
        _steps = [WirdStep.tamrin, WirdStep.tasmi, WirdStep.natija];
      case WirdBloc.baid:
        _steps = [WirdStep.tamrin, WirdStep.natija];
    }
    _currentStep = _steps.first;

    // Audio
    final audioUrl = _buildAudioUrl();
    _orchestrator = AudioOrchestrator(verseAudioUrl: audioUrl);
    _orchestrator.init();
  }

  String _buildAudioUrl() {
    final surah = widget.verse.surahNumber.toString().padLeft(3, '0');
    final verse = widget.verse.verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${widget.reciterFolder}/$surah$verse.mp3';
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    super.dispose();
  }

  void _onStepComplete(StepResult result) {
    _stepResults.add(result);

    // ── Soumettre le résultat de l'étape au backend (sauf Nour = écoute pure) ──
    if (result.step != WirdStep.nour) {
      _submitStepToBackend(result);
    }

    // ── Soumettre les exercices individuels (TAMRIN) ──
    if (result.step == WirdStep.tamrin) {
      for (final ex in result.exerciseResults) {
        _submitExerciseToBackend(ex);
      }
    }

    final idx = _steps.indexOf(_currentStep);
    if (idx + 1 < _steps.length) {
      final nextStep = _steps[idx + 1];
      // Si on arrive à Natija, le verset est considéré comme complété.
      // On prépare le résultat pour que Natija puisse l'afficher,
      // et on notifie le parent immédiatement pour sauvegarder la progression.
      if (nextStep == WirdStep.natija) {
        _prepareResult();
      }
      setState(() => _currentStep = nextStep);
    } else {
      // Dernier step sans Natija (ex: flow raccourci)
      _prepareResult();
      widget.onComplete?.call(_verseResult!);
    }
  }

  /// Envoie le résultat d'une étape au backend.
  Future<void> _submitStepToBackend(StepResult result) async {
    try {
      await ref.read(wirdSessionProvider.notifier).submitStep(
        surahNumber: widget.verse.surahNumber,
        verseNumber: widget.verse.verseNumber,
        step: result.step.name.toUpperCase(),
        score: result.score,
        durationSeconds: result.durationSeconds,
      );
    } catch (_) {
      // Ne pas bloquer le flow si le backend échoue
    }
  }

  /// Envoie le résultat d'un exercice au backend.
  Future<void> _submitExerciseToBackend(ExerciseResult result) async {
    try {
      await ref.read(wirdSessionProvider.notifier).submitExercise(
        surahNumber: widget.verse.surahNumber,
        verseNumber: widget.verse.verseNumber,
        exerciseType: result.type.key,
        isCorrect: result.isCorrect,
        responseTimeMs: result.responseTimeMs,
      );
    } catch (_) {
      // Ne pas bloquer le flow si le backend échoue
    }
  }

  VerseSessionResult? _verseResult;

  /// Prépare le résultat du verset (appelé avant Natija).
  void _prepareResult() {
    if (_verseResult != null) return; // Déjà calculé

    final exerciseScores = _stepResults
        .where((r) => r.score > 0)
        .map((r) => r.score)
        .toList();

    final avgScore = exerciseScores.isEmpty
        ? 0
        : exerciseScores.reduce((a, b) => a + b) ~/ exerciseScores.length;

    final stars = avgScore >= 90 ? 3 : avgScore >= 70 ? 2 : avgScore >= 50 ? 1 : 0;
    final xp = stars * 15 + avgScore ~/ 5;

    _verseResult = VerseSessionResult(
      verse: widget.verse,
      stepResults: _stepResults,
      finalScore: avgScore,
      stars: stars,
      xpEarned: xp,
    );
  }

  /// Appelé par Natija.onFinish → notifie le parent pour avancer au verset suivant.
  void _finishFlow() {
    _prepareResult();
    widget.onComplete?.call(_verseResult!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barre d'étapes ──
            _buildTopBar(),

            // ── Indicateur d'étapes ──
            WirdStepIndicator(
              steps: _steps,
              currentStep: _currentStep,
            ),

            const SizedBox(height: 8),

            // ── Contenu de l'étape ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            icon: const Icon(Icons.close, color: HifzColors.textLight),
            onPressed: () => _showExitConfirmation(),
          ),
          const Spacer(),
          // Référence du verset
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.verse.reference,
                style: HifzTypo.body(color: HifzColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      WirdStep.nour => StepNour(
          key: const ValueKey('nour'),
          verse: widget.verse,
          orchestrator: _orchestrator,
          onComplete: (result) => _onStepComplete(result),
        ),
      WirdStep.tikrar => StepTikrar(
          key: const ValueKey('tikrar'),
          verse: widget.verse,
          orchestrator: _orchestrator,
          onComplete: (result) => _onStepComplete(result),
        ),
      WirdStep.tamrin => StepTamrin(
          key: const ValueKey('tamrin'),
          verse: widget.verse,
          onComplete: (result) => _onStepComplete(result),
        ),
      WirdStep.tasmi => StepTasmi(
          key: const ValueKey('tasmi'),
          verse: widget.verse,
          onComplete: (result) => _onStepComplete(result),
        ),
      WirdStep.natija => StepNatija(
          key: const ValueKey('natija'),
          verse: widget.verse,
          stepResults: _stepResults,
          onFinish: () => _finishFlow(),
        ),
    };
  }

  void _showExitConfirmation() {
    // Si on est sur Natija, le verset est déjà complété → sauvegarder et quitter
    if (_verseResult != null) {
      widget.onComplete?.call(_verseResult!);
      // Quitter le Wird (retour au menu Hifz V2)
      if (mounted) Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HifzColors.ivoryWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Quitter le Wird ?', style: HifzTypo.sectionTitle()),
        content: Text(
          'Ta progression sur ce verset ne sera pas sauvegardée.',
          style: HifzTypo.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Continuer', style: HifzTypo.body(color: HifzColors.emerald)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Quitter', style: HifzTypo.body(color: HifzColors.wrong)),
          ),
        ],
      ),
    );
  }
}

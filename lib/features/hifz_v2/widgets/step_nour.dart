import 'package:flutter/material.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../services/audio_orchestrator.dart';

/// Étape 1 — NOUR (نور) : Illumination.
///
/// Triple encodage : auditif (récitateur) + visuel (texte arabe) + sémantique (traduction).
/// L'audio se lance automatiquement. Bouton "Suivant" après 2 écoutes minimum.
class StepNour extends StatefulWidget {
  const StepNour({
    super.key,
    required this.verse,
    required this.orchestrator,
    required this.onComplete,
  });

  final EnrichedVerse verse;
  final AudioOrchestrator orchestrator;
  final void Function(StepResult result) onComplete;

  @override
  State<StepNour> createState() => _StepNourState();
}

class _StepNourState extends State<StepNour> {
  int _listenCount = 0;
  bool _audioFinished = false;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Lancer l'audio automatiquement
    _playAudio();
  }

  Future<void> _playAudio() async {
    widget.orchestrator.onRepetitionComplete = () {
      setState(() {
        _listenCount++;
        _audioFinished = true;
      });
    };
    await widget.orchestrator.playOnce();
  }

  Future<void> _replayAudio() async {
    setState(() => _audioFinished = false);
    await widget.orchestrator.playOnce();
  }

  void _next() {
    widget.orchestrator.stop();
    final duration = DateTime.now().difference(_startTime).inSeconds;
    widget.onComplete(StepResult(
      step: WirdStep.nour,
      score: 0, // Pas de score pour l'étape de découverte
      durationSeconds: duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Label d'étape ──
          Text('NOUR', style: HifzTypo.stepLabel()),
          const SizedBox(height: 4),
          Text(
            'Découvre le sens',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 32),

          // ── Verset arabe ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: HifzDecor.card,
            child: Text(
              widget.verse.textAr,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: HifzTypo.verse(size: 30),
            ),
          ),

          const SizedBox(height: 20),

          // ── Traduction ──
          if (widget.verse.textFr != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HifzColors.emeraldMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.verse.textFr!,
                textAlign: TextAlign.center,
                style: HifzTypo.translation(size: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Contexte ──
          if (widget.verse.contextFr != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.verse.contextFr!,
                textAlign: TextAlign.center,
                style: HifzTypo.body(color: HifzColors.textLight),
              ),
            ),

          // ── Mot-clé ──
          if (widget.verse.keyWordAr != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: HifzColors.goldMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HifzColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.verse.keyWordAr!,
                    style: HifzTypo.verse(size: 20, color: HifzColors.gold),
                    textDirection: TextDirection.rtl,
                  ),
                  if (widget.verse.keyWordFr != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      widget.verse.keyWordFr!,
                      style: HifzTypo.body(color: HifzColors.textMedium),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // ── Compteur d'écoutes ──
          Text(
            '$_listenCount écoute${_listenCount > 1 ? 's' : ''}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 16),

          // ── Boutons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Réécouter
              OutlinedButton.icon(
                onPressed: _replayAudio,
                style: HifzDecor.secondaryButton.copyWith(
                  minimumSize: WidgetStatePropertyAll(const Size(140, 48)),
                ),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Réécouter'),
              ),

              const SizedBox(width: 16),

              // Suivant (actif après 2 écoutes)
              ElevatedButton(
                onPressed: _listenCount >= 2 ? _next : null,
                style: HifzDecor.primaryButton.copyWith(
                  minimumSize: WidgetStatePropertyAll(const Size(140, 52)),
                ),
                child: const Text('Suivant'),
              ),
            ],
          ),

          if (_listenCount < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Écoute au moins 2 fois avant de continuer',
                style: HifzTypo.body(color: HifzColors.textLight),
              ),
            ),
        ],
      ),
    );
  }
}

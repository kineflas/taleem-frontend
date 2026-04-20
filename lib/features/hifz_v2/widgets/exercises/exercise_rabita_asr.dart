/// ExerciseRabitaAsr — Test des enchaînements par récitation vocale (ASR).
///
/// Principe : L'utilisateur voit la fin du verset N et doit RÉCITER
/// le début du verset N+1 à voix haute. Le serveur ASR valide.
///
/// Pour N versets, il y a N-1 transitions à tester.
/// Score = % de transitions réussies (accuracy >= 0.7).
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/hifz_v2_theme.dart';
import '../../models/wird_models.dart';
import '../../services/asr_service.dart';

class ExerciseRabitaAsr extends StatefulWidget {
  const ExerciseRabitaAsr({
    super.key,
    required this.verses,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final void Function(int score) onComplete;

  @override
  State<ExerciseRabitaAsr> createState() => _ExerciseRabitaAsrState();
}

class _ExerciseRabitaAsrState extends State<ExerciseRabitaAsr> {
  late List<_AsrTransition> _transitions;
  int _currentIndex = 0;
  int _correctCount = 0;

  // ASR state
  final AsrService _asr = AsrService();
  bool _isRecording = false;
  bool _isValidating = false;
  bool _answered = false;
  _TransitionResult? _lastResult;

  // Timer pour la durée d'enregistrement
  int _recSeconds = 0;
  Timer? _recTimer;

  @override
  void initState() {
    super.initState();
    _buildTransitions();
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _asr.dispose();
    super.dispose();
  }

  void _buildTransitions() {
    _transitions = [];
    for (var i = 0; i < widget.verses.length - 1; i++) {
      final current = widget.verses[i];
      final next = widget.verses[i + 1];

      // Fin du verset courant : les 3-4 derniers mots
      final endWords = current.words;
      final endCount = min(4, endWords.length);
      final endText = endWords.sublist(endWords.length - endCount).join(' ');

      // Début du verset suivant : les 3-4 premiers mots (texte attendu pour ASR)
      final startWords = next.words;
      final startCount = min(4, startWords.length);
      final expectedText = startWords.sublist(0, startCount).join(' ');

      _transitions.add(_AsrTransition(
        verseEndRef: current.reference,
        endText: endText,
        nextVerseRef: next.reference,
        expectedText: expectedText,
        fullNextText: next.textAr,
        surahNumber: next.surahNumber,
        verseNumber: next.verseNumber,
      ));
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _answered) return;

    try {
      await _asr.startRecording();
      _recSeconds = 0;
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recSeconds++);
      });
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro : $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _recTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isValidating = true;
    });

    final audioPath = await _asr.stopRecording();
    if (audioPath == null) {
      setState(() => _isValidating = false);
      return;
    }

    final t = _transitions[_currentIndex];

    // Valider via ASR
    final result = await _asr.validateRecording(
      audioPath: audioPath,
      expectedText: t.expectedText,
      words: t.expectedText.split(' '),
      recSeconds: _recSeconds,
      surahNumber: t.surahNumber,
      verseNumber: t.verseNumber,
      withTimestamps: false, // pas besoin de timestamps ici
    );

    await _asr.cleanup();

    final isCorrect = result.accuracy >= 0.7;
    if (isCorrect) _correctCount++;

    setState(() {
      _isValidating = false;
      _answered = true;
      _lastResult = _TransitionResult(
        isCorrect: isCorrect,
        accuracy: result.accuracy,
        transcription: result.transcription,
        expectedText: t.expectedText,
      );
    });

    // Avancer après un délai
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      if (_currentIndex + 1 < _transitions.length) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _lastResult = null;
        });
      } else {
        // Terminé
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
            'رابطة صوتية',
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

          // ── Instruction ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: HifzColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Récite le début du verset suivant',
                style: HifzTypo.body(color: HifzColors.textDark)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const Spacer(),

          // ── Zone centrale : bouton micro / validation / résultat ──
          if (_isValidating) ...[
            const CircularProgressIndicator(color: HifzColors.emerald),
            const SizedBox(height: 16),
            Text('Validation en cours...',
                style: HifzTypo.body(color: HifzColors.textMedium)),
          ] else if (_answered && _lastResult != null) ...[
            _buildResult(_lastResult!, t.expectedText),
          ] else ...[
            // Bouton micro
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isRecording ? 100 : 80,
                height: _isRecording ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? HifzColors.wrong.withOpacity(0.15)
                      : HifzColors.emerald.withOpacity(0.12),
                  border: Border.all(
                    color: _isRecording ? HifzColors.wrong : HifzColors.emerald,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 40,
                  color: _isRecording ? HifzColors.wrong : HifzColors.emerald,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording
                  ? 'Enregistrement... ${_recSeconds}s\nAppuie pour arrêter'
                  : 'Appuie pour enregistrer',
              textAlign: TextAlign.center,
              style: HifzTypo.body(
                color:
                    _isRecording ? HifzColors.wrong : HifzColors.textMedium,
              ),
            ),
          ],

          const Spacer(),

          // ── Score en cours ──
          Text(
            '$_correctCount/${_currentIndex + (_answered ? 1 : 0)} correct${_correctCount > 1 ? 's' : ''}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResult(_TransitionResult result, String expected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: result.isCorrect
            ? HifzColors.correct.withOpacity(0.08)
            : HifzColors.wrong.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isCorrect ? HifzColors.correct : HifzColors.wrong,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icône résultat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                result.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color:
                    result.isCorrect ? HifzColors.correct : HifzColors.wrong,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                result.isCorrect ? 'Correct !' : 'Pas tout à fait...',
                style: HifzTypo.body(
                  color: result.isCorrect
                      ? HifzColors.correct
                      : HifzColors.wrong,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '${(result.accuracy * 100).round()}%',
                style: HifzTypo.body(color: HifzColors.textMedium),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Ce qui était attendu
          Text(
            'Réponse attendue :',
            style: HifzTypo.body(color: HifzColors.textLight)
                .copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            expected,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: HifzTypo.verse(size: 18, color: HifzColors.emeraldDark),
          ),

          if (result.transcription.isNotEmpty &&
              result.transcription != '(simulation)') ...[
            const SizedBox(height: 10),
            Text(
              'Ce que tu as dit :',
              style: HifzTypo.body(color: HifzColors.textLight)
                  .copyWith(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              result.transcription,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: HifzTypo.verse(
                size: 18,
                color: result.isCorrect
                    ? HifzColors.textDark
                    : HifzColors.wrong,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Représente une transition à tester par ASR.
class _AsrTransition {
  const _AsrTransition({
    required this.verseEndRef,
    required this.endText,
    required this.nextVerseRef,
    required this.expectedText,
    required this.fullNextText,
    required this.surahNumber,
    required this.verseNumber,
  });

  final String verseEndRef;
  final String endText;
  final String nextVerseRef;
  final String expectedText; // Les 3-4 premiers mots du verset suivant
  final String fullNextText;
  final int surahNumber;
  final int verseNumber;
}

/// Résultat d'une transition ASR.
class _TransitionResult {
  const _TransitionResult({
    required this.isCorrect,
    required this.accuracy,
    required this.transcription,
    required this.expectedText,
  });

  final bool isCorrect;
  final double accuracy;
  final String transcription;
  final String expectedText;
}

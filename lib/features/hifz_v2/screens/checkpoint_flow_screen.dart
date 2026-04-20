/// CheckpointFlowScreen — Orchestre le flow Checkpoint Tarkibi.
///
/// 5 étapes séquentielles pour vérifier un groupe de versets :
///   ① Istima' (écoute globale)
///   ② Tartib (ordonnancement)
///   ③ Takamul (complétion multi-versets)
///   ④ Tasmi' (récitation cumulée — réutilise StepTasmi)
///   ⑤ Natija (résultats détaillés)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hifz_v2_service.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../services/audio_orchestrator.dart';
import '../widgets/exercises/exercise_tartib.dart';
import '../widgets/exercises/exercise_takamul.dart';

class CheckpointFlowScreen extends ConsumerStatefulWidget {
  const CheckpointFlowScreen({
    super.key,
    required this.verses,
    required this.reciterFolder,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final String reciterFolder;
  final void Function(CheckpointResult result) onComplete;

  @override
  ConsumerState<CheckpointFlowScreen> createState() =>
      _CheckpointFlowScreenState();
}

class _CheckpointFlowScreenState extends ConsumerState<CheckpointFlowScreen> {
  CheckpointStep _currentStep = CheckpointStep.istima;
  final _startTime = DateTime.now();

  // Scores par étape
  int _tartibScore = 0;
  int _takamulScore = 0;
  int _tasmiScore = 0;

  // Audio pour Istima'
  List<AudioOrchestrator>? _orchestrators;
  int _currentListeningVerse = 0;
  bool _isListening = false;

  // Steps list
  static const _steps = CheckpointStep.values;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() {
    _orchestrators = widget.verses.map((v) {
      final surah = v.surahNumber.toString().padLeft(3, '0');
      final verse = v.verseNumber.toString().padLeft(3, '0');
      final url =
          'https://everyayah.com/data/${widget.reciterFolder}/$surah$verse.mp3';
      return AudioOrchestrator(verseAudioUrl: url);
    }).toList();

    for (final o in _orchestrators!) {
      o.init();
    }
  }

  @override
  void dispose() {
    if (_orchestrators != null) {
      for (final o in _orchestrators!) {
        o.dispose();
      }
    }
    super.dispose();
  }

  void _advanceStep() {
    final idx = _steps.indexOf(_currentStep);
    if (idx + 1 < _steps.length) {
      setState(() => _currentStep = _steps[idx + 1]);
    }
  }

  /// Soumet les résultats au backend et appelle onComplete
  Future<void> _finishCheckpoint() async {
    final duration = DateTime.now().difference(_startTime).inSeconds;

    final firstVerse = widget.verses.first;
    final lastVerse = widget.verses.last;

    // Soumettre au backend
    try {
      final service = ref.read(hifzV2ServiceProvider);
      final sessionState = ref.read(wirdSessionProvider);

      await service.completeCheckpoint(
        wirdSessionId: sessionState.wirdSessionId,
        surahNumber: firstVerse.surahNumber,
        verseStart: firstVerse.verseNumber,
        verseEnd: lastVerse.verseNumber,
        tartibScore: _tartibScore,
        takamulScore: _takamulScore,
        tasmiScore: _tasmiScore,
        durationSeconds: duration,
      );
    } catch (_) {
      // Ne pas bloquer l'UI
    }

    final globalScore = (
      _tartibScore * 0.25 + _takamulScore * 0.35 + _tasmiScore * 0.40
    ).round().clamp(0, 100);

    final stars = globalScore >= 90 ? 3 : globalScore >= 70 ? 2 : globalScore >= 50 ? 1 : 0;
    final xp = 25 + (globalScore >= 90 ? 20 : globalScore >= 70 ? 10 : 0);

    widget.onComplete(CheckpointResult(
      verses: widget.verses,
      scoresByStep: {
        'tartib': _tartibScore,
        'takamul': _takamulScore,
        'tasmi': _tasmiScore,
      },
      globalScore: globalScore,
      stars: stars,
      xpEarned: xp,
      versesUpdated: widget.verses.length,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _buildTopBar(),

            // ── Step indicator ──
            _buildStepIndicator(),

            const SizedBox(height: 8),

            // ── Step content ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
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
          IconButton(
            icon: const Icon(Icons.close, color: HifzColors.textLight),
            onPressed: () => _showExitConfirmation(),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: HifzColors.goldMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CHECKPOINT',
              style: HifzTypo.stepLabel(),
            ),
          ),
          const Spacer(),
          Text(
            '${widget.verses.first.reference} → ${widget.verses.last.reference}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final stepLabels = {
      CheckpointStep.istima: 'Istima\'',
      CheckpointStep.tartib: 'Tartib',
      CheckpointStep.takamul: 'Takamul',
      CheckpointStep.tasmi: 'Tasmi\'',
      CheckpointStep.natija: 'Natija',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _steps.map((step) {
          final isActive = step == _currentStep;
          final isDone = step.index < _currentStep.index;

          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? HifzColors.emerald
                        : isActive
                            ? HifzColors.gold
                            : HifzColors.ivoryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepLabels[step] ?? '',
                  style: HifzTypo.body(
                    color: isActive
                        ? HifzColors.gold
                        : isDone
                            ? HifzColors.emerald
                            : HifzColors.textLight,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      CheckpointStep.istima => _StepIstima(
          key: const ValueKey('istima'),
          verses: widget.verses,
          orchestrators: _orchestrators!,
          onComplete: () => _advanceStep(),
        ),
      CheckpointStep.tartib => ExerciseTartib(
          key: const ValueKey('tartib'),
          verses: widget.verses,
          onComplete: (score) {
            _tartibScore = score;
            _advanceStep();
          },
        ),
      CheckpointStep.takamul => ExerciseTakamul(
          key: const ValueKey('takamul'),
          verses: widget.verses,
          onComplete: (score) {
            _takamulScore = score;
            _advanceStep();
          },
        ),
      CheckpointStep.tasmi => _StepTasmiGrouped(
          key: const ValueKey('tasmi'),
          verses: widget.verses,
          onComplete: (score) {
            _tasmiScore = score;
            _advanceStep();
          },
        ),
      CheckpointStep.natija => _CheckpointNatija(
          key: const ValueKey('natija'),
          tartibScore: _tartibScore,
          takamulScore: _takamulScore,
          tasmiScore: _tasmiScore,
          verses: widget.verses,
          onFinish: () => _finishCheckpoint(),
        ),
    };
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HifzColors.ivoryWarm,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Quitter le Checkpoint ?', style: HifzTypo.sectionTitle()),
        content: Text(
          'Ta progression sur ce checkpoint ne sera pas sauvegardée.',
          style: HifzTypo.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Continuer',
                style: HifzTypo.body(color: HifzColors.emerald)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child:
                Text('Quitter', style: HifzTypo.body(color: HifzColors.wrong)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Step Istima' — Écoute globale de tous les versets
// ═══════════════════════════════════════════════════════════════════

class _StepIstima extends StatefulWidget {
  const _StepIstima({
    super.key,
    required this.verses,
    required this.orchestrators,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final List<AudioOrchestrator> orchestrators;
  final VoidCallback onComplete;

  @override
  State<_StepIstima> createState() => _StepIstimaState();
}

class _StepIstimaState extends State<_StepIstima> {
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _playAll();
  }

  Future<void> _playAll() async {
    setState(() => _isPlaying = true);

    for (var i = 0; i < widget.verses.length; i++) {
      if (!mounted) return;
      setState(() => _currentIndex = i);

      try {
        await widget.orchestrators[i].playFull();
        // Small pause between verses
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        // Continue on error
      }
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'استماع شامل',
            style: HifzTypo.verse(size: 26, color: HifzColors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            'Écoute attentivement les ${widget.verses.length} versets',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),

          const SizedBox(height: 40),

          // ── Listening indicator ──
          if (_isPlaying) ...[
            // Verse counter
            Text(
              '${_currentIndex + 1} / ${widget.verses.length}',
              style: HifzTypo.score(color: HifzColors.emerald)
                  .copyWith(fontSize: 36),
            ),
            const SizedBox(height: 16),

            // Animated wave
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  return _AnimatedBar(
                    delay: Duration(milliseconds: i * 100),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              widget.verses[_currentIndex].reference,
              style: HifzTypo.body(color: HifzColors.textLight),
            ),
          ],

          if (_isDone) ...[
            const Icon(Icons.check_circle,
                size: 64, color: HifzColors.emerald),
            const SizedBox(height: 16),
            Text('Écoute terminée',
                style: HifzTypo.sectionTitle()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onComplete,
              style: HifzDecor.primaryButton,
              child: const Text('Continuer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple animated bar for the waveform effect.
class _AnimatedBar extends StatefulWidget {
  const _AnimatedBar({required this.delay});
  final Duration delay;

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 6,
          height: 10 + _ctrl.value * 28,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: HifzColors.emerald.withOpacity(0.5 + _ctrl.value * 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}

/// AnimatedBuilder helper.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ═══════════════════════════════════════════════════════════════════
// Step Tasmi' Groupé — Récitation de tous les versets (simplifié)
// ═══════════════════════════════════════════════════════════════════

class _StepTasmiGrouped extends StatefulWidget {
  const _StepTasmiGrouped({
    super.key,
    required this.verses,
    required this.onComplete,
  });

  final List<EnrichedVerse> verses;
  final void Function(int score) onComplete;

  @override
  State<_StepTasmiGrouped> createState() => _StepTasmiGroupedState();
}

class _StepTasmiGroupedState extends State<_StepTasmiGrouped> {
  bool _showText = false;
  int _selfScore = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'تسميع جماعي',
            style: HifzTypo.verse(size: 24, color: HifzColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            'Récite les ${widget.verses.length} versets de mémoire',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.verses.first.reference} → ${widget.verses.last.reference}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),

          const SizedBox(height: 24),

          // ── Toggle text visibility ──
          OutlinedButton.icon(
            onPressed: () => setState(() => _showText = !_showText),
            style: HifzDecor.secondaryButton,
            icon: Icon(_showText ? Icons.visibility_off : Icons.visibility,
                size: 18),
            label: Text(_showText ? 'Masquer le texte' : 'Afficher le texte'),
          ),

          const SizedBox(height: 16),

          // ── Text display ──
          if (_showText)
            Expanded(
              child: ListView.separated(
                itemCount: widget.verses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final v = widget.verses[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HifzColors.ivoryWarm,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${v.verseNumber}',
                          style: HifzTypo.body(color: HifzColors.textLight)
                              .copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.textAr,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: HifzTypo.verse(size: 18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(Icons.mic_none_rounded,
                    size: 80, color: HifzColors.emeraldMuted),
              ),
            ),

          const SizedBox(height: 16),

          // ── Self-evaluation ──
          Text('Comment as-tu récité ?',
              style: HifzTypo.body(color: HifzColors.textMedium)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreButton(
                label: 'Difficile',
                emoji: '😓',
                color: HifzColors.wrong,
                onTap: () => widget.onComplete(30),
              ),
              _ScoreButton(
                label: 'Moyen',
                emoji: '😐',
                color: HifzColors.close,
                onTap: () => widget.onComplete(60),
              ),
              _ScoreButton(
                label: 'Bien',
                emoji: '😊',
                color: HifzColors.emerald,
                onTap: () => widget.onComplete(80),
              ),
              _ScoreButton(
                label: 'Parfait',
                emoji: '🌟',
                color: HifzColors.gold,
                onTap: () => widget.onComplete(100),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: HifzTypo.body(color: color).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Checkpoint Natija — Résultats détaillés
// ═══════════════════════════════════════════════════════════════════

class _CheckpointNatija extends StatelessWidget {
  const _CheckpointNatija({
    super.key,
    required this.tartibScore,
    required this.takamulScore,
    required this.tasmiScore,
    required this.verses,
    required this.onFinish,
  });

  final int tartibScore;
  final int takamulScore;
  final int tasmiScore;
  final List<EnrichedVerse> verses;
  final VoidCallback onFinish;

  int get _globalScore =>
      (tartibScore * 0.25 + takamulScore * 0.35 + tasmiScore * 0.40)
          .round()
          .clamp(0, 100);

  int get _stars =>
      _globalScore >= 90 ? 3 : _globalScore >= 70 ? 2 : _globalScore >= 50 ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Global score ──
          Text(
            '$_globalScore%',
            style: HifzTypo.score(
              color: _globalScore >= 70 ? HifzColors.emerald : HifzColors.wrong,
            ),
          ),
          const SizedBox(height: 8),

          // ── Stars ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: HifzColors.gold,
                size: 32,
              );
            }),
          ),

          const SizedBox(height: 24),

          // ── Détails par étape ──
          _StepScoreRow('Tartib', 'ترتيب', tartibScore),
          const SizedBox(height: 8),
          _StepScoreRow('Takamul', 'تكامل', takamulScore),
          const SizedBox(height: 8),
          _StepScoreRow('Tasmi\'', 'تسميع', tasmiScore),

          const SizedBox(height: 24),

          // ── Versets couverts ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: HifzDecor.card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: HifzColors.emerald, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${verses.length} versets vérifiés',
                  style: HifzTypo.body(color: HifzColors.textDark),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${verses.first.reference} → ${verses.last.reference})',
                  style: HifzTypo.body(color: HifzColors.textLight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Bouton ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: HifzDecor.primaryButton,
              child: const Text('Continuer le Wird'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScoreRow extends StatelessWidget {
  const _StepScoreRow(this.labelFr, this.labelAr, this.score);

  final String labelFr;
  final String labelAr;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 70 ? HifzColors.correct : score >= 50 ? HifzColors.close : HifzColors.wrong;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: HifzColors.ivoryWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(labelAr,
              textDirection: TextDirection.rtl,
              style: HifzTypo.verse(size: 16, color: HifzColors.textMedium)),
          const SizedBox(width: 10),
          Text(labelFr,
              style: HifzTypo.body(color: HifzColors.textMedium)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score%',
              style: HifzTypo.body(color: color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

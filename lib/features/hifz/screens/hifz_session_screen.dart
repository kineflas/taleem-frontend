import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../models/hifz_score_model.dart';
import '../providers/hifz_provider.dart';
import '../providers/quran_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SILSILA — Protocole TIKRAR 6446
// Phase 0: Lecture   × 6  (texte visible)
// Phase 1: Récitation × 4 (texte caché — auto-dictée)
// Phase 2: Lecture   × 4  (texte visible)
// Phase 3: Récitation × 6 (texte caché — auto-dictée)
// ─────────────────────────────────────────────────────────────────────────────

const _phaseTargets   = [6, 4, 4, 6];
const _phaseIsRecall  = [false, true, false, true];
const _phaseGroup     = ['A', 'A', 'B', 'B'];
const _phaseTypeFr    = ['Lecture', 'Récitation', 'Lecture', 'Récitation'];

enum SessionMode { tikrar, libre }

// ReviewScore est importé depuis ../models/hifz_score_model.dart

class HifzSessionScreen extends ConsumerStatefulWidget {
  final HifzGoalModel goal;

  const HifzSessionScreen({super.key, required this.goal});

  @override
  ConsumerState<HifzSessionScreen> createState() => _HifzSessionScreenState();
}

class _HifzSessionScreenState extends ConsumerState<HifzSessionScreen>
    with SingleTickerProviderStateMixin {
  // ── Navigation ───────────────────────────────────────────────────────────
  late int _currentVerse;

  // ── Session mode ─────────────────────────────────────────────────────────
  SessionMode _sessionMode = SessionMode.tikrar;

  // ── TIKRAR 6446 state ────────────────────────────────────────────────────
  int  _tikrarPhase    = 0;
  int  _phaseProgress  = 0;
  bool _tikrarComplete = false;

  // ── Libre mode state ─────────────────────────────────────────────────────
  int _loopCount    = 5;
  int _currentLoop  = 0;
  int _pauseSeconds = 3;

  // ── Common state ─────────────────────────────────────────────────────────
  int  _maskingLevel = 0; // 0=visible, 1=30%, 2=60%, 3=premier lettre
  bool _isPlaying    = false;
  bool _audioError   = false;
  Set<int> _versesMarked = {};
  Timer? _pauseTimer;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _phaseAnim;

  // ── Audio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Normalise le nom du récitateur (variantes historiques en DB)
  static const Map<String, String> _reciterAliases = {
    'Al-Husary_128kbps':  'Husary_128kbps',
    'Al-Husary_64kbps':   'Husary_64kbps',
    'Husary':             'Husary_128kbps',
    'Alafasy':            'Alafasy_128kbps',
    'Abdul_Basit':        'Abdul_Basit_Murattal_192kbps',
  };

  String get _normalizedReciter {
    final raw = widget.goal.reciterFolder.isNotEmpty
        ? widget.goal.reciterFolder
        : 'Alafasy_128kbps';
    return _reciterAliases[raw] ?? raw;
  }

  String _audioUrl(int surah, int verse, {String? reciterOverride}) {
    final s = surah.toString().padLeft(3, '0');
    final v = verse.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${reciterOverride ?? _normalizedReciter}/$s$v.mp3';
  }

  Future<void> _playVerseAudio(int surah, int verse) async {
    setState(() => _audioError = false);
    try {
      // audioplayers v6 : un stop() explicite est nécessaire avant play()
      // si l'état est PlayerState.completed, sinon la lecture échoue silencieusement.
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(_audioUrl(surah, verse)));
    } catch (_) {
      try {
        await _audioPlayer.play(
          UrlSource(_audioUrl(surah, verse, reciterOverride: 'Alafasy_128kbps')),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Récitateur indisponible — lecture avec Alafasy"),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e2) {
        if (mounted) {
          setState(() { _isPlaying = false; _audioError = true; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Audio indisponible — vérifiez la connexion"),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  // ── TIKRAR logic ──────────────────────────────────────────────────────────

  void _onTikrarAudioComplete() {
    final target = _phaseTargets[_tikrarPhase];
    if (_phaseProgress + 1 < target) {
      // Plus de répétitions dans la phase actuelle
      setState(() => _phaseProgress++);
      _pauseTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          _playVerseAudio(widget.goal.surahNumber, _currentVerse);
        }
      });
    } else if (_tikrarPhase < 3) {
      // Passer à la phase suivante
      final nextPhase = _tikrarPhase + 1;
      setState(() {
        _tikrarPhase   = nextPhase;
        _phaseProgress = 0;
        _maskingLevel  = _phaseIsRecall[nextPhase] ? 3 : 0;
      });
      _phaseAnim.forward(from: 0);

      final isRecall = _phaseIsRecall[nextPhase];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isRecall
                ? '🎯 Phase ${_phaseGroup[nextPhase]} — Récitation de mémoire !'
                : '📖 Phase ${_phaseGroup[nextPhase]} — Lecture avec le texte',
          ),
          backgroundColor:
              isRecall ? AppColors.accent : AppColors.primary,
          duration: const Duration(seconds: 2),
        ));
      }

      _pauseTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          _playVerseAudio(widget.goal.surahNumber, _currentVerse);
        }
      });
    } else {
      // Toutes les phases terminées → évaluation WAQF
      setState(() {
        _isPlaying    = false;
        _tikrarComplete = true;
      });
    }
  }

  void _resetTikrar() {
    setState(() {
      _tikrarPhase    = 0;
      _phaseProgress  = 0;
      _tikrarComplete = false;
      _maskingLevel   = 0;
    });
  }

  void _onWaqfEval(ReviewScore score) {
    final labels = {
      ReviewScore.green:  '✅ Excellent — Prochaine révision dans 7 jours',
      ReviewScore.orange: '⚠️ Bien — Révision dans 3 jours',
      ReviewScore.red:    '🔄 À retravailler — Révision demain',
    };
    final colors = {
      ReviewScore.green:  AppColors.success,
      ReviewScore.orange: AppColors.warning,
      ReviewScore.red:    AppColors.danger,
    };

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(labels[score]!),
        backgroundColor: colors[score],
        duration: const Duration(seconds: 3),
      ));
    }

    // Marquer le verset si score ≥ orange
    if (score != ReviewScore.red) {
      _versesMarked.add(_currentVerse);
    }

    _resetTikrar();

    // Auto-avance si succès ou hésitation
    if (score != ReviewScore.red && _currentVerse < widget.goal.totalVerses) {
      Future.delayed(const Duration(milliseconds: 600), _nextVerse);
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentVerse = 1;

    _phaseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_sessionMode == SessionMode.tikrar && !_tikrarComplete) {
        _onTikrarAudioComplete();
      } else {
        // Mode Libre
        if (_currentLoop < _loopCount - 1) {
          setState(() => _currentLoop++);
          _pauseTimer = Timer(Duration(seconds: _pauseSeconds), () {
            if (mounted && _isPlaying) {
              _playVerseAudio(widget.goal.surahNumber, _currentVerse);
            }
          });
        } else {
          setState(() { _isPlaying = false; _currentLoop = 0; });
        }
      }
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _phaseAnim.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(quranSurahProvider(widget.goal.surahNumber));

    return surahAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('سورة ${widget.goal.surahNumber}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des versets…'),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('سورة ${widget.goal.surahNumber}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger les versets',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(quranSurahProvider(widget.goal.surahNumber)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (verseTexts) => _buildSession(context, verseTexts),
    );
  }

  Widget _buildSession(BuildContext context, Map<int, String> verseTexts) {
    final verseText = verseTexts[_currentVerse] ?? '…';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('سورة ${widget.goal.surahNumber}'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Mode toggle chip
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: _buildModeToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Barre de progression globale ─────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الآية $_currentVerse / ${widget.goal.totalVerses}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${((_currentVerse / widget.goal.totalVerses) * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentVerse / widget.goal.totalVerses,
                      minHeight: 6,
                      backgroundColor: AppColors.heatmapEmpty,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Texte du verset ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _sessionMode == SessionMode.tikrar && !_tikrarComplete
                      ? (_phaseIsRecall[_tikrarPhase]
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.3))
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'الآية $_currentVerse',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildMaskedVerseText(verseText),
                  const SizedBox(height: 12),
                  // Label masquage courant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('مستوى الإخفاء: ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        ['واضح', '30%', '60%', 'أول حرف'][_maskingLevel],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Indicateur TIKRAR ou compteur Libre ──────────────────────
            if (_sessionMode == SessionMode.tikrar)
              _buildTikrarPhaseDisplay()
            else
              _buildLibreCounter(),

            const SizedBox(height: 20),

            // ── Contrôles audio ou évaluation WAQF ───────────────────────
            if (_tikrarComplete && _sessionMode == SessionMode.tikrar)
              _buildWaqfEvaluation()
            else ...[
              _buildPlayerControls(),
              const SizedBox(height: 20),
              // Masking buttons (visibles en mode libre, et override en tikrar)
              if (_sessionMode == SessionMode.libre) _buildMaskingButtons(),
              const SizedBox(height: 16),
              // Actions (Je le connais / Encore)
              _buildActionButtons(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeChip('6446', SessionMode.tikrar),
          _modeChip('Libre', SessionMode.libre),
        ],
      ),
    );
  }

  Widget _modeChip(String label, SessionMode mode) {
    final isActive = _sessionMode == mode;
    return GestureDetector(
      onTap: () {
        if (_sessionMode == mode) return;
        _pauseTimer?.cancel();
        _audioPlayer.stop();
        setState(() {
          _sessionMode  = mode;
          _isPlaying    = false;
          _currentLoop  = 0;
          if (mode == SessionMode.libre) _tikrarComplete = false;
          if (mode == SessionMode.tikrar) _resetTikrar();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  /// Indicateur de phase TIKRAR — phase A/B + progression en pastilles
  Widget _buildTikrarPhaseDisplay() {
    if (_tikrarComplete) return const SizedBox.shrink();

    final isRecall  = _phaseIsRecall[_tikrarPhase];
    final target    = _phaseTargets[_tikrarPhase];
    final groupColor = isRecall ? AppColors.accent : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: groupColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: groupColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Phase ${_phaseGroup[_tikrarPhase]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _phaseTypeFr[_tikrarPhase],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                      fontSize: 14,
                    ),
                  ),
                  if (isRecall) ...[
                    const SizedBox(width: 6),
                    const Text('🎯', style: TextStyle(fontSize: 14)),
                  ] else ...[
                    const SizedBox(width: 6),
                    const Text('📖', style: TextStyle(fontSize: 14)),
                  ],
                ],
              ),
              Text(
                '${_phaseProgress + 1} / $target',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pastilles de progression
          Row(
            children: List.generate(target, (i) {
              final filled = i <= _phaseProgress;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    color: filled ? groupColor : groupColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Aperçu des 4 phases
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isCurrentPhase = i == _tikrarPhase;
              final isComplete     = i < _tikrarPhase;
              final phaseColor     = _phaseIsRecall[i] ? AppColors.accent : AppColors.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isCurrentPhase ? 28 : 22,
                      height: isCurrentPhase ? 28 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isComplete
                            ? phaseColor
                            : isCurrentPhase
                                ? phaseColor.withOpacity(0.9)
                                : phaseColor.withOpacity(0.15),
                        border: isCurrentPhase
                            ? Border.all(color: phaseColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isComplete
                              ? '✓'
                              : '${_phaseTargets[i]}',
                          style: TextStyle(
                            color: isComplete || isCurrentPhase
                                ? Colors.white
                                : phaseColor,
                            fontWeight: FontWeight.w800,
                            fontSize: isCurrentPhase ? 11 : 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phaseIsRecall[i] ? '🎯' : '📖',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Compteur simple mode Libre
  Widget _buildLibreCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🔁'),
              const SizedBox(width: 8),
              Text(
                'Écoute ${_currentLoop + 1}/$_loopCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          Text('⏱️ ${_pauseSeconds}s',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Évaluation WAQF après TIKRAR complet
  Widget _buildWaqfEvaluation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'WAQF — Évaluation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cycle TIKRAR 6446 terminé ! Comment vous en êtes-vous sorti ?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _waqfButton('🟢', 'Parfait', 'J+7', AppColors.success, () => _onWaqfEval(ReviewScore.green))),
              const SizedBox(width: 8),
              Expanded(child: _waqfButton('🟡', 'Bien', 'J+3', AppColors.warning, () => _onWaqfEval(ReviewScore.orange))),
              const SizedBox(width: 8),
              Expanded(child: _waqfButton('🔴', 'Difficile', 'J+1', AppColors.danger, () => _onWaqfEval(ReviewScore.red))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waqfButton(String emoji, String label, String nextDate, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              nextDate,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaskedVerseText(String verseText) {
    final words = verseText.split(' ');

    if (_maskingLevel == 0) {
      return Text(
        verseText,
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        textDirection: TextDirection.rtl,
      );
    } else if (_maskingLevel == 1) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          final isMasked = (word.hashCode % 100) < 30;
          return Text(
            isMasked ? '█████' : word,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isMasked ? AppColors.textHint : AppColors.primary,
            ),
          );
        }).toList(),
      );
    } else if (_maskingLevel == 2) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          final isMasked = (word.hashCode % 100) < 60;
          return Text(
            isMasked ? '█████' : word,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isMasked ? AppColors.textHint : AppColors.primary,
            ),
          );
        }).toList(),
      );
    } else {
      // Auto-dictée: seulement le premier caractère
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((word) {
          return Text(
            word.isNotEmpty ? '${word[0]}___' : '',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildPlayerControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton précédent
          IconButton(
            onPressed: _currentVerse > 1 ? _previousVerse : null,
            icon: const Icon(Icons.skip_previous, size: 28),
            color: AppColors.primary,
          ),

          // Bouton play (Libre: stepper loop; TIKRAR: juste play/pause)
          if (_sessionMode == SessionMode.libre)
            _buildControl(
              '🔁',
              '$_loopCount',
              () => setState(() => _loopCount = (_loopCount - 1).clamp(1, 20)),
              () => setState(() => _loopCount = (_loopCount + 1).clamp(1, 20)),
            ),

          GestureDetector(
            onTap: _audioError ? null : _togglePlayPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _audioError ? AppColors.danger : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _audioError
                    ? const Icon(Icons.wifi_off, color: Colors.white, size: 28)
                    : Text(
                        _isPlaying ? '⏸️' : '▶️',
                        style: const TextStyle(fontSize: 32),
                      ),
              ),
            ),
          ),

          if (_sessionMode == SessionMode.libre)
            _buildControl(
              '⏱️',
              '${_pauseSeconds}s',
              () => setState(() => _pauseSeconds = (_pauseSeconds - 1).clamp(0, 60)),
              () => setState(() => _pauseSeconds = (_pauseSeconds + 1).clamp(0, 60)),
            ),

          // Bouton suivant
          IconButton(
            onPressed: _currentVerse < widget.goal.totalVerses ? _nextVerse : null,
            icon: const Icon(Icons.skip_next, size: 28),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildControl(String emoji, String label, VoidCallback onMinus, VoidCallback onPlus) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onMinus,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.remove, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPlus,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaskingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildMaskingButton('واضح', 0)),
          const SizedBox(width: 6),
          Expanded(child: _buildMaskingButton('30%', 1)),
          const SizedBox(width: 6),
          Expanded(child: _buildMaskingButton('60%', 2)),
          const SizedBox(width: 6),
          Expanded(child: _buildMaskingButton('أول', 3)),
        ],
      ),
    );
  }

  Widget _buildMaskingButton(String label, int level) {
    final isSelected = _maskingLevel == level;
    return ElevatedButton(
      onPressed: () => setState(() => _maskingLevel = level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          // Bouton "Je le connais"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _versesMarked.contains(_currentVerse) ? null : _handleMarkKnown,
              icon: const Text('✅', style: TextStyle(fontSize: 20)),
              label: Text(
                _versesMarked.contains(_currentVerse) ? 'Mémorisé ✓' : 'Je le connais',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.heatmapEmpty,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Bouton "Encore"
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleRepeat,
              icon: const Icon(Icons.refresh),
              label: const Text('Encore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_sessionMode == SessionMode.tikrar) ...[
            const SizedBox(height: 10),
            // Override masking en tikrar (optionnel)
            Text(
              'Mode TIKRAR actif — masquage automatique par phase',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      _pauseTimer?.cancel();
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      final state = _audioPlayer.state;
      if (state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _playVerseAudio(widget.goal.surahNumber, _currentVerse);
      }
    }
  }

  Future<void> _handleRepeat() async {
    _pauseTimer?.cancel();
    await _audioPlayer.stop();
    if (_sessionMode == SessionMode.tikrar) {
      _resetTikrar();
    }
    setState(() { _isPlaying = true; _currentLoop = 0; });
    await _playVerseAudio(widget.goal.surahNumber, _currentVerse);
  }

  Future<void> _stopAudio() async {
    _pauseTimer?.cancel();
    await _audioPlayer.stop();
    setState(() { _isPlaying = false; _currentLoop = 0; });
  }

  void _handleMarkKnown() {
    setState(() => _versesMarked.add(_currentVerse));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الآية $_currentVerse مسجلة ✅'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
    if (_currentVerse < widget.goal.totalVerses) {
      Future.delayed(const Duration(milliseconds: 500), _nextVerse);
    }
  }

  Future<void> _nextVerse() async {
    if (_currentVerse < widget.goal.totalVerses) {
      await _stopAudio();
      setState(() {
        _currentVerse++;
        if (_sessionMode == SessionMode.tikrar) {
          _tikrarPhase    = 0;
          _phaseProgress  = 0;
          _tikrarComplete = false;
          _maskingLevel   = 0;
        }
      });
    }
  }

  Future<void> _previousVerse() async {
    if (_currentVerse > 1) {
      await _stopAudio();
      setState(() {
        _currentVerse--;
        if (_sessionMode == SessionMode.tikrar) {
          _tikrarPhase    = 0;
          _phaseProgress  = 0;
          _tikrarComplete = false;
          _maskingLevel   = 0;
        }
      });
    }
  }
}

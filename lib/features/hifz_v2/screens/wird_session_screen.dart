import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import 'checkpoint_flow_screen.dart';
import 'wird_verse_flow_screen.dart';

/// Écran principal du Wird quotidien.
///
/// Orchestre les 3 blocs (JADID → QARIB → BA'ID) et affiche
/// la progression globale. Chaque verset lance le flow en 5 étapes
/// via WirdVerseFlowScreen.
class WirdSessionScreen extends ConsumerStatefulWidget {
  const WirdSessionScreen({
    super.key,
    required this.session,
  });

  final WirdSession session;

  @override
  ConsumerState<WirdSessionScreen> createState() => _WirdSessionScreenState();
}

class _WirdSessionScreenState extends ConsumerState<WirdSessionScreen> {
  WirdBloc _currentBloc = WirdBloc.jadid;
  int _currentVerseIdx = 0;
  final List<VerseSessionResult> _results = [];
  bool _isInFlow = false;
  bool _wirdComplete = false;
  bool _autoAdvance = true; // Mode Enchaînement : auto-avance au verset suivant

  // ── Checkpoint tracking ──
  /// Nombre de versets JADID complétés depuis le dernier checkpoint
  int _jadidSinceCheckpoint = 0;
  /// Seuil de déclenchement du checkpoint (tous les N versets JADID)
  static const int _checkpointThreshold = 3;
  /// true quand on affiche le CheckpointFlowScreen
  bool _inCheckpoint = false;
  /// Versets accumulés pour le prochain checkpoint
  final List<EnrichedVerse> _checkpointVerses = [];

  List<EnrichedVerse> get _currentVerses => switch (_currentBloc) {
        WirdBloc.jadid => widget.session.jadidVerses,
        WirdBloc.qarib => widget.session.qaribVerses,
        WirdBloc.baid => widget.session.baidVerses,
      };

  int get _totalDone {
    var done = 0;
    if (_currentBloc == WirdBloc.qarib || _currentBloc == WirdBloc.baid) {
      done += widget.session.jadidVerses.length;
    }
    if (_currentBloc == WirdBloc.baid) {
      done += widget.session.qaribVerses.length;
    }
    done += _currentVerseIdx;
    return done;
  }

  void _startVerseFlow() {
    setState(() => _isInFlow = true);
  }

  void _onVerseComplete(VerseSessionResult result) {
    _results.add(result);

    // ── Checkpoint tracking pour le bloc JADID ──
    if (_currentBloc == WirdBloc.jadid) {
      _jadidSinceCheckpoint++;
      _checkpointVerses.add(_currentVerses[_currentVerseIdx]);
    }

    final shouldCheckpoint = _currentBloc == WirdBloc.jadid &&
        _jadidSinceCheckpoint >= _checkpointThreshold;

    final hasMoreVerses = _currentVerseIdx + 1 < _currentVerses.length;

    if (shouldCheckpoint) {
      // Lancer le checkpoint AVANT d'avancer l'index.
      // L'index sera incrémenté dans _onCheckpointComplete si nécessaire.
      setState(() {
        _inCheckpoint = true;
        _isInFlow = false;
      });
    } else if (hasMoreVerses) {
      // Avancer au verset suivant dans le même bloc
      ref.read(wirdSessionProvider.notifier).nextVerse();
      setState(() {
        _currentVerseIdx++;
        _isInFlow = _autoAdvance;
      });
    } else {
      // Bloc terminé — déclencher un checkpoint si des versets JADID en attente
      if (_currentBloc == WirdBloc.jadid && _checkpointVerses.isNotEmpty) {
        setState(() {
          _inCheckpoint = true;
          _isInFlow = false;
        });
      } else {
        _advanceBloc();
      }
    }
  }

  /// Appelé quand le CheckpointFlowScreen se termine
  void _onCheckpointComplete(CheckpointResult result) {
    _inCheckpoint = false;
    _jadidSinceCheckpoint = 0;
    _checkpointVerses.clear();

    // Avancer au verset suivant (l'index n'a PAS été incrémenté avant le checkpoint)
    final hasMoreVerses = _currentVerseIdx + 1 < _currentVerses.length;

    if (hasMoreVerses) {
      ref.read(wirdSessionProvider.notifier).nextVerse();
      setState(() {
        _currentVerseIdx++;
        _isInFlow = _autoAdvance;
      });
    } else {
      // Dernier verset du bloc → avancer au bloc suivant
      _advanceBloc();
    }
  }

  void _advanceBloc() {
    final notifier = ref.read(wirdSessionProvider.notifier);

    switch (_currentBloc) {
      case WirdBloc.jadid:
        // Passer au bloc suivant et réinitialiser le compteur checkpoint
        _jadidSinceCheckpoint = 0;
        _checkpointVerses.clear();

        if (widget.session.qaribVerses.isNotEmpty) {
          notifier.nextBloc();
          setState(() {
            _currentBloc = WirdBloc.qarib;
            _currentVerseIdx = 0;
            _isInFlow = _autoAdvance;
          });
        } else if (widget.session.baidVerses.isNotEmpty) {
          notifier.nextBloc();
          setState(() {
            _currentBloc = WirdBloc.baid;
            _currentVerseIdx = 0;
            _isInFlow = _autoAdvance;
          });
        } else {
          _finishWird();
        }
      case WirdBloc.qarib:
        if (widget.session.baidVerses.isNotEmpty) {
          notifier.nextBloc();
          setState(() {
            _currentBloc = WirdBloc.baid;
            _currentVerseIdx = 0;
            _isInFlow = _autoAdvance;
          });
        } else {
          _finishWird();
        }
      case WirdBloc.baid:
        _finishWird();
    }
  }

  Future<void> _finishWird() async {
    // Terminer le Wird côté backend
    try {
      await ref.read(wirdSessionProvider.notifier).complete();
      // Rafraîchir les données après complétion
      ref.invalidate(wirdTodayProvider);
      ref.invalidate(journeyMapProvider);
    } catch (_) {
      // Ne pas bloquer l'affichage du résultat
    }

    if (!mounted) return;
    setState(() {
      _wirdComplete = true;
      _isInFlow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Checkpoint en cours ──
    if (_inCheckpoint && _checkpointVerses.isNotEmpty) {
      return CheckpointFlowScreen(
        verses: List.of(_checkpointVerses),
        reciterFolder: widget.session.reciterFolder,
        onComplete: _onCheckpointComplete,
      );
    }

    if (_isInFlow && _currentVerses.isNotEmpty) {
      return WirdVerseFlowScreen(
        verse: _currentVerses[_currentVerseIdx],
        reciterFolder: widget.session.reciterFolder,
        bloc: _currentBloc,
        onComplete: _onVerseComplete,
      );
    }

    if (_wirdComplete) {
      return _buildWirdComplete();
    }

    return _buildWirdOverview();
  }

  Widget _buildWirdOverview() {
    final total = widget.session.totalVerses;
    final progress = total > 0 ? _totalDone / total : 0.0;

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ──
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: HifzColors.textLight),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Ton Wird',
                    style: HifzTypo.sectionTitle(),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              // ── Progression globale ──
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: HifzColors.ivoryDark,
                  valueColor: const AlwaysStoppedAnimation(HifzColors.emerald),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_totalDone/$total versets — ~${widget.session.estimatedDuration.inMinutes} min',
                style: HifzTypo.body(color: HifzColors.textLight),
              ),

              const SizedBox(height: 32),

              // ── Bloc courant ──
              _buildBlocHeader(),

              const SizedBox(height: 16),

              // ── Verset courant ──
              Expanded(
                child: _buildCurrentVerseCard(),
              ),

              // ── Toggle enchaînement ──
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.fast_forward_rounded,
                        color: _autoAdvance
                            ? HifzColors.emerald
                            : HifzColors.textLight,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enchaînement automatique',
                        style: HifzTypo.body(
                          color: _autoAdvance
                              ? HifzColors.textDark
                              : HifzColors.textLight,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _autoAdvance,
                      activeColor: HifzColors.emerald,
                      onChanged: (v) => setState(() => _autoAdvance = v),
                    ),
                  ],
                ),
              ),

              // ── Bouton lancer ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentVerses.isNotEmpty ? _startVerseFlow : null,
                  style: HifzDecor.primaryButton,
                  child: const Text('Commencer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlocHeader() {
    final (label, labelAr, desc) = switch (_currentBloc) {
      WirdBloc.jadid => ('JADID', 'جديد', 'Nouveaux versets'),
      WirdBloc.qarib => ('QARIB', 'قريب', 'Révision proche'),
      WirdBloc.baid => ('BA\'ID', 'بعيد', 'Révision lointaine'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HifzColors.goldMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HifzColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(labelAr, style: HifzTypo.verse(size: 20, color: HifzColors.gold)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: HifzTypo.stepLabel()),
              Text(
                '$desc — ${_currentVerses.length} verset${_currentVerses.length > 1 ? 's' : ''}',
                style: HifzTypo.body(color: HifzColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVerseCard() {
    if (_currentVerses.isEmpty) {
      return Center(
        child: Text('Aucun verset dans ce bloc', style: HifzTypo.body()),
      );
    }

    final verse = _currentVerses[_currentVerseIdx];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: HifzDecor.card,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Verset ${_currentVerseIdx + 1}/${_currentVerses.length}',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
          const SizedBox(height: 16),
          Text(
            verse.textAr,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: HifzTypo.verse(size: 26),
          ),
          if (verse.textFr != null) ...[
            const SizedBox(height: 16),
            Text(
              verse.textFr!,
              textAlign: TextAlign.center,
              style: HifzTypo.translation(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWirdComplete() {
    final sessionState = ref.read(wirdSessionProvider);
    // Utiliser les XP du backend si disponibles, sinon fallback local
    final totalXp = sessionState.totalXpEarned > 0
        ? sessionState.totalXpEarned
        : _results.fold<int>(0, (s, r) => s + r.xpEarned);
    final totalStars = _results.fold<int>(0, (s, r) => s + r.stars);
    final avgScore = _results.isEmpty
        ? 0
        : _results.fold<int>(0, (s, r) => s + r.finalScore) ~/ _results.length;

    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: HifzColors.emerald),
                const SizedBox(height: 16),
                Text('Wird terminé !', style: HifzTypo.sectionTitle()),
                const SizedBox(height: 24),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _WirdStat('$avgScore%', 'Score moyen'),
                    _WirdStat('$totalStars', 'Étoiles'),
                    _WirdStat('+$totalXp', 'XP'),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Bouton principal : Choisir une autre sourate ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(wirdSessionProvider.notifier).reset();
                      ref.invalidate(suggestedSurahsProvider);
                      ref.invalidate(wirdTodayProvider);
                      ref.invalidate(journeyMapProvider);
                      // Retourner à l'écran Ikhtiar
                      Navigator.of(context).pop();
                      context.push('/hifz-v2/ikhtiar');
                    },
                    style: HifzDecor.primaryButton,
                    child: const Text('Choisir une autre sourate'),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Bouton secondaire : Retour au menu ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(wirdSessionProvider.notifier).reset();
                      ref.invalidate(wirdTodayProvider);
                      ref.invalidate(journeyMapProvider);
                      Navigator.of(context).pop();
                    },
                    style: HifzDecor.secondaryButton,
                    child: const Text('Retour au menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WirdStat extends StatelessWidget {
  const _WirdStat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: HifzTypo.score(color: HifzColors.gold).copyWith(fontSize: 32)),
        Text(label, style: HifzTypo.body(color: HifzColors.textLight)),
      ],
    );
  }
}

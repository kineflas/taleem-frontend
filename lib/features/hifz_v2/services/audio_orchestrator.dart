import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Phases de la boucle TIKRAR 6446.
enum TikrarPhase {
  ecoute6(6, 'Écoute', true),       // 6× écoute avec texte visible
  rappel4(4, 'Rappel', false),      // 4× récitation avec masquage progressif
  consolidation4(4, 'Consolidation', true),  // 4× réécoute
  autonomie6(6, 'Autonomie', false); // 6× récitation autonome

  const TikrarPhase(this.repetitions, this.label, this.isListening);
  final int repetitions;
  final String label;
  final bool isListening;  // true = récitateur joue, false = élève récite
}

/// Orchestrateur audio intelligent pour le TIKRAR 6446.
///
/// Fonctionnalités :
/// - Boucle automatique par phase avec compteur
/// - Volume ducking : baisse le récitateur pendant la récitation élève
/// - Pause inter-boucle configurable
/// - Suivi de position pour le karaoke
/// - Contrôle de vitesse (0.5x → 1.5x)
class AudioOrchestrator extends ChangeNotifier {
  AudioOrchestrator({
    required this.verseAudioUrl,
    this.pauseBetweenLoops = const Duration(seconds: 3),
  });

  final String verseAudioUrl;
  final Duration pauseBetweenLoops;

  // ── Lecteurs audio ──
  final AudioPlayer _reciterPlayer = AudioPlayer();
  final AudioPlayer _studentMicPlayer = AudioPlayer(); // Pour le playback replay

  // ── État ──
  TikrarPhase _currentPhase = TikrarPhase.ecoute6;
  int _currentRepetition = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isInPause = false; // Pause entre les boucles
  double _playbackRate = 1.0;
  double _reciterVolume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ── Getters ──
  TikrarPhase get currentPhase => _currentPhase;
  int get currentRepetition => _currentRepetition;
  int get totalRepetitions => _currentPhase.repetitions;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isInPause => _isInPause;
  double get playbackRate => _playbackRate;
  double get reciterVolume => _reciterVolume;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isListeningPhase => _currentPhase.isListening;

  /// Progression globale sur les 4 phases (0.0 → 1.0).
  double get globalProgress {
    const phases = TikrarPhase.values;
    final phaseIdx = phases.indexOf(_currentPhase);
    final totalReps = phases.fold<int>(0, (s, p) => s + p.repetitions);
    var doneReps = 0;
    for (var i = 0; i < phaseIdx; i++) {
      doneReps += phases[i].repetitions;
    }
    doneReps += _currentRepetition;
    return doneReps / totalReps;
  }

  /// Progression dans la phase courante (0.0 → 1.0).
  double get phaseProgress => _currentRepetition / _currentPhase.repetitions;

  // ── Callbacks ──
  VoidCallback? onPhaseChanged;
  VoidCallback? onRepetitionComplete;
  VoidCallback? onAllComplete;
  void Function(Duration position)? onPositionChanged;

  // ── Souscriptions ──
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;
  Timer? _pauseTimer;

  /// Initialise le lecteur et charge l'audio.
  Future<void> init() async {
    await _reciterPlayer.setSourceUrl(verseAudioUrl);
    await _reciterPlayer.setReleaseMode(ReleaseMode.stop);

    _positionSub = _reciterPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      onPositionChanged?.call(pos);
      notifyListeners();
    });

    _completeSub = _reciterPlayer.onPlayerComplete.listen((_) {
      _onRepetitionFinished();
    });

    // Récupérer la durée
    _reciterPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
  }

  /// Démarre la boucle TIKRAR depuis le début.
  Future<void> startTikrar() async {
    _currentPhase = TikrarPhase.ecoute6;
    _currentRepetition = 0;
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
    await _playCurrentRepetition();
  }

  /// Joue la répétition courante.
  Future<void> _playCurrentRepetition() async {
    if (_currentPhase.isListening) {
      // Phase d'écoute : volume normal
      await _reciterPlayer.setVolume(1.0);
      _reciterVolume = 1.0;
      await _reciterPlayer.setPlaybackRate(_playbackRate);
      await _reciterPlayer.seek(Duration.zero);
      await _reciterPlayer.resume();
    } else {
      // Phase de récitation : volume ducking (10% pour servir de fond léger)
      await _reciterPlayer.setVolume(0.08);
      _reciterVolume = 0.08;
      await _reciterPlayer.setPlaybackRate(_playbackRate);
      await _reciterPlayer.seek(Duration.zero);
      await _reciterPlayer.resume();
    }
    notifyListeners();
  }

  /// Appelé quand une répétition se termine.
  void _onRepetitionFinished() {
    _currentRepetition++;
    onRepetitionComplete?.call();
    notifyListeners();

    if (_currentRepetition >= _currentPhase.repetitions) {
      // Phase terminée → passer à la suivante
      _advancePhase();
    } else {
      // Pause inter-boucle puis rejouer
      _startPauseBetweenLoops();
    }
  }

  /// Pause entre deux répétitions.
  void _startPauseBetweenLoops() {
    _isInPause = true;
    notifyListeners();
    _pauseTimer = Timer(pauseBetweenLoops, () {
      _isInPause = false;
      notifyListeners();
      if (_isPlaying && !_isPaused) {
        _playCurrentRepetition();
      }
    });
  }

  /// Passe à la phase suivante.
  void _advancePhase() {
    final phases = TikrarPhase.values;
    final idx = phases.indexOf(_currentPhase);

    if (idx + 1 >= phases.length) {
      // Toutes les phases terminées
      _isPlaying = false;
      onAllComplete?.call();
      notifyListeners();
      return;
    }

    _currentPhase = phases[idx + 1];
    _currentRepetition = 0;
    onPhaseChanged?.call();
    notifyListeners();

    // Petite pause avant la nouvelle phase
    _isInPause = true;
    notifyListeners();
    _pauseTimer = Timer(const Duration(seconds: 2), () {
      _isInPause = false;
      if (_isPlaying && !_isPaused) {
        _playCurrentRepetition();
      }
      notifyListeners();
    });
  }

  /// Bascule pause / reprise.
  Future<void> togglePause() async {
    if (_isPaused) {
      _isPaused = false;
      await _reciterPlayer.resume();
    } else {
      _isPaused = true;
      await _reciterPlayer.pause();
      _pauseTimer?.cancel();
    }
    notifyListeners();
  }

  /// Change la vitesse de lecture.
  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 1.5);
    await _reciterPlayer.setPlaybackRate(_playbackRate);
    notifyListeners();
  }

  /// Saute directement la répétition courante (bouton "passer").
  void skipRepetition() {
    _reciterPlayer.stop();
    _onRepetitionFinished();
  }

  /// Saute toute la phase courante.
  void skipPhase() {
    _reciterPlayer.stop();
    _pauseTimer?.cancel();
    _currentRepetition = _currentPhase.repetitions;
    _advancePhase();
  }

  /// Joue l'audio une seule fois (hors boucle — pour l'étape NOUR).
  Future<void> playOnce() async {
    await _reciterPlayer.setVolume(1.0);
    _reciterVolume = 1.0;
    await _reciterPlayer.setPlaybackRate(_playbackRate);
    await _reciterPlayer.seek(Duration.zero);
    await _reciterPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  /// Joue l'audio une seule fois et attend la fin avant de retourner.
  /// Utilisé pour l'écoute séquentielle (Istima' du checkpoint).
  Future<void> playOnceAndWait() async {
    final completer = Completer<void>();

    StreamSubscription<void>? sub;
    sub = _reciterPlayer.onPlayerComplete.listen((_) {
      sub?.cancel();
      _isPlaying = false;
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    });

    await _reciterPlayer.setVolume(1.0);
    _reciterVolume = 1.0;
    await _reciterPlayer.setPlaybackRate(_playbackRate);
    await _reciterPlayer.seek(Duration.zero);
    await _reciterPlayer.resume();
    _isPlaying = true;
    notifyListeners();

    return completer.future;
  }

  /// Arrête tout.
  Future<void> stop() async {
    _isPlaying = false;
    _isPaused = false;
    _pauseTimer?.cancel();
    await _reciterPlayer.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _reciterPlayer.dispose();
    _studentMicPlayer.dispose();
    super.dispose();
  }
}

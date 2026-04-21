import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/player_models.dart';

/// Service de lecture audio séquentielle pour le Coran.
///
/// Gère :
///   - Lecture séquentielle d'une playlist (versets)
///   - Répétition par verset (1-5×)
///   - Contrôle vitesse (0.75x → 1.5x)
///   - Pause / reprise / suivant / précédent
///   - Callbacks de progression
class QuranAudioService extends ChangeNotifier {
  QuranAudioService();

  final AudioPlayer _player = AudioPlayer();

  // ── Configuration ──
  ReciterChoice _reciter = ReciterChoice.husary;
  double _speed = 1.0;
  int _globalRepeat = 1; // Répétitions par verset (overridable par entry)

  // ── Playlist ──
  List<PlaylistEntry> _playlist = [];
  int _currentIndex = 0;
  int _currentRepeat = 0; // Répétition en cours (0-based)

  // ── État de lecture ──
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ── Listeners ──
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;

  // ── Getters ──
  ReciterChoice get reciter => _reciter;
  double get speed => _speed;
  int get globalRepeat => _globalRepeat;
  List<PlaylistEntry> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  int get currentRepeat => _currentRepeat;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasPlaylist => _playlist.isNotEmpty;

  PlaylistEntry? get currentEntry =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  int get effectiveRepeatCount {
    final entry = currentEntry;
    if (entry == null) return _globalRepeat;
    return entry.repeatCount > 1 ? entry.repeatCount : _globalRepeat;
  }

  double get playlistProgress {
    if (_playlist.isEmpty) return 0;
    return (_currentIndex + 1) / _playlist.length;
  }

  // ── Initialisation ──

  void init() {
    _positionSub = _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      _onVerseComplete();
    });
  }

  // ── Configuration ──

  void setReciter(ReciterChoice r) {
    _reciter = r;
    notifyListeners();
  }

  void setSpeed(double s) {
    _speed = s.clamp(0.5, 2.0);
    if (_isPlaying) {
      _player.setPlaybackRate(_speed);
    }
    notifyListeners();
  }

  void setGlobalRepeat(int n) {
    _globalRepeat = n.clamp(1, 5);
    notifyListeners();
  }

  // ── Construction de playlist ──

  /// Mode lecture libre : sourate complète ou plage de versets.
  void buildLecturePlaylist({
    required int surah,
    required int startVerse,
    required int endVerse,
    int repeatEach = 1,
  }) {
    _playlist = [];
    for (int v = startVerse; v <= endVerse; v++) {
      _playlist.add(PlaylistEntry(
        surah: surah,
        verse: v,
        repeatCount: repeatEach,
      ));
    }
    _currentIndex = 0;
    _currentRepeat = 0;
    notifyListeners();
  }

  /// Mode révision SRS : playlist pré-construite par le backend.
  void buildRevisionPlaylist(List<RevisionVerse> verses) {
    _playlist = verses
        .map((v) => PlaylistEntry(
              surah: v.surah,
              verse: v.verse,
              repeatCount: v.adaptiveRepeat,
              srsTier: v.tier,
            ))
        .toList();
    _currentIndex = 0;
    _currentRepeat = 0;
    notifyListeners();
  }

  // ── Contrôles de lecture ──

  Future<void> play() async {
    if (_playlist.isEmpty) return;
    await _playCurrentVerse();
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPaused = true;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (!_isPaused) return;
    await _player.resume();
    _isPaused = false;
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_isPaused) {
      await resume();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    _currentRepeat = 0;
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      if (_isPlaying || _isPaused) {
        await _playCurrentVerse();
      } else {
        notifyListeners();
      }
    } else {
      // Fin de playlist
      await stop();
    }
  }

  Future<void> previous() async {
    _currentRepeat = 0;
    if (_currentIndex > 0) {
      _currentIndex--;
      if (_isPlaying || _isPaused) {
        await _playCurrentVerse();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> jumpToIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    _currentRepeat = 0;
    if (_isPlaying || _isPaused) {
      await _playCurrentVerse();
    } else {
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  // ── Logique interne ──

  Future<void> _playCurrentVerse() async {
    final entry = currentEntry;
    if (entry == null) return;

    final url = _reciter.audioUrl(entry.surah, entry.verse);
    debugPrint('[QuranAudio] Playing $url (rep ${_currentRepeat + 1}/${effectiveRepeatCount})');

    await _player.stop();
    await _player.setPlaybackRate(_speed);
    await _player.play(UrlSource(url));

    _isPlaying = true;
    _isPaused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  void _onVerseComplete() {
    _currentRepeat++;

    if (_currentRepeat < effectiveRepeatCount) {
      // Encore des répétitions pour ce verset
      _playCurrentVerse();
    } else {
      // Passer au verset suivant
      _currentRepeat = 0;
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
        _playCurrentVerse();
      } else {
        // Fin de la playlist
        _isPlaying = false;
        _isPaused = false;
        notifyListeners();
      }
    }
  }

  // ── Cleanup ──

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// AsrReplayPlayer — Lecture audio synchronisée avec coloration mot par mot.
///
/// Lit l'enregistrement de l'utilisateur et illumine chaque mot
/// en temps réel selon son timestamp et son statut ASR :
///   - Actif (en cours)  → or + glow
///   - Correct (passé)   → vert émeraude
///   - Proche (passé)    → or chaud
///   - Erreur (passé)    → terre cuite
///   - Oublié            → sable barré
///   - À venir           → gris clair
///
/// Nécessite des WordResults avec startTime/endTime (endpoint /api/validate-replay).
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/hifz_v2_theme.dart';
import '../services/asr_service.dart';

class AsrReplayPlayer extends StatefulWidget {
  const AsrReplayPlayer({
    super.key,
    required this.wordResults,
    required this.audioPath,
    this.audioBytes,
    this.fontSize = 20,
    this.showHeardWord = true,
  });

  /// Résultats mot par mot avec timestamps (startTime, endTime).
  final List<AsrWordResult> wordResults;

  /// Chemin vers le fichier audio (mobile) ou 'web' si audioBytes est fourni.
  final String audioPath;

  /// Bytes audio (web uniquement — blob en mémoire).
  final List<int>? audioBytes;

  /// Taille de la police arabe.
  final double fontSize;

  /// Afficher le mot entendu sous les mots erronés.
  final bool showHeardWord;

  @override
  State<AsrReplayPlayer> createState() => _AsrReplayPlayerState();
}

class _AsrReplayPlayerState extends State<AsrReplayPlayer> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _syncTimer;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _activeWordIndex = -1;

  /// Mots filtrés (sans les extras) pour l'affichage principal.
  late final List<AsrWordResult> _displayWords;

  @override
  void initState() {
    super.initState();
    _displayWords = widget.wordResults
        .where((w) => w.status != AsrWordStatus.extra)
        .toList();

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _activeWordIndex = -1;
        });
        _syncTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      _syncTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      // Premier play ou reprise
      if (_position == Duration.zero || _position >= _duration) {
        // Démarrer depuis le début
        if (kIsWeb && widget.audioBytes != null) {
          await _player.setSource(BytesSource(
            Uint8List.fromList(widget.audioBytes!),
          ));
        } else {
          await _player.setSource(DeviceFileSource(widget.audioPath));
        }
      }
      await _player.resume();
      _startSyncLoop();
      setState(() => _isPlaying = true);
    }
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    // Sync toutes les 50ms (~20fps) — assez fluide pour le suivi mot à mot
    _syncTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateActiveWord();
    });
  }

  void _updateActiveWord() {
    final t = _position.inMilliseconds / 1000.0; // secondes

    int newActive = -1;
    for (int i = 0; i < _displayWords.length; i++) {
      final w = _displayWords[i];
      final start = w.startTime;
      final end = w.endTime;

      if (start == null || end == null) continue;

      if (t >= start && t < end) {
        newActive = i;
        break;
      }

      // Si on est entre ce mot et le suivant, garder ce mot comme actif
      if (t >= start && t >= end) {
        // Chercher si un prochain mot a commencé
        if (i + 1 < _displayWords.length) {
          final nextStart = _displayWords[i + 1].startTime;
          if (nextStart != null && t < nextStart) {
            newActive = i; // Entre deux mots — garder le dernier
            break;
          }
        } else {
          // Dernier mot
          newActive = i;
        }
      }
    }

    if (newActive != _activeWordIndex && mounted) {
      setState(() => _activeWordIndex = newActive);
    }
  }

  void _seekTo(double value) {
    final newPosition = Duration(milliseconds: (value * 1000).round());
    _player.seek(newPosition);
    setState(() => _position = newPosition);
    _updateActiveWord();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Contrôles audio ──
        _buildControls(),
        const SizedBox(height: 16),
        // ── Texte synchronisé ──
        Expanded(child: _buildSyncText()),
      ],
    );
  }

  Widget _buildControls() {
    final posSeconds = _position.inMilliseconds / 1000.0;
    final durSeconds =
        _duration.inMilliseconds > 0 ? _duration.inMilliseconds / 1000.0 : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: HifzColors.ivoryWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HifzColors.ivoryDark),
      ),
      child: Row(
        children: [
          // Bouton play/pause
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HifzColors.emerald,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Temps écoulé
          Text(_fmt(_position),
              style: HifzTypo.body(color: HifzColors.textMedium)
                  .copyWith(fontSize: 12, fontFeatures: [const FontFeature.tabularFigures()])),
          const SizedBox(width: 8),

          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: HifzColors.emerald,
                inactiveTrackColor: HifzColors.ivoryDark,
                thumbColor: HifzColors.emerald,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: posSeconds.clamp(0, durSeconds),
                max: durSeconds,
                onChanged: _seekTo,
              ),
            ),
          ),

          const SizedBox(width: 8),
          // Durée totale
          Text(_fmt(_duration),
              style: HifzTypo.body(color: HifzColors.textLight)
                  .copyWith(fontSize: 12, fontFeatures: [const FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _buildSyncText() {
    final t = _position.inMilliseconds / 1000.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HifzColors.ivoryWarm,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 5,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: List.generate(_displayWords.length, (i) {
              final w = _displayWords[i];
              return _ReplayWord(
                word: w,
                isActive: i == _activeWordIndex,
                isPast: _isWordPast(w, i, t),
                showHeard: widget.showHeardWord,
                fontSize: widget.fontSize,
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Un mot est "passé" si on a dépassé son endTime,
  /// ou s'il est missing et que le mot suivant (non-missing) a commencé.
  bool _isWordPast(AsrWordResult w, int index, double currentTime) {
    if (w.endTime != null) return currentTime >= w.endTime!;

    // Mot missing — pas de timestamp. Chercher le prochain mot avec timestamp.
    for (int j = index + 1; j < _displayWords.length; j++) {
      final next = _displayWords[j];
      if (next.startTime != null) {
        return currentTime >= next.startTime!;
      }
    }
    return false;
  }
}

// ── Mot individuel avec animation ──

class _ReplayWord extends StatelessWidget {
  const _ReplayWord({
    required this.word,
    required this.isActive,
    required this.isPast,
    required this.showHeard,
    required this.fontSize,
  });

  final AsrWordResult word;
  final bool isActive;
  final bool isPast;
  final bool showHeard;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    bool strikethrough = false;

    if (isActive) {
      // Mot en cours de lecture → or + glow
      textColor = HifzColors.textDark;
      bgColor = HifzColors.gold.withOpacity(0.3);
    } else if (isPast) {
      // Mot déjà lu → couleur selon statut
      switch (word.status) {
        case AsrWordStatus.correct:
          textColor = HifzColors.correct;
          bgColor = HifzColors.correct.withOpacity(0.1);
        case AsrWordStatus.close:
          textColor = HifzColors.close;
          bgColor = HifzColors.close.withOpacity(0.1);
        case AsrWordStatus.wrong:
          textColor = HifzColors.wrong;
          bgColor = HifzColors.wrong.withOpacity(0.1);
        case AsrWordStatus.missing:
          textColor = HifzColors.missing;
          bgColor = Colors.transparent;
          strikethrough = true;
        case AsrWordStatus.extra:
          textColor = HifzColors.textLight;
          bgColor = Colors.transparent;
      }
    } else {
      // Mot à venir → gris
      textColor = HifzColors.textLight.withOpacity(0.5);
      bgColor = Colors.transparent;
    }

    final showHeardLabel = showHeard &&
        isPast &&
        word.expected != null &&
        (word.status == AsrWordStatus.wrong ||
            word.status == AsrWordStatus.close);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: HifzColors.gold.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word.word,
            style: HifzTypo.verse(size: fontSize, color: textColor).copyWith(
              decoration:
                  strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: HifzColors.missing,
            ),
          ),
          if (showHeardLabel)
            Text(
              word.expected!,
              style: HifzTypo.verse(
                size: fontSize * 0.6,
                color: textColor.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}

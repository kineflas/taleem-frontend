import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../services/quran_audio_service.dart';

/// Barre de contrôle du lecteur Quran.
///
/// Contient : slider de progression, play/pause, next/prev,
/// vitesse, répétition, affichage du verset courant.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.service,
    this.surahName,
    this.onSpeedTap,
    this.onRepeatTap,
  });

  final QuranAudioService service;
  final String? surahName;
  final VoidCallback? onSpeedTap;
  final VoidCallback? onRepeatTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final entry = service.currentEntry;
        final progress = service.duration.inMilliseconds > 0
            ? service.position.inMilliseconds / service.duration.inMilliseconds
            : 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: HifzColors.ivoryWarm,
            border: Border(
              top: BorderSide(color: HifzColors.ivoryDark, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Info verset ──
                if (entry != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${surahName ?? 'Sourate ${entry.surah}'} — Verset ${entry.verse}',
                      style: HifzTypo.body(color: HifzColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ── Répétition ──
                if (entry != null && service.effectiveRepeatCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Répétition ${service.currentRepeat + 1}/${service.effectiveRepeatCount}',
                      style: HifzTypo.stepLabel(color: HifzColors.gold),
                    ),
                  ),

                // ── Slider ──
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: HifzColors.emerald,
                    inactiveTrackColor: HifzColors.ivoryDark,
                    thumbColor: HifzColors.emerald,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) {
                      final ms = (v * service.duration.inMilliseconds).round();
                      service.seekTo(Duration(milliseconds: ms));
                    },
                  ),
                ),

                // ── Temps ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(service.position),
                          style: _timeStyle),
                      Text(
                        'Verset ${service.currentIndex + 1}/${service.playlist.length}',
                        style: _timeStyle.copyWith(color: HifzColors.textMedium),
                      ),
                      Text(_formatDuration(service.duration),
                          style: _timeStyle),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Boutons principaux ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vitesse
                    _ActionChip(
                      label: '${service.speed}x',
                      onTap: onSpeedTap ?? () => _cycleSpeed(service),
                    ),

                    const SizedBox(width: 12),

                    // Précédent
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36,
                      color: HifzColors.emeraldDark,
                      onPressed: service.currentIndex > 0
                          ? () => service.previous()
                          : null,
                    ),

                    const SizedBox(width: 4),

                    // Play / Pause
                    _PlayButton(
                      isPlaying: service.isPlaying,
                      onPressed: () => service.togglePlayPause(),
                    ),

                    const SizedBox(width: 4),

                    // Suivant
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36,
                      color: HifzColors.emeraldDark,
                      onPressed: service.currentIndex < service.playlist.length - 1
                          ? () => service.next()
                          : null,
                    ),

                    const SizedBox(width: 12),

                    // Repeat
                    _ActionChip(
                      label: '${service.globalRepeat}×',
                      icon: Icons.repeat_rounded,
                      onTap: onRepeatTap ?? () => _cycleRepeat(service),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cycleSpeed(QuranAudioService s) {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final idx = speeds.indexOf(s.speed);
    final next = speeds[(idx + 1) % speeds.length];
    s.setSpeed(next);
  }

  void _cycleRepeat(QuranAudioService s) {
    final next = s.globalRepeat >= 5 ? 1 : s.globalRepeat + 1;
    s.setGlobalRepeat(next);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static final _timeStyle = GoogleFonts.nunito(
    fontSize: 12,
    color: HifzColors.textLight,
  );
}

// ── Sous-widgets ────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HifzColors.emerald,
        boxShadow: [
          BoxShadow(
            color: HifzColors.emerald.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    this.icon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HifzColors.ivoryDark, width: 1),
          color: HifzColors.ivory,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: HifzColors.textMedium),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HifzColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

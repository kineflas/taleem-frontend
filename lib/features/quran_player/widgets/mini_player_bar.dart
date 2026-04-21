import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../providers/quran_player_provider.dart';
import '../services/quran_audio_service.dart';

/// Barre mini-player persistante affichée au-dessus de la bottom nav.
///
/// Visible uniquement quand le service audio a une playlist active.
/// Tap → ouvre le player en plein écran (/quran-player).
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(quranAudioServiceProvider);

    // N'afficher que si une playlist est chargée
    if (!audioService.hasPlaylist) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        // Masquer si aucune playlist
        if (!audioService.hasPlaylist) return const SizedBox.shrink();

        final entry = audioService.currentEntry;
        if (entry == null) return const SizedBox.shrink();

        final progress = audioService.duration.inMilliseconds > 0
            ? audioService.position.inMilliseconds /
                audioService.duration.inMilliseconds
            : 0.0;

        final surahName = audioService.currentSurahName;
        final verseInfo = 'Verset ${entry.verse}';

        return GestureDetector(
          onTap: () => context.push('/quran-player'),
          child: Container(
            decoration: BoxDecoration(
              color: HifzColors.emeraldDark,
              boxShadow: [
                BoxShadow(
                  color: HifzColors.textDark.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de progression fine
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: HifzColors.emerald.withOpacity(0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(HifzColors.gold),
                ),

                // Contenu du mini-player
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Icône disque / animation
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: HifzColors.emerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          audioService.isPlaying
                              ? Icons.graphic_eq_rounded
                              : Icons.auto_stories_rounded,
                          color: HifzColors.gold,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Info sourate + verset
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              surahName ?? 'Sourate ${entry.surah}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HifzColors.ivory,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$verseInfo — ${audioService.currentIndex + 1}/${audioService.playlist.length}',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: HifzColors.ivory.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bouton précédent
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: HifzColors.ivory.withOpacity(0.8),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        onPressed: audioService.currentIndex > 0
                            ? () => audioService.previous()
                            : null,
                      ),

                      // Bouton play/pause
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: HifzColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            audioService.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: HifzColors.emeraldDark,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => audioService.togglePlayPause(),
                        ),
                      ),

                      // Bouton suivant
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        color: HifzColors.ivory.withOpacity(0.8),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        onPressed: audioService.currentIndex <
                                audioService.playlist.length - 1
                            ? () => audioService.next()
                            : null,
                      ),

                      // Bouton stop
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: HifzColors.ivory.withOpacity(0.5),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        onPressed: () => audioService.stop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

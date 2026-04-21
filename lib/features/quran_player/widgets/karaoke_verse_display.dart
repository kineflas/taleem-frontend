import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hifz_v2/models/hifz_v2_theme.dart';
import '../../hifz_v2/models/wird_models.dart';
import '../services/quran_audio_service.dart';

/// Affichage karaoke mot par mot pour le lecteur Coran.
///
/// Utilise [EnrichedVerse.audioTimings] pour synchroniser
/// le highlight mot-par-mot avec la position audio.
///
/// Pour les sourates sans timing, fallback sur le highlight par verset.
class KaraokeVerseDisplay extends ConsumerStatefulWidget {
  const KaraokeVerseDisplay({
    super.key,
    required this.verses,
    required this.audioService,
    required this.startVerse,
    this.showTranslation = false,
    this.translations,
  });

  final List<EnrichedVerse> verses;
  final QuranAudioService audioService;
  final int startVerse;
  final bool showTranslation;
  final Map<int, String>? translations;

  @override
  ConsumerState<KaraokeVerseDisplay> createState() =>
      _KaraokeVerseDisplayState();
}

class _KaraokeVerseDisplayState extends ConsumerState<KaraokeVerseDisplay> {
  final ScrollController _scrollCtrl = ScrollController();
  int? _lastScrolledVerse;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleVerses = widget.verses
        .where((v) => v.verseNumber >= widget.startVerse)
        .toList();

    return ListenableBuilder(
      listenable: widget.audioService,
      builder: (context, _) {
        final currentVerse =
            widget.audioService.currentEntry?.verse ?? widget.startVerse;

        // Auto-scroll
        if (currentVerse != _lastScrolledVerse) {
          _lastScrolledVerse = currentVerse;
          _scrollToVerse(currentVerse, visibleVerses);
        }

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: visibleVerses.length,
          itemBuilder: (context, index) {
            final verse = visibleVerses[index];
            final isActive = verse.verseNumber == currentVerse;
            final isPast = verse.verseNumber < currentVerse;

            // Translation : soit depuis EnrichedVerse, soit depuis la map externe
            final translation = widget.showTranslation
                ? (verse.textFr ??
                    widget.translations?[verse.verseNumber])
                : null;

            if (isActive && verse.audioTimings != null) {
              // Mode karaoke actif — highlight mot par mot
              return _KaraokeActiveCard(
                verse: verse,
                audioService: widget.audioService,
                translation: translation,
              );
            }

            // Mode normal — highlight par verset
            return _VerseCard(
              verseNumber: verse.verseNumber,
              text: verse.textAr,
              translation: translation,
              isActive: isActive,
              isPast: isPast,
            );
          },
        );
      },
    );
  }

  void _scrollToVerse(int verseNum, List<EnrichedVerse> visibleVerses) {
    final index = visibleVerses.indexWhere((v) => v.verseNumber == verseNum);
    if (index < 0 || !_scrollCtrl.hasClients) return;

    const estimatedHeight = 160.0;
    final targetOffset = index * estimatedHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }
}

// ── Karaoke Active Card ─────────────────────────────────────────────

class _KaraokeActiveCard extends StatelessWidget {
  const _KaraokeActiveCard({
    required this.verse,
    required this.audioService,
    this.translation,
  });

  final EnrichedVerse verse;
  final QuranAudioService audioService;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final timings = verse.audioTimings!;
    final positionSec =
        audioService.position.inMilliseconds / 1000.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HifzColors.goldMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HifzColors.gold, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HifzColors.gold,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${verse.verseNumber}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: HifzColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'EN COURS',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Texte arabe avec karaoke mot par mot
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: List.generate(verse.words.length, (i) {
                final word = verse.words[i];

                // Déterminer l'état du mot
                _WordState wordState;
                if (i < timings.length) {
                  final wordStart = timings[i];
                  final wordEnd = (i + 1 < timings.length)
                      ? timings[i + 1]
                      : wordStart + 2.0; // Dernier mot ~ 2s

                  if (positionSec >= wordStart && positionSec < wordEnd) {
                    wordState = _WordState.active;
                  } else if (positionSec >= wordEnd) {
                    wordState = _WordState.past;
                  } else {
                    wordState = _WordState.pending;
                  }
                } else {
                  wordState = _WordState.pending;
                }

                return AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.amiri(
                    fontSize: wordState == _WordState.active ? 30 : 24,
                    height: 2.0,
                    color: switch (wordState) {
                      _WordState.active => HifzColors.karaokeActive,
                      _WordState.past => HifzColors.karaokePast,
                      _WordState.pending => HifzColors.karaokePending,
                    },
                    fontWeight: wordState == _WordState.active
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  child: Text(word),
                );
              }),
            ),
          ),

          // Traduction
          if (translation != null) ...[
            const SizedBox(height: 8),
            Divider(color: HifzColors.ivoryDark, height: 1),
            const SizedBox(height: 8),
            Text(
              translation!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.5,
                color: HifzColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _WordState { active, past, pending }

// ── Standard Verse Card (non-active / no timing) ────────────────────

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verseNumber,
    required this.text,
    this.translation,
    required this.isActive,
    required this.isPast,
  });

  final int verseNumber;
  final String text;
  final String? translation;
  final bool isActive;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? HifzColors.goldMuted
        : isPast
            ? HifzColors.emeraldMuted
            : Colors.transparent;

    final textColor = isActive
        ? HifzColors.textDark
        : isPast
            ? HifzColors.emeraldDark
            : HifzColors.textLight;

    final borderColor = isActive ? HifzColors.gold : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? HifzColors.gold : HifzColors.ivoryDark,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$verseNumber',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : HifzColors.textMedium,
                  ),
                ),
              ),
              if (isPast) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded,
                    color: HifzColors.emerald, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              style: GoogleFonts.amiri(
                fontSize: isActive ? 26 : 22,
                height: 2.0,
                color: textColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (translation != null) ...[
            const SizedBox(height: 8),
            Divider(color: HifzColors.ivoryDark, height: 1),
            const SizedBox(height: 8),
            Text(
              translation!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.5,
                color: HifzColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

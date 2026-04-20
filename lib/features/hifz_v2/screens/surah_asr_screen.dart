/// SurahAsrScreen — Validation d'une sourate complète par récitation vocale.
///
/// L'utilisateur enregistre sa récitation de toute la sourate,
/// puis l'audio est envoyé au serveur ASR (/api/validate-surah)
/// qui retourne un résultat mot par mot.
///
/// Flow :
///   1. Prêt — consignes + bouton démarrer
///   2. Enregistrement — micro actif, timer, possibilité d'afficher le texte
///   3. Validation — envoi au serveur, loading
///   4. Résultats — score global + texte coloré mot par mot
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hifz_v2_theme.dart';
import '../models/wird_models.dart';
import '../providers/hifz_v2_provider.dart';
import '../services/asr_service.dart';
import '../widgets/asr_replay_player.dart';

enum _AsrPhase { ready, recording, validating, results }

class SurahAsrScreen extends ConsumerStatefulWidget {
  const SurahAsrScreen({
    super.key,
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahNameFr,
    required this.allVerses,
  });

  final int surahNumber;
  final String surahNameAr;
  final String surahNameFr;
  final List<EnrichedVerse> allVerses;

  @override
  ConsumerState<SurahAsrScreen> createState() => _SurahAsrScreenState();
}

class _SurahAsrScreenState extends ConsumerState<SurahAsrScreen> {
  _AsrPhase _phase = _AsrPhase.ready;
  final AsrService _asr = AsrService();

  // Recording
  int _recSeconds = 0;
  Timer? _recTimer;
  bool _showText = false;

  // Audio conservé pour le replay
  String? _savedAudioPath;
  Uint8List? _savedAudioBytes;

  // Results
  AsrValidationResult? _result;
  bool _showReplay = false;

  @override
  void dispose() {
    _recTimer?.cancel();
    _asr.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _asr.startRecording();
      _recSeconds = 0;
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recSeconds++);
      });
      setState(() => _phase = _AsrPhase.recording);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro : $e')),
        );
      }
    }
  }

  Future<void> _stopAndValidate() async {
    _recTimer?.cancel();

    setState(() => _phase = _AsrPhase.validating);

    final audioPath = await _asr.stopRecording();
    if (audioPath == null) {
      setState(() => _phase = _AsrPhase.ready);
      return;
    }

    // Conserver l'audio pour le replay (ne pas appeler cleanup)
    _savedAudioPath = audioPath;
    _savedAudioBytes = _asr.webRecordingBytes;

    // Textes attendus par verset
    final verseTexts = widget.allVerses.map((v) => v.textAr).toList();

    final result = await _asr.validateSurahRecording(
      audioPath: audioPath,
      verseTexts: verseTexts,
    );

    if (!mounted) return;

    setState(() {
      _result = result;
      _phase = _AsrPhase.results;
      _showReplay = false;
    });
  }

  void _retry() {
    _asr.cleanup();
    setState(() {
      _phase = _AsrPhase.ready;
      _result = null;
      _recSeconds = 0;
      _showReplay = false;
      _savedAudioPath = null;
      _savedAudioBytes = null;
    });
  }

  /// Vérifie qu'au moins quelques mots ont des timestamps pour le replay.
  bool _hasTimestamps(AsrValidationResult r) {
    return r.wordResults.any((w) => w.startTime != null && w.endTime != null);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HifzColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: switch (_phase) {
                _AsrPhase.ready => _buildReady(),
                _AsrPhase.recording => _buildRecording(),
                _AsrPhase.validating => _buildValidating(),
                _AsrPhase.results => _buildResults(),
              },
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
            onPressed: () {
              if (_phase == _AsrPhase.recording) {
                _asr.stopRecording();
                _recTimer?.cancel();
              }
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          Column(
            children: [
              Text(widget.surahNameAr,
                  style: HifzTypo.verse(size: 20, color: HifzColors.gold)),
              Text(widget.surahNameFr,
                  style: HifzTypo.body(color: HifzColors.textMedium)
                      .copyWith(fontSize: 12)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HifzColors.emeraldMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.allVerses.length} versets',
              style: HifzTypo.body(color: HifzColors.emerald)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 1 : Prêt ──

  Widget _buildReady() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HifzColors.emerald.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded,
                size: 40, color: HifzColors.emerald),
          ),
          const SizedBox(height: 24),
          Text('Validation vocale',
              style: HifzTypo.sectionTitle()),
          const SizedBox(height: 8),
          Text(
            'Récite la sourate ${widget.surahNameFr} en entier.\n'
            'Le serveur analysera ta récitation mot par mot.',
            textAlign: TextAlign.center,
            style: HifzTypo.body(color: HifzColors.textMedium),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              style: HifzDecor.primaryButton,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Commencer l\'enregistrement'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 2 : Enregistrement ──

  Widget _buildRecording() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Timer
          const SizedBox(height: 16),
          Text(
            _formatDuration(_recSeconds),
            style: HifzTypo.score(color: HifzColors.wrong).copyWith(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: HifzColors.wrong,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Enregistrement en cours...',
                  style: HifzTypo.body(color: HifzColors.wrong)),
            ],
          ),

          const SizedBox(height: 20),

          // Toggle texte
          OutlinedButton.icon(
            onPressed: () => setState(() => _showText = !_showText),
            style: HifzDecor.secondaryButton,
            icon: Icon(_showText ? Icons.visibility_off : Icons.visibility,
                size: 18),
            label: Text(_showText ? 'Masquer le texte' : 'Afficher le texte'),
          ),

          const SizedBox(height: 12),

          // Texte de la sourate (scrollable)
          if (_showText)
            Expanded(
              child: ListView.separated(
                itemCount: widget.allVerses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final v = widget.allVerses[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: HifzColors.ivoryWarm,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${v.verseNumber}',
                            style: HifzTypo.body(color: HifzColors.textLight)
                                .copyWith(fontSize: 11)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.textAr,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: HifzTypo.verse(size: 17),
                          ),
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

          // Bouton arrêter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _stopAndValidate,
              style: ElevatedButton.styleFrom(
                backgroundColor: HifzColors.wrong,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Arrêter et valider'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 3 : Validation ──

  Widget _buildValidating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: HifzColors.emerald),
          const SizedBox(height: 24),
          Text('Analyse de ta récitation...',
              style: HifzTypo.body(color: HifzColors.textMedium)),
          const SizedBox(height: 8),
          Text(
            '${widget.allVerses.length} versets à analyser',
            style: HifzTypo.body(color: HifzColors.textLight),
          ),
        ],
      ),
    );
  }

  // ── Phase 4 : Résultats ──

  Widget _buildResults() {
    final r = _result;
    if (r == null) return const SizedBox.shrink();

    final pct = (r.accuracy * 100).round();
    final color = pct >= 70 ? HifzColors.correct : pct >= 50 ? HifzColors.close : HifzColors.wrong;
    final stars = pct >= 90 ? 3 : pct >= 70 ? 2 : pct >= 50 ? 1 : 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Score
          Text(
            '$pct%',
            style: HifzTypo.score(color: color),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: HifzColors.gold,
              size: 32,
            )),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip('Corrects', '${r.correctWords}', HifzColors.correct),
              _StatChip('Erreurs', '${r.wrongWords}', HifzColors.wrong),
              _StatChip('Oubliés', '${r.missingWords}', HifzColors.missing),
            ],
          ),

          const SizedBox(height: 12),

          // Toggle Replay / Texte statique
          if (_savedAudioPath != null && _hasTimestamps(r))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showReplay = !_showReplay),
                style: HifzDecor.secondaryButton.copyWith(
                  minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
                ),
                icon: Icon(
                  _showReplay ? Icons.text_fields_rounded : Icons.play_circle_rounded,
                  size: 18,
                ),
                label: Text(_showReplay ? 'Vue statique' : 'Réécouter avec suivi'),
              ),
            ),

          // Texte coloré mot par mot — statique ou replay synchronisé
          Expanded(
            child: _showReplay && _savedAudioPath != null
                ? AsrReplayPlayer(
                    wordResults: r.wordResults,
                    audioPath: _savedAudioPath!,
                    audioBytes: _savedAudioBytes,
                    fontSize: 18,
                  )
                : Container(
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
                          spacing: 6,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: r.wordResults
                              .where((w) => w.status != AsrWordStatus.extra)
                              .map((w) => _ColoredWord(w))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(HifzColors.correct, 'Correct'),
              const SizedBox(width: 12),
              _LegendDot(HifzColors.close, 'Proche'),
              const SizedBox(width: 12),
              _LegendDot(HifzColors.wrong, 'Erreur'),
              const SizedBox(width: 12),
              _LegendDot(HifzColors.missing, 'Oublié'),
            ],
          ),

          const SizedBox(height: 16),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retry,
                  style: HifzDecor.secondaryButton,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: HifzDecor.primaryButton,
                  child: const Text('Terminer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──

class _ColoredWord extends StatelessWidget {
  const _ColoredWord(this.word);
  final AsrWordResult word;

  @override
  Widget build(BuildContext context) {
    final color = switch (word.status) {
      AsrWordStatus.correct => HifzColors.correct,
      AsrWordStatus.close => HifzColors.close,
      AsrWordStatus.wrong => HifzColors.wrong,
      AsrWordStatus.missing => HifzColors.missing,
      AsrWordStatus.extra => HifzColors.textLight,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        word.word,
        style: HifzTypo.verse(size: 18, color: color),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: HifzTypo.body(color: color)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: HifzTypo.body(color: HifzColors.textLight)
                .copyWith(fontSize: 11)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: HifzTypo.body(color: HifzColors.textLight)
                .copyWith(fontSize: 10)),
      ],
    );
  }
}

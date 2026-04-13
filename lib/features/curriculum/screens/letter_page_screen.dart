import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';
import '../widgets/mouth_diagram_widget.dart';
import 'letter_speed_round_screen.dart';
import 'letter_mastery_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LetterPageScreen — parcours lettre unifié en 3 phases
//
// Phase 1 : Découverte  (scroll passif : hero, 4 formes, makhraj, famille)
// Phase 2 : Quiz        (5-6 questions inline, AnimatedSwitcher)
// Phase 3 : Résultat    (étoiles, XP, retour unité)
//
// Paramètres :
//   enrollmentId — pour persister le score via completeItem
//   unit         — unité de type LETTER avec ses items (4 formes)
//   existingStars — étoiles déjà acquises (0-3), -1 si première visite
// ─────────────────────────────────────────────────────────────────────────────

class LetterPageScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  final CurriculumUnit unit;
  final int existingStars; // 0-3

  const LetterPageScreen({
    super.key,
    required this.enrollmentId,
    required this.unit,
    this.existingStars = 0,
  });

  @override
  ConsumerState<LetterPageScreen> createState() => _LetterPageScreenState();
}

// ── Phases ──────────────────────────────────────────────────────────────────
enum _Phase { discovery, quiz, result }

class _LetterPageScreenState extends ConsumerState<LetterPageScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.discovery;

  // Audio
  final AudioPlayer _audio = AudioPlayer();
  bool _isPlaying = false;

  // Quiz state
  late List<_QuizQuestion> _questions;
  int _qIndex = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;
  bool _saving = false;

  // Result
  int _earnedStars = 0;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    // Auto-play audio on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.unit.audioUrl != null) _playAudio();
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  // ── Audio ──────────────────────────────────────────────────────────────────

  Future<void> _playAudio({String? overrideUrl}) async {
    final raw = overrideUrl ?? widget.unit.audioUrl;
    if (raw == null) return;
    if (_isPlaying) {
      await _audio.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      final url = raw.startsWith('http') ? raw : '${ApiConstants.baseUrl}$raw';
      setState(() => _isPlaying = true);
      await _audio.play(UrlSource(url));
      _audio.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  // ── Quiz builder ───────────────────────────────────────────────────────────

  List<_QuizQuestion> _buildQuestions() {
    final rng = Random();
    final glyph = widget.unit.titleAr; // isolated glyph
    final letterName = glyphToName[glyph] ?? widget.unit.titleFr ?? glyph;
    final letterItems = widget.unit.items
        .where((i) => i.letterPosition != null)
        .toList();

    final questions = <_QuizQuestion>[];

    // ── Q0 : Audio-first — Écoute avant de voir le glyph ─────────────
    if (widget.unit.audioUrl != null) {
      final distractors = allLetterNames
          .where((n) => n != letterName)
          .toList()
        ..shuffle(rng);
      final choices = [letterName, ...distractors.take(3)]..shuffle(rng);
      questions.add(_QuizQuestion(
        type: _QType.soundToName,
        questionFr: '🎧 Écoute attentivement — quelle lettre as-tu entendu ?',
        displayGlyph: null,
        correctAnswer: letterName,
        choices: choices,
        itemAudioUrl: widget.unit.audioUrl,
      ));
    }

    // ── Q1 : Glyph → Nom (lettre affichée, choisir son nom) ─────────────
    {
      final distractors = allLetterNames
          .where((n) => n != letterName)
          .toList()
        ..shuffle(rng);
      final choices = [letterName, ...distractors.take(3)]..shuffle(rng);
      questions.add(_QuizQuestion(
        type: _QType.glyphToName,
        questionFr: 'Quelle est cette lettre ?',
        displayGlyph: glyph,
        correctAnswer: letterName,
        choices: choices,
      ));
    }

    // ── Q2 : Nom → Glyph (nom affiché, choisir le bon glyph) ────────────
    {
      final otherGlyphs = glyphToName.keys
          .where((g) => g != glyph)
          .toList()
        ..shuffle(rng);
      final choices = [glyph, ...otherGlyphs.take(3)]..shuffle(rng);
      questions.add(_QuizQuestion(
        type: _QType.nameToGlyph,
        questionFr: 'Laquelle est la lettre $letterName ?',
        displayGlyph: null,
        correctAnswer: glyph,
        choices: choices,
        isGlyphChoice: true,
      ));
    }

    // ── Q3 & Q4 : Reconnaissance de position (formes distinctes) ────────
    if (letterItems.length >= 2) {
      const posLabels = {
        'isolated': 'Isolée',
        'initial':  'Initiale',
        'medial':   'Médiane',
        'final':    'Finale',
      };

      // Group items by their visual glyph (titleAr) to detect identical forms
      final Map<String, List<CurriculumItem>> formGroups = {};
      for (final item in letterItems) {
        formGroups.putIfAbsent(item.titleAr, () => []).add(item);
      }

      // Only quiz on visually distinct forms to avoid impossible questions
      final distinctForms = formGroups.values.toList()..shuffle(rng);
      int added = 0;
      for (final group in distinctForms) {
        if (added >= 2) break;
        final item = group.first;
        final correctPos = posLabels[item.letterPosition] ?? '';
        if (correctPos.isEmpty) continue;

        // All valid position labels for this visual form
        final allValidPos = group
            .map((i) => posLabels[i.letterPosition] ?? '')
            .where((p) => p.isNotEmpty)
            .toList();
        final extraAnswers = allValidPos.where((p) => p != correctPos).toList();

        final questionLabel = allValidPos.length > 1
            ? 'Quelle est la position de cette forme ? (plusieurs réponses valides)'
            : 'Quelle est la position de cette forme ?';

        final choices = posLabels.values.toList()..shuffle(rng);
        questions.add(_QuizQuestion(
          type: _QType.positionRecognition,
          questionFr: questionLabel,
          displayGlyph: item.titleAr,
          correctAnswer: correctPos,
          extraCorrectAnswers: extraAnswers,
          choices: choices,
          itemAudioUrl: item.audioUrl,
        ));
        added++;
      }
    }

    // ── Q5 : Famille de lettres (si la lettre a des sœurs) ───────────────
    final familyIdx = glyphToFamilyIndex[glyph];
    if (familyIdx != null) {
      final family = letterFamilies[familyIdx];
      final sisters = family.letters.where((l) => l != glyph).toList();
      if (sisters.isNotEmpty) {
        final randomSister = sisters[rng.nextInt(sisters.length)];
        // Distractors : glyphs from OTHER families
        final otherGlyphs = glyphToName.keys
            .where((g) => g != glyph && glyphToFamilyIndex[g] != familyIdx)
            .toList()
          ..shuffle(rng);
        final choices = [randomSister, ...otherGlyphs.take(3)]..shuffle(rng);
        questions.add(_QuizQuestion(
          type: _QType.familyRecognition,
          questionFr: 'Laquelle est dans la même famille que $glyph ($letterName) ?',
          displayGlyph: null,
          correctAnswer: randomSister,
          choices: choices,
          isGlyphChoice: true,
        ));
      }
    }

    // ── Q6 : Audio → Nom (si audioUrl disponible) ────────────────────────
    if (widget.unit.audioUrl != null && questions.length < 6) {
      final distractors = allLetterNames
          .where((n) => n != letterName)
          .toList()
        ..shuffle(rng);
      final choices = [letterName, ...distractors.take(3)]..shuffle(rng);
      questions.add(_QuizQuestion(
        type: _QType.soundToName,
        questionFr: 'Écoute et identifie la lettre',
        displayGlyph: null,
        correctAnswer: letterName,
        choices: choices,
        itemAudioUrl: widget.unit.audioUrl,
      ));
    }

    // ── Questions de révision — lettres précédentes ───────────────────────
    // Find letters that come before the current one in letterGroups order.
    // Pick up to 3 at random, add one question each (varied type).
    // The current letter is always a distractor to raise difficulty.
    final allGlyphsOrdered = letterGroups.expand((g) => g).toList();
    final currentIdx = allGlyphsOrdered.indexOf(glyph);
    if (currentIdx > 0) {
      final previousGlyphs = allGlyphsOrdered.sublist(0, currentIdx);
      final shuffledPrev = [...previousGlyphs]..shuffle(rng);
      final reviewCount = min(3, shuffledPrev.length);

      for (final prevGlyph in shuffledPrev.take(reviewCount)) {
        final prevName = glyphToName[prevGlyph] ?? prevGlyph;
        final questionType = rng.nextInt(3); // 0 = glyph→name, 1 = name→glyph, 2 = audio→name

        if (questionType == 0) {
          // Show previous glyph → choose its name
          final distractors = allLetterNames
              .where((n) => n != prevName)
              .toList()
            ..shuffle(rng);
          // Force current letter name as one distractor to raise difficulty
          final pool = [letterName, ...distractors.where((n) => n != letterName)]
              .take(3)
              .toList();
          final choices = [prevName, ...pool]..shuffle(rng);
          questions.add(_QuizQuestion(
            type: _QType.glyphToName,
            questionFr: '🔄 Révision — Quelle est cette lettre ?',
            displayGlyph: prevGlyph,
            correctAnswer: prevName,
            choices: choices,
          ));
        } else if (questionType == 1) {
          // Show previous letter name → choose its glyph
          final otherGlyphs = glyphToName.keys
              .where((g) => g != prevGlyph)
              .toList()
            ..shuffle(rng);
          // Force current glyph as one distractor
          final pool = [glyph, ...otherGlyphs.where((g) => g != glyph)]
              .take(3)
              .toList();
          final choices = [prevGlyph, ...pool]..shuffle(rng);
          questions.add(_QuizQuestion(
            type: _QType.nameToGlyph,
            questionFr: '🔄 Révision — Laquelle est la lettre $prevName ?',
            displayGlyph: null,
            correctAnswer: prevGlyph,
            choices: choices,
            isGlyphChoice: true,
          ));
        } else {
          // Play audio of previous letter → choose its name
          final prevFilename = glyphToAudioFilename[prevGlyph]
              ?? glyphToName[prevGlyph]?.toLowerCase().replaceAll(' ', '_')
              ?? prevGlyph;
          final prevAudioUrl =
              '${ApiConstants.baseUrl}/static/audio/letters/$prevFilename.mp3';
          final distractors = allLetterNames
              .where((n) => n != prevName)
              .toList()
            ..shuffle(rng);
          final pool = [letterName, ...distractors.where((n) => n != letterName)]
              .take(3)
              .toList();
          final choices = [prevName, ...pool]..shuffle(rng);
          questions.add(_QuizQuestion(
            type: _QType.soundToName,
            questionFr: '🔄 Révision — Écoute et identifie la lettre',
            displayGlyph: null,
            correctAnswer: prevName,
            choices: choices,
            itemAudioUrl: prevAudioUrl,
          ));
        }
      }
    }

    questions.shuffle(rng);
    return questions;
  }

  // ── Quiz handlers ──────────────────────────────────────────────────────────

  void _onSelectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selected = answer;
      _answered = true;
      if (_questions[_qIndex].isCorrect(answer)) _score++;
    });
  }

  void _nextQuestion() {
    if (_qIndex + 1 >= _questions.length) {
      _finishQuiz();
    } else {
      setState(() {
        _qIndex++;
        _selected = null;
        _answered = false;
      });
    }
  }

  Future<void> _finishQuiz() async {
    final total = _questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;
    final stars = pct >= 95 ? 3 : pct >= 80 ? 2 : pct >= 60 ? 1 : 0;
    setState(() {
      _earnedStars = stars;
      _phase = _Phase.result;
    });

    // Persister via completeItem sur le premier item de la lettre
    // masteryLevel 1/2/3 correspond aux étoiles (0 étoiles = pas de validation)
    if (stars > 0 && stars >= widget.existingStars) {
      final firstItem = widget.unit.items.isNotEmpty ? widget.unit.items.first : null;
      if (firstItem != null) {
        setState(() => _saving = true);
        try {
          await ref.read(curriculumApiProvider).completeItem(
            firstItem.id,
            enrollmentId: widget.enrollmentId,
            masteryLevel: stars,
          );
          ref.invalidate(enrollmentProgressProvider(widget.enrollmentId));
        } catch (_) {}
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  void _retryQuiz() {
    setState(() {
      _questions = _buildQuestions();
      _qIndex = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _phase = _Phase.quiz;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final glyph = widget.unit.titleAr;
    final letterName = glyphToName[glyph] ?? widget.unit.titleFr ?? glyph;
    final pronunciation = letterPronunciations[glyph] ??
        letterPronunciations[letterName];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              glyph,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 10),
            Text(
              letterName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (widget.unit.audioUrl != null)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop_circle_outlined : Icons.volume_up,
                color: _isPlaying ? Colors.amber : Colors.white,
              ),
              onPressed: _playAudio,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _phase == _Phase.discovery
            ? _buildDiscovery(context, glyph, letterName, pronunciation)
            : _phase == _Phase.quiz
                ? _buildQuizPhase(context)
                : _buildResult(context, letterName),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 1 — DÉCOUVERTE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDiscovery(
    BuildContext context,
    String glyph,
    String letterName,
    LetterPronunciation? pronunciation,
  ) {
    final letterItems = widget.unit.items
        .where((i) => i.letterPosition != null)
        .toList();
    final familyIdx = glyphToFamilyIndex[glyph];
    final family = familyIdx != null ? letterFamilies[familyIdx] : null;
    final words = letterWordExamples[glyph] ?? [];
    final mnemonic = letterMnemonics[glyph];

    return SingleChildScrollView(
      key: const ValueKey('discovery'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero ───────────────────────────────────────────────────────
          _HeroCard(
            glyph: glyph,
            letterName: letterName,
            transliteration: widget.unit.items.isNotEmpty
                ? widget.unit.items.first.transliteration
                : null,
            audioUrl: widget.unit.audioUrl,
            isPlaying: _isPlaying,
            onPlay: _playAudio,
            existingStars: widget.existingStars,
          ),
          const SizedBox(height: 20),

          // ── 4 formes ──────────────────────────────────────────────────
          if (letterItems.isNotEmpty) ...[
            _SectionHeader(label: 'Les 4 formes'),
            const SizedBox(height: 10),
            _FourFormsGrid(items: letterItems, onPlayAudio: _playAudio),
            const SizedBox(height: 20),
          ],

          // ── Makhraj / Prononciation ────────────────────────────────────
          if (pronunciation != null) ...[
            _SectionHeader(label: 'Prononciation'),
            const SizedBox(height: 10),
            _PronunciationCard(pronunciation: pronunciation, glyph: glyph),
            const SizedBox(height: 20),
          ],

          // ── Comparaison audio (si paire confusable) ───────────────────
          if (pronunciation?.paireGlyph != null) ...[
            const SizedBox(height: 10),
            _AudioComparisonWidget(
              glyphA: glyph,
              glyphB: pronunciation!.paireGlyph!,
              nameA: letterName,
              nameB: glyphToName[pronunciation.paireGlyph!] ?? pronunciation.paireGlyph!,
              audioUrlA: widget.unit.audioUrl,
            ),
          ],

          // ── Famille ───────────────────────────────────────────────────
          if (family != null) ...[
            _SectionHeader(label: 'Famille de lettres'),
            const SizedBox(height: 10),
            _FamilyCard(family: family, currentGlyph: glyph),
            const SizedBox(height: 20),
          ],

          // ── Mots en contexte ──────────────────────────────────────────
          if (words.isNotEmpty) ...[
            _SectionHeader(label: 'Ce son dans des mots'),
            const SizedBox(height: 10),
            _WordsContextSection(words: words),
            const SizedBox(height: 20),
          ],

          // ── Mnémotechnique ────────────────────────────────────────────
          if (mnemonic != null) ...[
            _MnemonicCard(mnemonic: mnemonic),
            const SizedBox(height: 20),
          ],

          // ── Non-connectante ───────────────────────────────────────────
          if (nonConnectingLetters.contains(glyph)) ...[
            _InfoBadge(
              icon: Icons.link_off,
              text: 'Lettre non-connectante — ne se lie jamais à la lettre suivante.',
            ),
            const SizedBox(height: 20),
          ],

          // ── CTA ───────────────────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => setState(() {
                _phase = _Phase.quiz;
                _audio.stop();
                _isPlaying = false;
              }),
              icon: const Icon(Icons.quiz_outlined, color: Colors.white),
              label: Text(
                widget.existingStars > 0
                    ? 'Améliorer mon score — Faire le quiz'
                    : 'Je connais cette lettre — Faire le quiz',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 2 — QUIZ
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuizPhase(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: Text('Aucune question disponible.'));
    }
    final q = _questions[_qIndex];
    final total = _questions.length;

    return Column(
      key: const ValueKey('quiz'),
      children: [
        // ── Barre de progression ─────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Question ${_qIndex + 1} / $total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Show revision indicator on review questions
                      if (_questions[_qIndex].questionFr.startsWith('🔄')) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔄',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_score / $total',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_qIndex + 1) / total,
                  minHeight: 6,
                  backgroundColor: AppColors.heatmapEmpty,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        // ── Question ─────────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: SingleChildScrollView(
              key: ValueKey(_qIndex),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Révision badge + label question
                  if (q.questionFr.startsWith('🔄')) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 12, color: Colors.deepPurple.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Révision des lettres précédentes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    // Strip the "🔄 Révision — " prefix for cleaner display
                    q.questionFr.startsWith('🔄')
                        ? q.questionFr.replaceFirst(RegExp(r'^🔄 Révision — '), '')
                        : q.questionFr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Affichage selon le type
                  if (q.type == _QType.soundToName)
                    _AudioQuestion(
                      audioUrl: q.itemAudioUrl!,
                      onPlay: () => _playAudio(overrideUrl: q.itemAudioUrl),
                      isPlaying: _isPlaying,
                    )
                  else if (q.displayGlyph != null)
                    _GlyphDisplay(glyph: q.displayGlyph!),

                  const SizedBox(height: 24),

                  // Choix
                  ...q.choices.map((choice) => _AnswerTile(
                        label: choice,
                        isGlyph: q.isGlyphChoice,
                        state: !_answered
                            ? _TileState.idle
                            : q.isCorrect(choice)
                                ? _TileState.correct
                                : choice == _selected
                                    ? _TileState.wrong
                                    : _TileState.idle,
                        onTap: () => _onSelectAnswer(choice),
                      )),

                  // Feedback + bouton Suivant
                  if (_answered) ...[
                    const SizedBox(height: 12),
                    _FeedbackBanner(
                      correct: _selected != null && q.isCorrect(_selected!),
                      correctAnswer: q.correctAnswer,
                      allCorrectAnswers: q.allCorrectAnswers,
                      isGlyph: q.isGlyphChoice,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _nextQuestion,
                        child: Text(
                          _qIndex + 1 >= total
                              ? 'Voir les résultats'
                              : 'Question suivante →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 3 — RÉSULTAT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResult(BuildContext context, String letterName) {
    final total = _questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;
    final passed = _earnedStars > 0;
    final improved = _earnedStars > widget.existingStars;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Score ──────────────────────────────────────────────────────
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: (passed ? AppColors.success : AppColors.danger)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: (passed ? AppColors.success : AppColors.danger)
                    .withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: passed ? AppColors.success : AppColors.danger,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            passed ? (improved ? '🎉 Nouveau record !' : '✅ Lettre validée !') : '⚠️ Pas encore !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: passed ? AppColors.success : AppColors.danger,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$_score bonne${_score > 1 ? 's' : ''} réponse${_score > 1 ? 's' : ''} sur $total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // ── Étoiles ────────────────────────────────────────────────────
          _StarRow(
            stars: _earnedStars,
            previous: widget.existingStars,
            improved: improved,
          ),
          const SizedBox(height: 8),
          Text(
            _starLabel(pct),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 32),

          // ── XP badge ───────────────────────────────────────────────────
          if (passed && (_saving || improved))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    _saving
                        ? 'Sauvegarde...'
                        : '+${_xpForStars(_earnedStars)} XP gagnés',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // ── Actions ────────────────────────────────────────────────────
          if (!passed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _phase = _Phase.discovery),
                  icon: Icon(Icons.arrow_back, color: AppColors.primary),
                  label: Text('Réviser la lettre',
                      style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _retryQuiz,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Réessayer le quiz',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_earnedStars < 3) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _retryQuiz,
                    icon: Icon(Icons.star_outline, color: AppColors.accent),
                    label: Text(
                      'Viser ${_earnedStars + 1} étoile${_earnedStars + 1 > 1 ? 's' : ''} →',
                      style: TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_earnedStars),
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                  label: const Text('Retour aux lettres',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (_earnedStars == 3) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => LetterSpeedRoundScreen(
                              glyphsToReview: [widget.unit.titleAr],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt, color: Colors.deepPurple),
                      label: const Text(
                        '⚡ Mode Vitesse',
                        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _starLabel(int pct) {
    if (pct >= 95) return 'Maîtrise parfaite ⭐⭐⭐';
    if (pct >= 80) return 'Très bonne maîtrise ⭐⭐';
    if (pct >= 60) return 'En bonne voie ⭐';
    return 'Continuez vos efforts — réessayez !';
  }

  int _xpForStars(int stars) => stars == 3 ? 25 : stars == 2 ? 20 : 15;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz data model
// ─────────────────────────────────────────────────────────────────────────────

enum _QType { glyphToName, nameToGlyph, positionRecognition, familyRecognition, soundToName }

class _QuizQuestion {
  final _QType type;
  final String questionFr;
  final String? displayGlyph;
  final String correctAnswer;
  /// All valid answers (includes correctAnswer + any equivalent positions for
  /// letters whose form is identical across multiple positions).
  final List<String> allCorrectAnswers;
  final List<String> choices;
  final bool isGlyphChoice;
  final String? itemAudioUrl;

  _QuizQuestion({
    required this.type,
    required this.questionFr,
    required this.displayGlyph,
    required this.correctAnswer,
    required this.choices,
    List<String>? extraCorrectAnswers,
    this.isGlyphChoice = false,
    this.itemAudioUrl,
  }) : allCorrectAnswers = [correctAnswer, ...?extraCorrectAnswers];

  bool isCorrect(String answer) => allCorrectAnswers.contains(answer);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String glyph;
  final String letterName;
  final String? transliteration;
  final String? audioUrl;
  final bool isPlaying;
  final VoidCallback onPlay;
  final int existingStars;

  const _HeroCard({
    required this.glyph,
    required this.letterName,
    required this.transliteration,
    required this.audioUrl,
    required this.isPlaying,
    required this.onPlay,
    required this.existingStars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          // Étoiles si déjà validée
          if (existingStars > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < existingStars ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Glyph géant
          Text(
            glyph,
            style: TextStyle(
              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
              fontSize: 88,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.1,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),

          // Translittération
          if (transliteration != null)
            Text(
              '[$transliteration]',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.accent,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 14),

          // Bouton audio
          if (audioUrl != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPlaying ? AppColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              onPressed: onPlay,
              icon: Icon(
                isPlaying ? Icons.stop : Icons.volume_up,
                size: 20,
              ),
              label: Text(
                isPlaying ? 'Arrêter' : 'Écouter la prononciation',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Grille 4 formes ──────────────────────────────────────────────────────────

class _FourFormsGrid extends StatelessWidget {
  final List<CurriculumItem> items;
  final Future<void> Function({String? overrideUrl}) onPlayAudio;

  const _FourFormsGrid({required this.items, required this.onPlayAudio});

  static String _positionLabel(String? pos) {
    switch (pos) {
      case 'isolated': return 'Isolée';
      case 'initial':  return 'Initiale';
      case 'medial':   return 'Médiane';
      case 'final':    return 'Finale';
      default: return pos ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enforce canonical order
    const order = ['isolated', 'initial', 'medial', 'final'];
    final sorted = [...items]..sort((a, b) =>
        order.indexOf(a.letterPosition ?? '').compareTo(
            order.indexOf(b.letterPosition ?? '')));

    // Merge items that share the exact same visual glyph (titleAr).
    // e.g. ا: isolated = 'ا', final = 'ا' → one card labeled "Isolée / Finale"
    final List<({String glyph, List<String> positions, String? audioUrl})> cards = [];
    for (final item in sorted) {
      final existing = cards.indexWhere((c) => c.glyph == item.titleAr);
      if (existing >= 0) {
        final c = cards[existing];
        final label = _positionLabel(item.letterPosition);
        if (!c.positions.contains(label)) {
          cards[existing] = (
            glyph: c.glyph,
            positions: [...c.positions, label],
            audioUrl: c.audioUrl ?? item.audioUrl,
          );
        }
      } else {
        cards.add((
          glyph: item.titleAr,
          positions: [_positionLabel(item.letterPosition)],
          audioUrl: item.audioUrl,
        ));
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: cards.map((card) {
        final isMerged = card.positions.length > 1;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMerged
                  ? AppColors.accent.withOpacity(0.4)
                  : AppColors.divider,
              width: isMerged ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glyph
              Text(
                card.glyph,
                style: TextStyle(
                  fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                  fontSize: 36,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              // Position label(s) — merged shows e.g. "Isolée / Finale"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  card.positions.join(' / '),
                  style: TextStyle(
                    fontSize: isMerged ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Note if merged
              if (isMerged) ...[
                const SizedBox(height: 3),
                Text(
                  'Même forme',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Prononciation ─────────────────────────────────────────────────────────────

class _PronunciationCard extends StatelessWidget {
  final LetterPronunciation pronunciation;
  final String glyph;
  const _PronunciationCard({required this.pronunciation, required this.glyph});

  Color _difficultyColor(PronunciationDifficulty d) {
    switch (d) {
      case PronunciationDifficulty.easy:   return AppColors.success;
      case PronunciationDifficulty.medium: return AppColors.warning;
      case PronunciationDifficulty.hard:   return Colors.orange;
      case PronunciationDifficulty.expert: return AppColors.danger;
    }
  }

  String _difficultyLabel(PronunciationDifficulty d) {
    switch (d) {
      case PronunciationDifficulty.easy:   return 'Facile';
      case PronunciationDifficulty.medium: return 'Moyen';
      case PronunciationDifficulty.hard:   return 'Difficile';
      case PronunciationDifficulty.expert: return 'Expert';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(pronunciation.difficulty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : catégorie + difficulté
          Row(
            children: [
              Expanded(
                child: Text(
                  pronunciation.categoryFr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  _difficultyLabel(pronunciation.difficulty),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Équivalent (en gras)
          Row(
            children: [
              const Text('≈ ', style: TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Text(
                  pronunciation.equivalentFr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            pronunciation.descriptionFr,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          ),

          // Schéma d'articulation (seulement pour les sons sans équivalent français)
          Builder(builder: (_) {
            final zones = zonesForGlyph(glyph);
            if (zones.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Text(
                  'Position dans la bouche',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                MouthDiagramWidget(zones: zones, showLegend: true),
              ],
            );
          }),

          // Astuce
          if (pronunciation.astuceFr != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      pronunciation.astuceFr!,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Paire minimale
          if (pronunciation.paireFr != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  pronunciation.paireFr!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Famille ───────────────────────────────────────────────────────────────────

class _FamilyCard extends StatefulWidget {
  final LetterFamily family;
  final String currentGlyph;
  const _FamilyCard({required this.family, required this.currentGlyph});

  @override
  State<_FamilyCard> createState() => _FamilyCardState();
}

class _FamilyCardState extends State<_FamilyCard> {
  final _audio = AudioPlayer();
  String? _playingGlyph;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _playGlyph(String glyph) async {
    await _audio.stop();
    setState(() => _playingGlyph = glyph);
    try {
      final filename = glyphToAudioFilename[glyph] ?? glyphToName[glyph]?.toLowerCase().replaceAll(' ', '_') ?? glyph;
      await _audio.play(UrlSource('${ApiConstants.baseUrl}/static/audio/letters/$filename.mp3'));
      _audio.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingGlyph = null);
      });
    } catch (_) {
      if (mounted) setState(() => _playingGlyph = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.family.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.family.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.family.descriptionFr,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.family.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.touch_app, size: 12, color: widget.family.color.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                'Appuyez pour écouter',
                style: TextStyle(fontSize: 10, color: widget.family.color.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.family.letters.map((g) {
              final isCurrent = g == widget.currentGlyph;
              final isPlaying = _playingGlyph == g;
              return GestureDetector(
                onTap: () => _playGlyph(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? widget.family.color.withOpacity(0.3)
                        : isCurrent
                            ? widget.family.color.withOpacity(0.2)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent || isPlaying ? widget.family.color : Colors.grey[200]!,
                      width: isCurrent || isPlaying ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        g,
                        style: TextStyle(
                          fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                          fontSize: 28,
                          color: isCurrent ? widget.family.color : AppColors.primary,
                          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.normal,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      if (isPlaying)
                        Icon(Icons.volume_up, size: 12, color: widget.family.color),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Helpers UI ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quiz : affichage glyph ────────────────────────────────────────────────────

class _GlyphDisplay extends StatelessWidget {
  final String glyph;
  const _GlyphDisplay({required this.glyph});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          glyph,
          style: TextStyle(
            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

// ── Quiz : question audio ─────────────────────────────────────────────────────

class _AudioQuestion extends StatelessWidget {
  final String audioUrl;
  final VoidCallback onPlay;
  final bool isPlaying;
  const _AudioQuestion({
    required this.audioUrl,
    required this.onPlay,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.accent.withOpacity(0.12)
              : AppColors.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPlaying ? AppColors.accent : AppColors.primary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.stop_circle_outlined : Icons.volume_up,
              size: 40,
              color: isPlaying ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              isPlaying ? 'Arrêter' : 'Écouter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPlaying ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz : tuile réponse ──────────────────────────────────────────────────────

enum _TileState { idle, correct, wrong }

class _AnswerTile extends StatelessWidget {
  final String label;
  final bool isGlyph;
  final _TileState state;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.label,
    required this.isGlyph,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;
    switch (state) {
      case _TileState.correct:
        bg = AppColors.success.withOpacity(0.10);
        border = AppColors.success;
        text = AppColors.success;
      case _TileState.wrong:
        bg = AppColors.danger.withOpacity(0.10);
        border = AppColors.danger;
        text = AppColors.danger;
      case _TileState.idle:
        bg = Colors.white;
        border = AppColors.divider;
        text = AppColors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state == _TileState.correct)
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              if (state == _TileState.wrong)
                const Icon(Icons.cancel, color: AppColors.danger, size: 18),
              if (state == _TileState.idle)
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Expanded(
                child: isGlyph
                    ? Text(
                        label,
                        style: TextStyle(
                          fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                          fontSize: 28,
                          color: text,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 26),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quiz : feedback ───────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  final List<String> allCorrectAnswers;
  final bool isGlyph;
  const _FeedbackBanner({
    required this.correct,
    required this.correctAnswer,
    required this.allCorrectAnswers,
    required this.isGlyph,
  });

  @override
  Widget build(BuildContext context) {
    // For multi-valid-position answers: "Isolée ou Finale"
    final answerDisplay = allCorrectAnswers.length > 1
        ? allCorrectAnswers.join(' ou ')
        : correctAnswer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (correct ? AppColors.success : AppColors.danger).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (correct ? AppColors.success : AppColors.danger).withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Text(
            correct ? '✅' : '❌',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: correct
                ? Text(
                    'Correct !',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'La bonne réponse était '),
                        TextSpan(
                          text: answerDisplay,
                          style: TextStyle(
                            fontFamily: isGlyph
                                ? GoogleFonts.scheherazadeNew().fontFamily
                                : null,
                            fontSize: isGlyph ? 20 : 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Résultat : étoiles ────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int stars;
  final int previous;
  final bool improved;
  const _StarRow({
    required this.stars,
    required this.previous,
    required this.improved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < stars;
        final wasAlready = i < previous;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled
                ? (improved && !wasAlready ? AppColors.accent : Colors.amber)
                : Colors.grey[300],
            size: 40,
          ),
        );
      }),
    );
  }
}

// ── Mots en contexte ────────────────────────────────────────────────────────

class _WordsContextSection extends StatelessWidget {
  final List<WordExample> words;
  const _WordsContextSection({required this.words});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: words.map((w) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                // Arabic word with highlighted letter
                RichText(
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      fontSize: 22,
                      height: 1.6,
                    ),
                    children: [
                      if (w.before.isNotEmpty)
                        TextSpan(text: w.before, style: const TextStyle(color: Colors.black87)),
                      TextSpan(
                        text: w.highlight,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (w.after.isNotEmpty)
                        TextSpan(text: w.after, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  w.translitFr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  w.meaningFr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mnémotechnique ────────────────────────────────────────────────────────────

class _MnemonicCard extends StatelessWidget {
  final LetterMnemonic mnemonic;
  const _MnemonicCard({required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠 ', style: TextStyle(fontSize: 16)),
              const Text(
                'Astuce mémoire',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mnemonic.hookFr,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          if (mnemonic.imageFr != null) ...[
            const SizedBox(height: 6),
            Text(
              '💭 ${mnemonic.imageFr}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.deepPurple.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Comparaison audio paires confusables ──────────────────────────────────────

class _AudioComparisonWidget extends StatefulWidget {
  final String glyphA;
  final String glyphB;
  final String nameA;
  final String nameB;
  final String? audioUrlA;

  const _AudioComparisonWidget({
    required this.glyphA,
    required this.glyphB,
    required this.nameA,
    required this.nameB,
    this.audioUrlA,
  });

  @override
  State<_AudioComparisonWidget> createState() => _AudioComparisonWidgetState();
}

class _AudioComparisonWidgetState extends State<_AudioComparisonWidget> {
  final _audio = AudioPlayer();
  String? _playing; // 'A' or 'B'

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _play(String which) async {
    await _audio.stop();
    setState(() => _playing = which);
    try {
      final String url;
      if (which == 'A' && widget.audioUrlA != null) {
        // Use the reliable unit audioUrl for the current letter
        url = widget.audioUrlA!;
      } else {
        // Construct URL from glyph → exact filename map
        final glyph = which == 'A' ? widget.glyphA : widget.glyphB;
        final filename = glyphToAudioFilename[glyph] ?? glyphToName[glyph]?.toLowerCase().replaceAll(' ', '_') ?? glyph;
        url = '${ApiConstants.baseUrl}/static/audio/letters/$filename.mp3';
      }
      await _audio.play(UrlSource(url));
      _audio.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = null);
      });
    } catch (_) {
      if (mounted) setState(() => _playing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👂 Distinguer ces deux sons',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildPlayBtn('A', widget.glyphA, widget.nameA)),
              const SizedBox(width: 8),
              const Text('↔', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(child: _buildPlayBtn('B', widget.glyphB, widget.nameB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayBtn(String which, String glyph, String name) {
    final isPlaying = _playing == which;
    return GestureDetector(
      onTap: () => _play(which),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isPlaying ? Colors.orange.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPlaying ? Colors.orange : AppColors.divider,
            width: isPlaying ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

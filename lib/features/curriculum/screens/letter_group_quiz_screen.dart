import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../data/arabic_alphabet_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LetterGroupQuizScreen — Quiz récapitulatif de groupe
//
// Proposé à la fin de chaque groupe de lettres.
// Questions variées : glyph → nom, nom → glyph, audio → nom.
// Score + badge de réussite.
// ─────────────────────────────────────────────────────────────────────────────

enum _QType { glyphToName, nameToGlyph, audioToName }

class _QuizItem {
  final _QType type;
  final String glyph;
  final String correct;
  final List<String> choices; // always 4

  const _QuizItem({
    required this.type,
    required this.glyph,
    required this.correct,
    required this.choices,
  });
}

class LetterGroupQuizScreen extends StatefulWidget {
  final int groupIndex;
  final List<String> glyphs; // all letters of the group

  const LetterGroupQuizScreen({
    super.key,
    required this.groupIndex,
    required this.glyphs,
  });

  @override
  State<LetterGroupQuizScreen> createState() => _LetterGroupQuizScreenState();
}

class _LetterGroupQuizScreenState extends State<LetterGroupQuizScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final _audio = AudioPlayer();

  late List<_QuizItem> _questions;
  int _index = 0;
  int _score = 0;
  bool _answered = false;
  String? _selected;
  bool _finished = false;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _questions = _buildQuestions();
    _onNewQuestion();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  List<_QuizItem> _buildQuestions() {
    final items = <_QuizItem>[];
    for (final glyph in widget.glyphs) {
      final name = glyphToName[glyph] ?? glyph;

      // Q1: glyph → nom
      items.add(_QuizItem(
        type: _QType.glyphToName,
        glyph: glyph,
        correct: name,
        choices: _buildNameChoices(name),
      ));

      // Q2: nom → glyph
      items.add(_QuizItem(
        type: _QType.nameToGlyph,
        glyph: glyph,
        correct: glyph,
        choices: _buildGlyphChoices(glyph),
      ));

      // Q3: audio → nom
      items.add(_QuizItem(
        type: _QType.audioToName,
        glyph: glyph,
        correct: name,
        choices: _buildNameChoices(name),
      ));
    }
    items.shuffle(_rng);
    // Limit to a reasonable length (max 3 questions per letter, capped at 24)
    return items.take(widget.glyphs.length * 3).toList();
  }

  List<String> _buildNameChoices(String correct) {
    final distractors = allLetterNames
        .where((n) => n != correct)
        .toList()
      ..shuffle(_rng);
    return ([correct, ...distractors.take(3)]..shuffle(_rng));
  }

  List<String> _buildGlyphChoices(String correct) {
    final allGlyphs = glyphToName.keys.toList();
    final distractors = allGlyphs.where((g) => g != correct).toList()..shuffle(_rng);
    return ([correct, ...distractors.take(3)]..shuffle(_rng));
  }

  void _onNewQuestion() {
    _fadeCtrl.forward(from: 0);
    final q = _questions[_index];
    if (q.type == _QType.audioToName) {
      _playAudio(q.glyph);
    }
  }

  Future<void> _playAudio(String glyph) async {
    final name = glyphToName[glyph]?.toLowerCase().replaceAll(' ', '_') ?? glyph;
    try {
      await _audio.play(
        UrlSource('${ApiConstants.baseUrl}/static/audio/letters/$name.mp3'),
      );
    } catch (_) {}
  }

  void _onAnswer(String choice) {
    if (_answered) return;
    final correct = _questions[_index].correct;
    final isRight = choice == correct;
    setState(() {
      _answered = true;
      _selected = choice;
      if (isRight) _score++;
    });
    Future.delayed(const Duration(milliseconds: 1000), _next);
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _selected = null;
    });
    _onNewQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult(context);
    final q = _questions[_index];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Quiz — ${letterGroupNames[widget.groupIndex]}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Text(
              '${_index + 1}/${_questions.length}',
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Score chip
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ScoreChip(score: _score, total: _index),
                      ),
                      const SizedBox(height: 20),

                      // Question card
                      Expanded(child: _buildQuestionCard(q)),

                      const SizedBox(height: 24),

                      // Answer choices
                      _buildChoices(q),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(_QuizItem q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question label
          Text(
            _questionLabel(q.type),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Question content
          if (q.type == _QType.glyphToName) ...[
            Text(
              q.glyph,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 100,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _playAudio(q.glyph),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, size: 14, color: Colors.white38),
                  SizedBox(width: 4),
                  Text('écouter', style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
          ] else if (q.type == _QType.nameToGlyph) ...[
            Text(
              glyphToName[q.glyph] ?? q.glyph,
              style: const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ] else ...[
            // Audio-first question
            GestureDetector(
              onTap: () => _playAudio(q.glyph),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.volume_up_rounded, size: 36, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Appuyez pour réécouter',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoices(_QuizItem q) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 10),
                  Expanded(child: _buildChoiceBtn(q, q.choices[row * 2 + col])),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceBtn(_QuizItem q, String choice) {
    final isCorrect = choice == q.correct;
    final isSelected = choice == _selected;

    Color bg = Colors.white.withOpacity(0.07);
    Color border = Colors.white24;
    if (_answered) {
      if (isCorrect) {
        bg = AppColors.success.withOpacity(0.2);
        border = AppColors.success;
      } else if (isSelected) {
        bg = AppColors.danger.withOpacity(0.2);
        border = AppColors.danger;
      }
    }

    // For nameToGlyph questions, choices are glyphs — show big Arabic
    final isGlyphChoice = q.type == _QType.nameToGlyph;

    return GestureDetector(
      onTap: () => _onAnswer(choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          choice,
          textAlign: TextAlign.center,
          textDirection: isGlyphChoice ? TextDirection.rtl : null,
          style: TextStyle(
            color: Colors.white,
            fontSize: isGlyphChoice ? 30 : 14,
            fontWeight: FontWeight.w700,
            fontFamily: isGlyphChoice ? GoogleFonts.scheherazadeNew().fontFamily : null,
          ),
        ),
      ),
    );
  }

  String _questionLabel(_QType type) {
    switch (type) {
      case _QType.glyphToName:
        return '🔤 Comment s\'appelle cette lettre ?';
      case _QType.nameToGlyph:
        return '🔍 Quelle est la lettre « ${glyphToName[_questions[_index].glyph] ?? ''} » ?';
      case _QType.audioToName:
        return '🎧 Écoute et identifie la lettre';
    }
  }

  Widget _buildResult(BuildContext context) {
    final total = _questions.length;
    final pct = ((_score / total) * 100).round();
    final groupName = letterGroupNames[widget.groupIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medal emoji
                Text(
                  pct >= 80 ? '🏆' : pct >= 60 ? '⭐' : '💪',
                  style: const TextStyle(fontSize: 72),
                ),
                const SizedBox(height: 16),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_score bonnes réponses / $total',
                  style: const TextStyle(fontSize: 15, color: Colors.white60),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _resultMessage(pct),
                  style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Recommencer',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour au programme',
                      style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restart() {
    setState(() {
      _questions = _buildQuestions();
      _index = 0;
      _score = 0;
      _answered = false;
      _selected = null;
      _finished = false;
    });
    _onNewQuestion();
  }

  String _resultMessage(int pct) {
    if (pct >= 80) return 'Excellent ! Tu maîtrises bien ce groupe de lettres. Continue sur ta lancée !';
    if (pct >= 60) return 'Bon travail ! Encore un peu de pratique et tu vas maîtriser ce groupe.';
    return 'Continue à pratiquer ces lettres — la répétition est la clé de l\'apprentissage !';
  }
}

class _ScoreChip extends StatelessWidget {
  final int score;
  final int total;
  const _ScoreChip({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Text(
        '✅ $score / $total',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

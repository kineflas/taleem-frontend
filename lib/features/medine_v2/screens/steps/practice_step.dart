import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/lesson_models_v2.dart';

/// Step 4: Interactive exercises (REORDER, FILL_BLANK, TRANSLATE, CLASSIFY).
class PracticeStep extends StatefulWidget {
  final LessonContentV2 lesson;
  final void Function({int xp}) onComplete;

  const PracticeStep({super.key, required this.lesson, required this.onComplete});

  @override
  State<PracticeStep> createState() => _PracticeStepState();
}

class _PracticeStepState extends State<PracticeStep> {
  int _currentExercise = 0;
  int _totalXp = 0;
  int _correctCount = 0;

  List<ExerciseV2> get exercises => widget.lesson.exercises;
  bool get hasExercises => exercises.isNotEmpty;

  void _onExerciseComplete({bool correct = true, int xp = 5}) {
    setState(() {
      if (correct) _correctCount++;
      _totalXp += xp;
      if (_currentExercise < exercises.length - 1) {
        _currentExercise++;
      } else {
        widget.onComplete(xp: _totalXp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!hasExercises) {
      // No parsed exercises — show a placeholder and allow skip
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✍️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Les exercices interactifs pour cette leçon arrivent bientôt !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => widget.onComplete(xp: 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuer vers le quiz'),
              ),
            ],
          ),
        ),
      );
    }

    final exercise = exercises[_currentExercise];

    return Column(
      children: [
        // Stepper
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: List.generate(exercises.length, (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _currentExercise
                      ? const Color(0xFF2D6A4F)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Exercice ${_currentExercise + 1} / ${exercises.length}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildExercise(exercise),
          ),
        ),
      ],
    );
  }

  Widget _buildExercise(ExerciseV2 exercise) {
    switch (exercise.type) {
      case 'REORDER':
        return _ReorderExercise(
          key: ValueKey('reorder_$_currentExercise'),
          exercise: exercise,
          onComplete: _onExerciseComplete,
        );
      case 'FILL_BLANK':
        return _FillBlankExercise(
          key: ValueKey('fill_$_currentExercise'),
          exercise: exercise,
          onComplete: _onExerciseComplete,
        );
      case 'TRANSLATE':
        return _TranslateExercise(
          key: ValueKey('translate_$_currentExercise'),
          exercise: exercise,
          onComplete: _onExerciseComplete,
        );
      case 'CLASSIFY':
        return _ClassifyExercise(
          key: ValueKey('classify_$_currentExercise'),
          exercise: exercise,
          onComplete: _onExerciseComplete,
        );
      default:
        return Center(child: Text('Type inconnu: ${exercise.type}'));
    }
  }
}

// ── REORDER Exercise ─────────────────────────────────────────────────────────

class _ReorderExercise extends StatefulWidget {
  final ExerciseV2 exercise;
  final void Function({bool correct, int xp}) onComplete;

  const _ReorderExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<_ReorderExercise> createState() => _ReorderExerciseState();
}

class _ReorderExerciseState extends State<_ReorderExercise> {
  late List<String> _shuffled;
  final List<String> _placed = [];
  bool? _isCorrect;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _shuffled = List.from(widget.exercise.words)..shuffle(Random());
    // Ensure shuffled is different from answer
    if (_shuffled.join() == widget.exercise.answerWords.join()) {
      _shuffled = _shuffled.reversed.toList();
    }
  }

  void _check() {
    final correct = _placed.join(' ') == widget.exercise.answerWords.join(' ');
    setState(() {
      _isCorrect = correct;
      _attempts++;
    });

    if (correct) {
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onComplete(correct: true, xp: _attempts <= 1 ? 13 : 5);
      });
    } else if (_attempts >= 3) {
      // Show answer after 3 attempts
      setState(() {
        _placed.clear();
        _placed.addAll(widget.exercise.answerWords);
        _shuffled.clear();
        _isCorrect = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        widget.onComplete(correct: false, xp: 2);
      });
    } else {
      // Reset after error
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _shuffled.addAll(_placed);
          _placed.clear();
          _isCorrect = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remettez dans l\'ordre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          if (widget.exercise.promptFr != null)
            Text(widget.exercise.promptFr!, style: const TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 24),

          // Target zone
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isCorrect == null
                  ? Colors.grey.shade100
                  : _isCorrect!
                      ? const Color(0xFFD8F3DC)
                      : const Color(0xFFFDEDED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect == null
                    ? Colors.grey.shade300
                    : _isCorrect!
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFC0392B),
                style: _placed.isEmpty ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._placed.map((w) => _WordChip(
                    word: w,
                    onTap: () {
                      if (_isCorrect != null) return;
                      setState(() {
                        _placed.remove(w);
                        _shuffled.add(w);
                      });
                    },
                    isPlaced: true,
                  )),
                  if (_placed.isEmpty)
                    Text(
                      'Glissez les mots ici...',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Source chips
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _shuffled.map((w) => _WordChip(
                word: w,
                onTap: () {
                  if (_isCorrect != null) return;
                  setState(() {
                    _shuffled.remove(w);
                    _placed.add(w);
                  });
                },
                isPlaced: false,
              )).toList(),
            ),
          ),

          const Spacer(),

          // Check button
          if (_shuffled.isEmpty && _placed.isNotEmpty && _isCorrect == null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Vérifier', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final bool isPlaced;

  const _WordChip({required this.word, required this.onTap, required this.isPlaced});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaced ? const Color(0xFF2D6A4F).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          word,
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'Amiri',
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

// ── FILL_BLANK Exercise ─────────────────────────────────────────────────────

/// Extract Arabic option words from prompt like "Complétez avec هَذَا ou هَذِهِ :"
List<String> _extractOptionsFromPrompt(String? prompt) {
  if (prompt == null || prompt.isEmpty) return [];

  // Try to find the part after "avec" and before ":"
  final avecIdx = prompt.toLowerCase().indexOf('avec');
  if (avecIdx < 0) return [];

  var after = prompt.substring(avecIdx + 4).trim();
  // Remove "et ..." suffix (e.g. "et changez la voyelle...")
  final etIdx = after.indexOf(' et ');
  if (etIdx > 0) after = after.substring(0, etIdx);
  after = after.replaceAll(RegExp(r'\s*:\s*$'), '').trim();

  // Split by " ou ", "، ", ", ", "/"
  final parts = after.split(RegExp(r'\s+ou\s+|،\s*|,\s*|/'));

  // Filter: only keep tokens that contain Arabic characters
  final arabicRe = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');
  final options = <String>[];
  for (final p in parts) {
    final trimmed = p.trim();
    if (trimmed.isNotEmpty && arabicRe.hasMatch(trimmed)) {
      // Extract just the Arabic portion if mixed with French
      final arabicOnly = trimmed
          .split(' ')
          .where((w) => arabicRe.hasMatch(w))
          .join(' ')
          .trim();
      if (arabicOnly.isNotEmpty) options.add(arabicOnly);
    }
  }
  return options;
}

/// Clean sentence for display: remove markdown bold markers and extra backslashes
String _cleanSentence(String raw) {
  return raw
      .replaceAll('**', '')
      .replaceAll(r'\_\_\_', '______')
      .replaceAll(r'\\_', '_')
      .replaceAll('______', ' ______ ')
      .trim();
}

class _FillBlankExercise extends StatefulWidget {
  final ExerciseV2 exercise;
  final void Function({bool correct, int xp}) onComplete;

  const _FillBlankExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<_FillBlankExercise> createState() => _FillBlankExerciseState();
}

class _FillBlankExerciseState extends State<_FillBlankExercise> {
  int _currentItem = 0;
  int _score = 0;
  String? _selectedOption;
  bool? _isCorrect;          // null = not checked, true/false = feedback shown
  late final List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = _extractOptionsFromPrompt(widget.exercise.promptFr);
  }

  void _selectOption(String option) {
    if (_isCorrect != null) return; // Already checked
    setState(() => _selectedOption = option);
  }

  void _check() {
    if (_selectedOption == null) return;
    final item = widget.exercise.items[_currentItem];
    final answer = (item.answer ?? '').trim();

    if (answer.isEmpty) {
      // No known answer → self-check, always advance
      _advanceAfterDelay(true);
      return;
    }

    final correct = _selectedOption!.trim() == answer;
    setState(() {
      _isCorrect = correct;
      if (correct) _score++;
    });

    // Auto-advance after feedback delay
    Future.delayed(Duration(milliseconds: correct ? 800 : 1800), () {
      if (!mounted) return;
      _advance();
    });
  }

  void _advanceAfterDelay(bool correct) {
    setState(() => _isCorrect = correct);
    if (correct) _score++;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _advance();
    });
  }

  void _advance() {
    setState(() {
      if (_currentItem < widget.exercise.items.length - 1) {
        _currentItem++;
        _selectedOption = null;
        _isCorrect = null;
      } else {
        widget.onComplete(
          correct: _score > widget.exercise.items.length / 2,
          xp: _score * 5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercise.items.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: () => widget.onComplete(xp: 0),
          child: const Text('Continuer'),
        ),
      );
    }

    final item = widget.exercise.items[_currentItem];
    final sentence = _cleanSentence(item.sentence ?? '');
    final correctAnswer = (item.answer ?? '').trim();
    final hasAnswer = correctAnswer.isNotEmpty;

    // Build display sentence: replace blank with selected option or correct answer
    String displaySentence = sentence;
    if (_isCorrect == false && hasAnswer) {
      // Show the correct answer after wrong selection
      displaySentence = sentence.replaceFirst(RegExp(r'_+'), correctAnswer);
    } else if (_selectedOption != null) {
      displaySentence = sentence.replaceFirst(RegExp(r'_+'), _selectedOption!);
    }

    // Determine card border color based on state
    Color cardBorderColor = Colors.grey.shade200;
    double cardBorderWidth = 1;
    if (_isCorrect == true) {
      cardBorderColor = const Color(0xFF2D6A4F);
      cardBorderWidth = 2;
    } else if (_isCorrect == false) {
      cardBorderColor = const Color(0xFFC0392B);
      cardBorderWidth = 2;
    } else if (_selectedOption != null) {
      cardBorderColor = const Color(0xFF2D6A4F).withOpacity(0.4);
      cardBorderWidth = 2;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.exercise.promptFr ?? 'Complétez',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentItem + 1} / ${widget.exercise.items.length}',
            style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Sentence card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isCorrect == true
                  ? const Color(0xFFD8F3DC)
                  : _isCorrect == false
                      ? const Color(0xFFFDEDED)
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor, width: cardBorderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                displaySentence,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Amiri',
                  color: Color(0xFF1A1A2E),
                  height: 1.8,
                ),
              ),
            ),
          ),

          // Feedback message
          if (_isCorrect == true)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Bonne réponse !',
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          if (_isCorrect == false)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Color(0xFFC0392B), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15, color: Color(0xFFC0392B)),
                        children: [
                          const TextSpan(
                            text: 'Incorrect. ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: 'La réponse est '),
                          TextSpan(
                            text: correctAnswer,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // "Choisissez" label
          if (_isCorrect == null)
            const Text(
              'Choisissez la bonne réponse :',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_isCorrect == null) const SizedBox(height: 14),

          // Option buttons
          if (_options.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _options.map((opt) {
                final isSelected = _selectedOption == opt;
                // After checking, highlight correct/wrong
                Color bgColor = Colors.white;
                Color borderColor = Colors.grey.shade300;
                double bw = 1.0;

                if (_isCorrect != null && hasAnswer) {
                  if (opt == correctAnswer) {
                    bgColor = const Color(0xFFD8F3DC);
                    borderColor = const Color(0xFF2D6A4F);
                    bw = 2;
                  } else if (isSelected && _isCorrect == false) {
                    bgColor = const Color(0xFFFDEDED);
                    borderColor = const Color(0xFFC0392B);
                    bw = 2;
                  }
                } else if (isSelected) {
                  bgColor = const Color(0xFF2D6A4F).withOpacity(0.12);
                  borderColor = const Color(0xFF2D6A4F);
                  bw = 2;
                }

                return GestureDetector(
                  onTap: () => _selectOption(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: bw),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 26,
                        fontFamily: 'Amiri',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Réfléchissez à la réponse, puis continuez.',
                style: TextStyle(color: Color(0xFF666666), fontStyle: FontStyle.italic),
              ),
            ),

          const Spacer(),

          // Verify / Next button
          if (_isCorrect == null)
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_selectedOption != null || _options.isEmpty) ? _check : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Vérifier',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── TRANSLATE Exercise ─────────────────────────────────────────────────────

class _TranslateExercise extends StatefulWidget {
  final ExerciseV2 exercise;
  final void Function({bool correct, int xp}) onComplete;

  const _TranslateExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<_TranslateExercise> createState() => _TranslateExerciseState();
}

class _TranslateExerciseState extends State<_TranslateExercise> {
  int _currentItem = 0;
  bool _revealed = false;
  bool? _selfEval; // null = not evaluated, true = got it, false = didn't
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() => _revealed = true);
  }

  void _selfCheck(bool gotIt) {
    setState(() => _selfEval = gotIt);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _advance();
    });
  }

  void _advance() {
    setState(() {
      if (_currentItem < widget.exercise.items.length - 1) {
        _currentItem++;
        _revealed = false;
        _selfEval = null;
        _textController.clear();
      } else {
        widget.onComplete(xp: 9);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercise.items.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: () => widget.onComplete(xp: 0),
          child: const Text('Continuer'),
        ),
      );
    }

    final item = widget.exercise.items[_currentItem];
    final hasAnswer = (item.answerAr ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Traduisez en arabe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                ),
              ),
              Text(
                '${_currentItem + 1} / ${widget.exercise.items.length}',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // French prompt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.promptFr ?? '',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Arabic text input
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selfEval == true
                    ? const Color(0xFF2D6A4F)
                    : _selfEval == false
                        ? const Color(0xFFC0392B)
                        : const Color(0xFF2D6A4F).withOpacity(0.3),
                width: _selfEval != null ? 2 : 1,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _textController,
                enabled: !_revealed,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  color: Color(0xFF1A1A2E),
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب هنا...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 20),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Revealed answer card
          if (_revealed && hasAnswer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF4A261).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Réponse attendue :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item.answerAr!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Amiri',
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Self-evaluation buttons (shown after reveal)
          if (_revealed && _selfEval == null) ...[
            const SizedBox(height: 16),
            const Text(
              'Avez-vous trouvé la bonne réponse ?',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _selfCheck(false),
                      icon: const Icon(Icons.close, color: Color(0xFFC0392B)),
                      label: const Text('Pas encore', style: TextStyle(color: Color(0xFFC0392B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC0392B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _selfCheck(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Correct !'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Feedback after self-eval
          if (_selfEval == true)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 22),
                  SizedBox(width: 8),
                  Text('Bravo !', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          if (_selfEval == false)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE76F51), size: 22),
                  SizedBox(width: 8),
                  Text('On continue, ça viendra !', style: TextStyle(color: Color(0xFFE76F51), fontWeight: FontWeight.w500, fontSize: 15)),
                ],
              ),
            ),

          const Spacer(),

          // Bottom button: "Voir la réponse" or "Suivant" (for no-answer items)
          if (!_revealed)
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _reveal,
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'Voir la réponse',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ),

          // If no answer available, show skip button instead of self-eval
          if (_revealed && !hasAnswer)
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _advance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentItem < widget.exercise.items.length - 1 ? 'Suivant' : 'Terminer',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── CLASSIFY Exercise ──────────────────────────────────────────────────────

class _ClassifyExercise extends StatefulWidget {
  final ExerciseV2 exercise;
  final void Function({bool correct, int xp}) onComplete;

  const _ClassifyExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<_ClassifyExercise> createState() => _ClassifyExerciseState();
}

class _ClassifyExerciseState extends State<_ClassifyExercise> {
  final Map<String, String> _classified = {};
  bool? _checked;

  List<ExerciseItemV2> get items => widget.exercise.items;
  List<String> get categories => widget.exercise.categories;

  void _classify(String word, String category) {
    setState(() => _classified[word] = category);
  }

  void _check() {
    int correct = 0;
    for (final item in items) {
      if (_classified[item.word] == item.category) correct++;
    }
    final score = correct / items.length;
    setState(() => _checked = score >= 0.6);

    Future.delayed(const Duration(seconds: 1), () {
      widget.onComplete(correct: score >= 0.6, xp: (score * 10).round());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.promptFr ?? 'Classez les mots',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),

          // Category headers
          Row(
            children: categories.map((cat) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Words to classify
          Expanded(
            child: ListView(
              children: items.map((item) {
                final word = item.word ?? '';
                final selected = _classified[word];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'Amiri',
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: selected == cat,
                          onSelected: _checked != null
                              ? null
                              : (v) {
                                  if (v) _classify(word, cat);
                                },
                          selectedColor: const Color(0xFFD8F3DC),
                        ),
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Check button
          if (_classified.length == items.length && _checked == null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Vérifier', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}

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

  void _answer(String selected) {
    final item = widget.exercise.items[_currentItem];
    final correct = selected == item.answer;
    if (correct) _score++;

    setState(() {
      if (_currentItem < widget.exercise.items.length - 1) {
        _currentItem++;
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.promptFr ?? 'Complétez',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentItem + 1} / ${widget.exercise.items.length}',
            style: const TextStyle(color: Color(0xFF999999)),
          ),
          const SizedBox(height: 24),

          // Sentence with blank
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                item.sentence ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  color: Color(0xFF1A1A2E),
                  height: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info text
          const Text(
            'Tapez sur la bonne réponse :',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),

          // Simple answer — just show continue since we don't have answer options parsed
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _answer(item.answer ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continuer', style: TextStyle(fontSize: 16)),
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
  bool _showHint = false;

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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Traduisez en arabe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 24),

          // French prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.promptFr ?? '',
              style: const TextStyle(fontSize: 18, color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(height: 16),

          if (_showHint && (item.answerAr ?? '').isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  item.answerAr!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Amiri',
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),

          const Spacer(),

          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showHint = !_showHint),
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(_showHint ? 'Masquer' : 'Indice'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_currentItem < widget.exercise.items.length - 1) {
                    setState(() {
                      _currentItem++;
                      _showHint = false;
                    });
                  } else {
                    widget.onComplete(xp: 9);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Suivant'),
              ),
            ],
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

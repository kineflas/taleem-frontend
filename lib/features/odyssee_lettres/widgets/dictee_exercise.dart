import 'package:flutter/material.dart';
import '../models/odyssee_models.dart';

/// Dictee: Listen and select syllables in the correct order.
class DicteeExercise extends StatefulWidget {
  final OdysseeExercise exercise;
  final void Function({bool correct}) onComplete;

  const DicteeExercise({super.key, required this.exercise, required this.onComplete});

  @override
  State<DicteeExercise> createState() => _DicteeExerciseState();
}

class _DicteeExerciseState extends State<DicteeExercise> {
  int _currentItem = 0;
  List<String> _selectedSyllabes = [];
  bool _showFeedback = false;
  int _correctCount = 0;

  List<String> _allChips(Map<String, dynamic> item) {
    final correctes = List<String>.from(item['syllabes_correctes'] ?? []);
    final distracteurs = List<String>.from(item['distracteurs'] ?? []);
    final all = [...correctes, ...distracteurs]..shuffle();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.items;
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete(correct: true));
      return const SizedBox.shrink();
    }

    final item = items[_currentItem];
    final mot = item['mot'] ?? '';
    final syllabesCorrectes = List<String>.from(item['syllabes_correctes'] ?? []);
    final chips = _allChips(item);
    final isCorrectAnswer = _listEquals(_selectedSyllabes, syllabesCorrectes);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.exercise.promptFr != null)
            Text(widget.exercise.promptFr!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Ecoute et reconstitue le mot',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Audio play button
          Center(
            child: GestureDetector(
              onTap: () {
                // TODO: play audio item['audio_id']
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A9D8F), width: 3),
                ),
                child: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF2A9D8F), size: 40),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Selected syllabes display area
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _showFeedback
                  ? (isCorrectAnswer
                      ? const Color(0xFF2A9D8F).withOpacity(0.1)
                      : const Color(0xFFC0392B).withOpacity(0.08))
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showFeedback
                    ? (isCorrectAnswer
                        ? const Color(0xFF2A9D8F)
                        : const Color(0xFFC0392B))
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _selectedSyllabes.isEmpty
                ? Center(
                    child: Text(
                      'Tape les syllabes dans l\'ordre...',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    textDirection: TextDirection.rtl,
                    children: List.generate(_selectedSyllabes.length, (i) {
                      return GestureDetector(
                        onTap: _showFeedback
                            ? null
                            : () {
                                setState(() => _selectedSyllabes.removeAt(i));
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C3483).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF6C3483).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedSyllabes[i],
                                style: const TextStyle(
                                    fontSize: 20, fontFamily: 'Amiri', color: Color(0xFF6C3483)),
                                textDirection: TextDirection.rtl,
                              ),
                              if (!_showFeedback) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.close_rounded,
                                    size: 16, color: const Color(0xFF6C3483).withOpacity(0.6)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
          if (_showFeedback && !isCorrectAnswer) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'Correct: ${syllabesCorrectes.join(" ")}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2A9D8F)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Chip grid
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: chips.map((syl) {
                  final alreadyUsed = _selectedSyllabes.contains(syl);
                  return GestureDetector(
                    onTap: (_showFeedback || alreadyUsed)
                        ? null
                        : () {
                            setState(() => _selectedSyllabes.add(syl));
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: alreadyUsed
                            ? Colors.grey.shade200
                            : const Color(0xFFE76F51).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: alreadyUsed
                              ? Colors.grey.shade300
                              : const Color(0xFFE76F51).withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        syl,
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Amiri',
                          color: alreadyUsed ? Colors.grey : const Color(0xFFE76F51),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Validate button
          Row(
            children: [
              if (!_showFeedback && _selectedSyllabes.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedSyllabes.clear()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF999999)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Effacer',
                          style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
                    ),
                  ),
                ),
              if (!_showFeedback)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedSyllabes.isEmpty
                        ? null
                        : () {
                            final correct =
                                _listEquals(_selectedSyllabes, syllabesCorrectes);
                            setState(() {
                              _showFeedback = true;
                              if (correct) _correctCount++;
                            });
                            Future.delayed(const Duration(milliseconds: 1200), () {
                              if (!mounted) return;
                              if (_currentItem < items.length - 1) {
                                setState(() {
                                  _currentItem++;
                                  _selectedSyllabes = [];
                                  _showFeedback = false;
                                });
                              } else {
                                widget.onComplete(
                                    correct: _correctCount > items.length ~/ 2);
                              }
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Valider',
                        style: TextStyle(
                            fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentItem + 1}/${items.length}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

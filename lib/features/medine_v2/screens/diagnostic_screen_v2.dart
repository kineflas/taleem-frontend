import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson_models_v2.dart';
import '../providers/lesson_provider_v2.dart';

/// Adaptive diagnostic placement test screen.
class DiagnosticScreenV2 extends ConsumerStatefulWidget {
  const DiagnosticScreenV2({super.key});

  @override
  ConsumerState<DiagnosticScreenV2> createState() => _DiagnosticScreenV2State();
}

class _DiagnosticScreenV2State extends ConsumerState<DiagnosticScreenV2> {
  int _currentQ = 0;
  int? _selected;
  bool _answered = false;
  final List<Map<String, dynamic>> _answers = [];
  DiagnosticResult? _result;
  bool _submitting = false;
  bool _started = false;

  static const _color = Color(0xFF2A9D8F);

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selected = index);
  }

  void _confirmAnswer(List<DiagnosticQuestion> questions) {
    if (_selected == null || _answered) return;
    final q = questions[_currentQ];
    _answers.add({'question_id': q.id, 'selected': _selected});
    setState(() => _answered = true);
  }

  void _nextQuestion(List<DiagnosticQuestion> questions) {
    if (_currentQ < questions.length - 1) {
      setState(() {
        _currentQ++;
        _selected = null;
        _answered = false;
      });
    } else {
      _submitDiagnostic();
    }
  }

  Future<void> _submitDiagnostic() async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(medineV2ApiProvider);
      final result = await api.submitDiagnostic(answers: _answers);
      if (mounted) setState(() { _result = result; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagAsync = ref.watch(medineV2DiagnosticProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Test de Placement'),
        centerTitle: true,
      ),
      body: diagAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (diag) {
          if (_result != null) return _buildResult();
          if (_submitting) return const Center(child: CircularProgressIndicator());
          if (!_started) return _buildIntro(diag);
          return _buildQuestion(diag);
        },
      ),
    );
  }

  Widget _buildIntro(DiagnosticContent diag) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              'Test de Placement Adaptatif',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Text(
              '${diag.totalQuestions} questions • ${diag.estimatedTime}',
              style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'Ce test évalue ton niveau actuel en arabe et recommande par où commencer dans le Tome 1.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Réponds au mieux de tes connaissances, sans dictionnaire.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _started = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Commencer le test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(DiagnosticContent diag) {
    final q = diag.questions[_currentQ];
    final isCorrect = _answered && _selected == q.correct;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${_currentQ + 1}/${diag.questions.length}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor(q.difficulty).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _difficultyLabel(q.difficulty),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _difficultyColor(q.difficulty)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(q.skillTested, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQ + 1) / diag.questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(_color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              q.question,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), height: 1.4),
            ),
            const SizedBox(height: 20),

            ...q.options.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final isSelected = _selected == i;
              final isCorrectOpt = q.correct == i;

              Color bgColor = Colors.white;
              Color borderColor = Colors.grey.shade300;
              if (_answered) {
                if (isCorrectOpt) { bgColor = const Color(0xFFD4EDDA); borderColor = const Color(0xFF28A745); }
                else if (isSelected) { bgColor = const Color(0xFFF8D7DA); borderColor = const Color(0xFFDC3545); }
              } else if (isSelected) {
                bgColor = _color.withOpacity(0.1); borderColor = _color;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _selectOption(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                    ),
                    child: Text(
                      option,
                      textDirection: _isArabic(option) ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                ),
              );
            }),

            if (_answered && q.explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? const Color(0xFFD4EDDA) : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(isCorrect ? Icons.check_circle : Icons.info_outline, size: 20,
                      color: isCorrect ? const Color(0xFF28A745) : const Color(0xFFF4A261)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q.explanation!, style: const TextStyle(fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answered
                    ? () => _nextQuestion(diag.questions)
                    : (_selected != null ? () => _confirmAnswer(diag.questions) : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _answered ? (_currentQ < diag.questions.length - 1 ? 'Suivante' : 'Voir les résultats') : 'Confirmer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('🎯', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              result.level,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${result.correct}/${result.total} — ${result.score.round()}%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            const SizedBox(height: 20),

            // Radar chart
            if (result.competencies.isNotEmpty) ...[
              const Text(
                'Tes compétences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: CustomPaint(
                  painter: _RadarChartPainter(
                    competencies: result.competencies,
                    color: _color,
                  ),
                  size: const Size(250, 250),
                ),
              ),
              const SizedBox(height: 8),
              // Competency legend
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: result.competencies.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.score >= 0.5 ? const Color(0xFFD4EDDA) : const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.name} ${(c.score * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.score >= 0.5 ? const Color(0xFF28A745) : const Color(0xFFE76F51),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Notre recommandation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (result.startAtLesson <= 23) {
                    context.go('/medine-v2/lesson/${result.startAtLesson}');
                  } else {
                    context.go('/student/medine-v2');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  result.startAtLesson <= 23
                      ? 'Commencer à la Leçon ${result.startAtLesson}'
                      : 'Retour à la carte',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/student/medine-v2'),
              child: const Text('Retour à la carte', style: TextStyle(color: Color(0xFF999999))),
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(int d) {
    if (d >= 3) return const Color(0xFFC0392B);
    if (d >= 2) return const Color(0xFFF4A261);
    return const Color(0xFF28A745);
  }

  String _difficultyLabel(int d) {
    if (d >= 3) return 'Difficile';
    if (d >= 2) return 'Moyen';
    return 'Facile';
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').allMatches(text).length > text.length * 0.3;
  }
}

/// Simple radar/spider chart painter.
class _RadarChartPainter extends CustomPainter {
  final List<CompetencyScore> competencies;
  final Color color;

  _RadarChartPainter({required this.competencies, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;
    final n = competencies.length;
    if (n < 3) return;

    final angleStep = 2 * pi / n;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final angle = -pi / 2 + angleStep * (i % n);
        final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        if (i == 0) path.moveTo(p.dx, p.dy);
        else path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + angleStep * i;
      final end = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw data
    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (var i = 0; i <= n; i++) {
      final idx = i % n;
      final score = competencies[idx].score.clamp(0.0, 1.0);
      final r = radius * score;
      final angle = -pi / 2 + angleStep * idx;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) dataPath.moveTo(p.dx, p.dy);
      else dataPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw dots
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final score = competencies[i].score.clamp(0.0, 1.0);
      final r = radius * score;
      final angle = -pi / 2 + angleStep * i;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Draw labels
    final textPainterStyle = TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500);
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + angleStep * i;
      final labelR = radius + 15;
      final p = Offset(center.dx + labelR * cos(angle), center.dy + labelR * sin(angle));

      final tp = TextPainter(
        text: TextSpan(text: competencies[i].name, style: textPainterStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);

      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

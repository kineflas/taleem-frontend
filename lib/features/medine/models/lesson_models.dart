import 'package:equatable/equatable.dart';

// ── Theory ────────────────────────────────────────────────────────────────

class TheorySection extends Equatable {
  final String titleFr;
  final String contentFr;
  final String? contentAr;
  final String? tipFr;

  const TheorySection({
    required this.titleFr,
    required this.contentFr,
    this.contentAr,
    this.tipFr,
  });

  factory TheorySection.fromJson(Map<String, dynamic> json) => TheorySection(
        titleFr: json['title_fr'] ?? '',
        contentFr: json['content_fr'] ?? '',
        contentAr: json['content_ar'],
        tipFr: json['tip_fr'],
      );

  @override
  List<Object?> get props => [titleFr, contentFr, contentAr, tipFr];
}

class ExampleItem extends Equatable {
  final String arabic;
  final String? transliteration;
  final String translationFr;
  final String? breakdownFr;
  final String? grammaticalNoteFr;

  const ExampleItem({
    required this.arabic,
    this.transliteration,
    required this.translationFr,
    this.breakdownFr,
    this.grammaticalNoteFr,
  });

  factory ExampleItem.fromJson(Map<String, dynamic> json) => ExampleItem(
        arabic: json['arabic'] ?? '',
        transliteration: json['transliteration'],
        translationFr: json['translation_fr'] ?? '',
        breakdownFr: json['breakdown_fr'],
        grammaticalNoteFr: json['grammatical_note_fr'],
      );

  @override
  List<Object?> get props =>
      [arabic, transliteration, translationFr, breakdownFr, grammaticalNoteFr];
}

class VocabItem extends Equatable {
  final String arabic;
  final String translationFr;
  final String? transliteration;

  const VocabItem({
    required this.arabic,
    required this.translationFr,
    this.transliteration,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
        arabic: json['arabic'] ?? '',
        translationFr: json['translation_fr'] ?? '',
        transliteration: json['transliteration'],
      );

  @override
  List<Object?> get props => [arabic, translationFr, transliteration];
}

class IllustrationItem extends Equatable {
  final String type;
  final String titleFr;
  final dynamic data;

  const IllustrationItem({
    required this.type,
    required this.titleFr,
    this.data,
  });

  factory IllustrationItem.fromJson(Map<String, dynamic> json) =>
      IllustrationItem(
        type: json['type'] ?? '',
        titleFr: json['title_fr'] ?? '',
        data: json['data'],
      );

  @override
  List<Object?> get props => [type, titleFr, data];
}

class LessonTheory extends Equatable {
  final List<TheorySection> sections;
  final List<ExampleItem> examples;
  final List<VocabItem> vocab;
  final List<IllustrationItem> illustrations;
  final String? grammarSummary;

  const LessonTheory({
    this.sections = const [],
    this.examples = const [],
    this.vocab = const [],
    this.illustrations = const [],
    this.grammarSummary,
  });

  factory LessonTheory.fromJson(Map<String, dynamic> json) => LessonTheory(
        sections: (json['sections'] as List? ?? [])
            .map((s) => TheorySection.fromJson(s))
            .toList(),
        examples: (json['examples'] as List? ?? [])
            .map((e) => ExampleItem.fromJson(e))
            .toList(),
        vocab: (json['vocab'] as List? ?? [])
            .map((v) => VocabItem.fromJson(v))
            .toList(),
        illustrations: (json['illustrations'] as List? ?? [])
            .map((i) => IllustrationItem.fromJson(i))
            .toList(),
        grammarSummary: json['grammar_summary'],
      );

  @override
  List<Object?> get props =>
      [sections, examples, vocab, illustrations, grammarSummary];
}

// ── Quiz ──────────────────────────────────────────────────────────────────

class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correct;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correct: json['correct'] ?? 0,
        explanation: json['explanation'],
      );

  @override
  List<Object?> get props => [id, question, options, correct, explanation];
}

// ── Progress ──────────────────────────────────────────────────────────────

class LessonProgress extends Equatable {
  final bool theoryCompleted;
  final bool dialogueCompleted;
  final double? exercisesScore;
  final double? quizScore;
  final int stars;
  final bool isCompleted;

  const LessonProgress({
    this.theoryCompleted = false,
    this.dialogueCompleted = false,
    this.exercisesScore,
    this.quizScore,
    this.stars = 0,
    this.isCompleted = false,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) =>
      LessonProgress(
        theoryCompleted: json['theory_completed'] ?? false,
        dialogueCompleted: json['dialogue_completed'] ?? false,
        exercisesScore: (json['exercises_score'] as num?)?.toDouble(),
        quizScore: (json['quiz_score'] as num?)?.toDouble(),
        stars: json['stars'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
      );

  /// Energy bar: 4 segments (theory, dialogue, exercises, quiz)
  double get energyFraction {
    int filled = 0;
    if (theoryCompleted) filled++;
    if (dialogueCompleted) filled++;
    if (exercisesScore != null && exercisesScore! > 0) filled++;
    if (quizScore != null && quizScore! > 0) filled++;
    return filled / 4;
  }

  @override
  List<Object?> get props => [
        theoryCompleted,
        dialogueCompleted,
        exercisesScore,
        quizScore,
        stars,
        isCompleted,
      ];
}

// ── Lesson Detail ─────────────────────────────────────────────────────────

class LessonDetail extends Equatable {
  final String unitId;
  final int lessonNumber;
  final int partNumber;
  final String titleAr;
  final String titleFr;
  final String? descriptionFr;
  final LessonTheory theory;
  final List<QuizQuestion> quizQuestions;
  final List<QuizQuestion> quizMdQuestions;
  final bool isUnlocked;
  final int previousLessonStars;
  final LessonProgress? progress;

  const LessonDetail({
    required this.unitId,
    required this.lessonNumber,
    required this.partNumber,
    required this.titleAr,
    required this.titleFr,
    this.descriptionFr,
    required this.theory,
    this.quizQuestions = const [],
    this.quizMdQuestions = const [],
    this.isUnlocked = true,
    this.previousLessonStars = 0,
    this.progress,
  });

  /// All quiz questions combined
  List<QuizQuestion> get allQuizQuestions => [
        ...quizQuestions,
        ...quizMdQuestions,
      ];

  factory LessonDetail.fromJson(Map<String, dynamic> json) => LessonDetail(
        unitId: json['unit_id'] ?? '',
        lessonNumber: json['lesson_number'] ?? 0,
        partNumber: json['part_number'] ?? 1,
        titleAr: json['title_ar'] ?? '',
        titleFr: json['title_fr'] ?? '',
        descriptionFr: json['description_fr'],
        theory: LessonTheory.fromJson(json['theory'] ?? {}),
        quizQuestions: (json['quiz_questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
        quizMdQuestions: (json['quiz_md_questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
        isUnlocked: json['is_unlocked'] ?? true,
        previousLessonStars: json['previous_lesson_stars'] ?? 0,
        progress: json['progress'] != null
            ? LessonProgress.fromJson(json['progress'])
            : null,
      );

  @override
  List<Object?> get props => [
        unitId,
        lessonNumber,
        partNumber,
        titleAr,
        titleFr,
        descriptionFr,
        theory,
        quizQuestions,
        quizMdQuestions,
        isUnlocked,
        previousLessonStars,
        progress,
      ];
}

// ── Lesson List Item ──────────────────────────────────────────────────────

class LessonListItem extends Equatable {
  final String unitId;
  final int lessonNumber;
  final String titleAr;
  final String titleFr;
  final int stars;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isMasteredByDiagnostic;

  const LessonListItem({
    required this.unitId,
    required this.lessonNumber,
    required this.titleAr,
    required this.titleFr,
    this.stars = 0,
    this.isCompleted = false,
    this.isUnlocked = true,
    this.isMasteredByDiagnostic = false,
  });

  factory LessonListItem.fromJson(Map<String, dynamic> json) => LessonListItem(
        unitId: json['unit_id'] ?? '',
        lessonNumber: json['lesson_number'] ?? 0,
        titleAr: json['title_ar'] ?? '',
        titleFr: json['title_fr'] ?? '',
        stars: json['stars'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        isUnlocked: json['is_unlocked'] ?? true,
        isMasteredByDiagnostic: json['is_mastered_by_diagnostic'] ?? false,
      );

  @override
  List<Object?> get props => [
        unitId,
        lessonNumber,
        titleAr,
        titleFr,
        stars,
        isCompleted,
        isUnlocked,
        isMasteredByDiagnostic,
      ];
}

// ── Quiz Result ───────────────────────────────────────────────────────────

class QuizResult extends Equatable {
  final double score;
  final int total;
  final int correct;
  final int stars;
  final int xpEarned;
  final List<Map<String, dynamic>> results;

  const QuizResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.xpEarned,
    this.results = const [],
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: (json['score'] as num?)?.toDouble() ?? 0,
        total: json['total'] ?? 0,
        correct: json['correct'] ?? 0,
        stars: json['stars'] ?? 0,
        xpEarned: json['xp_earned'] ?? 0,
        results: (json['results'] as List? ?? [])
            .map((r) => Map<String, dynamic>.from(r))
            .toList(),
      );

  @override
  List<Object?> get props => [score, total, correct, stars, xpEarned, results];
}

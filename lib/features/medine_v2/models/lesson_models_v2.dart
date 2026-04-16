import 'package:equatable/equatable.dart';

// ── Discovery Cards ─────────────────────────────────────────────────────────

class DiscoveryCardExample extends Equatable {
  final String ar;
  final String fr;
  final String? translit;

  const DiscoveryCardExample({required this.ar, required this.fr, this.translit});

  factory DiscoveryCardExample.fromJson(Map<String, dynamic> json) =>
      DiscoveryCardExample(
        ar: json['ar'] ?? '',
        fr: json['fr'] ?? '',
        translit: json['translit'],
      );

  @override
  List<Object?> get props => [ar, fr, translit];
}

class DiscoveryCard extends Equatable {
  final String type; // rule, expert_corner, pronunciation, examples_table, mise_en_situation
  final String? titleFr;
  final String? contentFr;
  final String? contentAr;
  final List<DiscoveryCardExample> examples;
  final List<Map<String, dynamic>> items; // pronunciation
  final List<Map<String, dynamic>> rows;  // examples_table

  const DiscoveryCard({
    required this.type,
    this.titleFr,
    this.contentFr,
    this.contentAr,
    this.examples = const [],
    this.items = const [],
    this.rows = const [],
  });

  factory DiscoveryCard.fromJson(Map<String, dynamic> json) => DiscoveryCard(
        type: json['type'] ?? 'rule',
        titleFr: json['title_fr'],
        contentFr: json['content_fr'],
        contentAr: json['content_ar'],
        examples: (json['examples'] as List? ?? [])
            .map((e) => DiscoveryCardExample.fromJson(e))
            .toList(),
        items: (json['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        rows: (json['rows'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

  @override
  List<Object?> get props => [type, titleFr, contentFr, contentAr, examples, items, rows];
}

// ── Dialogue ────────────────────────────────────────────────────────────────

class DialogueLineV2 extends Equatable {
  final String speakerAr;
  final String arabic;
  final String french;

  const DialogueLineV2({
    required this.speakerAr,
    required this.arabic,
    this.french = '',
  });

  factory DialogueLineV2.fromJson(Map<String, dynamic> json) => DialogueLineV2(
        speakerAr: json['speaker_ar'] ?? '',
        arabic: json['arabic'] ?? '',
        french: json['french'] ?? '',
      );

  @override
  List<Object?> get props => [speakerAr, arabic, french];
}

class DialogueV2 extends Equatable {
  final String? situation;
  final List<DialogueLineV2> lines;

  const DialogueV2({this.situation, this.lines = const []});

  factory DialogueV2.fromJson(Map<String, dynamic> json) => DialogueV2(
        situation: json['situation'],
        lines: (json['lines'] as List? ?? [])
            .map((l) => DialogueLineV2.fromJson(l))
            .toList(),
      );

  @override
  List<Object?> get props => [situation, lines];
}

// ── Exercises ───────────────────────────────────────────────────────────────

class ExerciseItemV2 extends Equatable {
  final String? sentence;
  final String? answer;
  final String? promptFr;
  final String? answerAr;
  final String? word;
  final String? category;

  const ExerciseItemV2({
    this.sentence,
    this.answer,
    this.promptFr,
    this.answerAr,
    this.word,
    this.category,
  });

  factory ExerciseItemV2.fromJson(Map<String, dynamic> json) => ExerciseItemV2(
        sentence: json['sentence'],
        answer: json['answer'],
        promptFr: json['prompt_fr'],
        answerAr: json['answer_ar'],
        word: json['word'],
        category: json['category'],
      );

  @override
  List<Object?> get props => [sentence, answer, promptFr, answerAr, word, category];
}

class ExerciseV2 extends Equatable {
  final String type; // REORDER, FILL_BLANK, TRANSLATE, CLASSIFY
  final String? promptFr;
  final List<String> words;
  final List<String> answerWords;
  final List<ExerciseItemV2> items;
  final List<String> categories;

  const ExerciseV2({
    required this.type,
    this.promptFr,
    this.words = const [],
    this.answerWords = const [],
    this.items = const [],
    this.categories = const [],
  });

  factory ExerciseV2.fromJson(Map<String, dynamic> json) => ExerciseV2(
        type: json['type'] ?? '',
        promptFr: json['prompt_fr'],
        words: List<String>.from(json['words'] ?? []),
        answerWords: List<String>.from(json['answer'] ?? []),
        items: (json['items'] as List? ?? [])
            .map((e) => ExerciseItemV2.fromJson(e))
            .toList(),
        categories: List<String>.from(json['categories'] ?? []),
      );

  @override
  List<Object?> get props => [type, promptFr, words, answerWords, items, categories];
}

// ── Quiz ────────────────────────────────────────────────────────────────────

class QuizQuestionV2 extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correct;
  final String? explanation;

  const QuizQuestionV2({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    this.explanation,
  });

  factory QuizQuestionV2.fromJson(Map<String, dynamic> json) => QuizQuestionV2(
        id: json['id']?.toString() ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correct: json['correct'] ?? 0,
        explanation: json['explanation'],
      );

  @override
  List<Object?> get props => [id, question, options, correct, explanation];
}

// ── Flashcard ───────────────────────────────────────────────────────────────

class FlashcardV2 extends Equatable {
  final String? id;
  final String frontAr;
  final String backFr;
  final String? category;
  final String? exampleAr;
  final String? exampleFr;

  const FlashcardV2({
    this.id,
    required this.frontAr,
    required this.backFr,
    this.category,
    this.exampleAr,
    this.exampleFr,
  });

  factory FlashcardV2.fromJson(Map<String, dynamic> json) => FlashcardV2(
        id: json['id'],
        frontAr: json['front_ar'] ?? '',
        backFr: json['back_fr'] ?? '',
        category: json['category'],
        exampleAr: json['example_ar'],
        exampleFr: json['example_fr'],
      );

  @override
  List<Object?> get props => [id, frontAr, backFr, category, exampleAr, exampleFr];
}

// ── Lesson Content V2 ──────────────────────────────────────────────────────

class LessonContentV2 extends Equatable {
  final int lessonNumber;
  final String titleFr;
  final String? titleAr;
  final int partNumber;
  final String partName;
  final String? objective;
  final List<DiscoveryCard> discoveryCards;
  final DialogueV2? dialogue;
  final List<ExerciseV2> exercises;
  final List<QuizQuestionV2> quizQuestions;
  final List<FlashcardV2> flashcards;

  const LessonContentV2({
    required this.lessonNumber,
    required this.titleFr,
    this.titleAr,
    required this.partNumber,
    required this.partName,
    this.objective,
    this.discoveryCards = const [],
    this.dialogue,
    this.exercises = const [],
    this.quizQuestions = const [],
    this.flashcards = const [],
  });

  factory LessonContentV2.fromJson(Map<String, dynamic> json) => LessonContentV2(
        lessonNumber: json['lesson_number'] ?? 0,
        titleFr: json['title_fr'] ?? '',
        titleAr: json['title_ar'],
        partNumber: json['part_number'] ?? 1,
        partName: json['part_name'] ?? '',
        objective: json['objective'],
        discoveryCards: (json['discovery_cards'] as List? ?? [])
            .map((c) => DiscoveryCard.fromJson(c))
            .toList(),
        dialogue: json['dialogue'] != null
            ? DialogueV2.fromJson(json['dialogue'])
            : null,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => ExerciseV2.fromJson(e))
            .toList(),
        quizQuestions: (json['quiz_questions'] as List? ?? [])
            .map((q) => QuizQuestionV2.fromJson(q))
            .toList(),
        flashcards: (json['flashcards'] as List? ?? [])
            .map((f) => FlashcardV2.fromJson(f))
            .toList(),
      );

  @override
  List<Object?> get props => [
        lessonNumber, titleFr, titleAr, partNumber, partName,
        objective, discoveryCards, dialogue, exercises, quizQuestions, flashcards,
      ];
}

// ── List Item V2 ────────────────────────────────────────────────────────────

class LessonListItemV2 extends Equatable {
  final int lessonNumber;
  final String titleFr;
  final String? titleAr;
  final int partNumber;
  final String partName;
  final int stars;
  final bool isCompleted;
  final bool isUnlocked;

  const LessonListItemV2({
    required this.lessonNumber,
    required this.titleFr,
    this.titleAr,
    required this.partNumber,
    required this.partName,
    this.stars = 0,
    this.isCompleted = false,
    this.isUnlocked = true,
  });

  factory LessonListItemV2.fromJson(Map<String, dynamic> json) => LessonListItemV2(
        lessonNumber: json['lesson_number'] ?? 0,
        titleFr: json['title_fr'] ?? '',
        titleAr: json['title_ar'],
        partNumber: json['part_number'] ?? 1,
        partName: json['part_name'] ?? '',
        stars: json['stars'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        isUnlocked: json['is_unlocked'] ?? true,
      );

  @override
  List<Object?> get props => [
        lessonNumber, titleFr, titleAr, partNumber, partName,
        stars, isCompleted, isUnlocked,
      ];
}

// ── Quiz Result V2 ──────────────────────────────────────────────────────────

class QuizResultV2 extends Equatable {
  final double score;
  final int total;
  final int correct;
  final int stars;
  final int xpEarned;
  final List<Map<String, dynamic>> results;

  const QuizResultV2({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.xpEarned,
    this.results = const [],
  });

  factory QuizResultV2.fromJson(Map<String, dynamic> json) => QuizResultV2(
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

// ── Boss Quiz ──────────────────────────────────────────────────────────────

class BossQuizContent extends Equatable {
  final int partNumber;
  final String title;
  final List<int> lessonsCovered;
  final int timeLimit;
  final int passingScore;
  final List<QuizQuestionV2> questions;

  const BossQuizContent({
    required this.partNumber,
    required this.title,
    this.lessonsCovered = const [],
    this.timeLimit = 15,
    this.passingScore = 70,
    this.questions = const [],
  });

  factory BossQuizContent.fromJson(Map<String, dynamic> json) => BossQuizContent(
        partNumber: json['part_number'] ?? 0,
        title: json['title'] ?? '',
        lessonsCovered: List<int>.from(json['lessons_covered'] ?? []),
        timeLimit: json['time_limit'] ?? 15,
        passingScore: json['passing_score'] ?? 70,
        questions: (json['questions'] as List? ?? [])
            .map((q) => QuizQuestionV2.fromJson(q))
            .toList(),
      );

  @override
  List<Object?> get props => [partNumber, title, lessonsCovered, timeLimit, passingScore, questions];
}

class BossQuizResult extends Equatable {
  final double score;
  final int total;
  final int correct;
  final int stars;
  final int xpEarned;
  final bool passed;
  final List<Map<String, dynamic>> results;

  const BossQuizResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.xpEarned,
    required this.passed,
    this.results = const [],
  });

  factory BossQuizResult.fromJson(Map<String, dynamic> json) => BossQuizResult(
        score: (json['score'] as num?)?.toDouble() ?? 0,
        total: json['total'] ?? 0,
        correct: json['correct'] ?? 0,
        stars: json['stars'] ?? 0,
        xpEarned: json['xp_earned'] ?? 0,
        passed: json['passed'] ?? false,
        results: (json['results'] as List? ?? [])
            .map((r) => Map<String, dynamic>.from(r))
            .toList(),
      );

  @override
  List<Object?> get props => [score, total, correct, stars, xpEarned, passed, results];
}

// ── Final Exam ─────────────────────────────────────────────────────────────

class FinalExamContent extends Equatable {
  final String examTitle;
  final int timeLimit;
  final int passingScore;
  final int totalQuestions;
  final List<QuizQuestionV2> questions;

  const FinalExamContent({
    required this.examTitle,
    this.timeLimit = 25,
    this.passingScore = 70,
    this.totalQuestions = 10,
    this.questions = const [],
  });

  factory FinalExamContent.fromJson(Map<String, dynamic> json) => FinalExamContent(
        examTitle: json['exam_title'] ?? '',
        timeLimit: json['time_limit'] ?? 25,
        passingScore: json['passing_score'] ?? 70,
        totalQuestions: json['total_questions'] ?? 10,
        questions: (json['questions'] as List? ?? [])
            .map((q) => QuizQuestionV2.fromJson(q))
            .toList(),
      );

  @override
  List<Object?> get props => [examTitle, timeLimit, passingScore, totalQuestions, questions];
}

// ── Diagnostic CAT ─────────────────────────────────────────────────────────

class DiagnosticQuestion extends Equatable {
  final String id;
  final String lessonTarget;
  final int difficulty;
  final String skillTested;
  final String question;
  final List<String> options;
  final int correct;
  final String? explanation;
  final String? adaptiveHint;

  const DiagnosticQuestion({
    required this.id,
    this.lessonTarget = '',
    this.difficulty = 1,
    this.skillTested = '',
    required this.question,
    required this.options,
    required this.correct,
    this.explanation,
    this.adaptiveHint,
  });

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) => DiagnosticQuestion(
        id: json['id']?.toString() ?? '',
        lessonTarget: json['lesson_target'] ?? '',
        difficulty: json['difficulty'] ?? 1,
        skillTested: json['skill_tested'] ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correct: json['correct'] ?? 0,
        explanation: json['explanation'],
        adaptiveHint: json['adaptive_hint'],
      );

  @override
  List<Object?> get props => [id, lessonTarget, difficulty, skillTested, question, options, correct];
}

class DiagnosticContent extends Equatable {
  final String testName;
  final int totalQuestions;
  final String estimatedTime;
  final List<DiagnosticQuestion> questions;

  const DiagnosticContent({
    required this.testName,
    this.totalQuestions = 10,
    this.estimatedTime = '10-12 minutes',
    this.questions = const [],
  });

  factory DiagnosticContent.fromJson(Map<String, dynamic> json) => DiagnosticContent(
        testName: json['test_name'] ?? '',
        totalQuestions: json['total_questions'] ?? 10,
        estimatedTime: json['estimated_time'] ?? '10-12 minutes',
        questions: (json['questions'] as List? ?? [])
            .map((q) => DiagnosticQuestion.fromJson(q))
            .toList(),
      );

  @override
  List<Object?> get props => [testName, totalQuestions, estimatedTime, questions];
}

class CompetencyScore extends Equatable {
  final String id;
  final String name;
  final double score;

  const CompetencyScore({
    required this.id,
    required this.name,
    required this.score,
  });

  factory CompetencyScore.fromJson(Map<String, dynamic> json) => CompetencyScore(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [id, name, score];
}

class DiagnosticResult extends Equatable {
  final double score;
  final int total;
  final int correct;
  final String level;
  final int startAtLesson;
  final int startAtPart;
  final String message;
  final List<CompetencyScore> competencies;
  final List<Map<String, dynamic>> results;

  const DiagnosticResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.level,
    required this.startAtLesson,
    required this.startAtPart,
    required this.message,
    this.competencies = const [],
    this.results = const [],
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) => DiagnosticResult(
        score: (json['score'] as num?)?.toDouble() ?? 0,
        total: json['total'] ?? 0,
        correct: json['correct'] ?? 0,
        level: json['level'] ?? '',
        startAtLesson: json['start_at_lesson'] ?? 1,
        startAtPart: json['start_at_part'] ?? 1,
        message: json['message'] ?? '',
        competencies: (json['competencies'] as List? ?? [])
            .map((c) => CompetencyScore.fromJson(c))
            .toList(),
        results: (json['results'] as List? ?? [])
            .map((r) => Map<String, dynamic>.from(r))
            .toList(),
      );

  @override
  List<Object?> get props => [score, total, correct, level, startAtLesson, startAtPart, message, competencies, results];
}

// ── Flashcard Group V2 (for review endpoint) ──────────────────────────────

class FlashcardGroupV2 extends Equatable {
  final int lessonNumber;
  final String titleFr;
  final int partNumber;
  final List<FlashcardV2> cards;

  const FlashcardGroupV2({
    required this.lessonNumber,
    required this.titleFr,
    required this.partNumber,
    this.cards = const [],
  });

  factory FlashcardGroupV2.fromJson(Map<String, dynamic> json) =>
      FlashcardGroupV2(
        lessonNumber: json['lesson_number'] ?? 0,
        titleFr: json['title_fr'] ?? '',
        partNumber: json['part_number'] ?? 1,
        cards: (json['cards'] as List? ?? [])
            .map((c) => FlashcardV2.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [lessonNumber, titleFr, partNumber, cards];
}

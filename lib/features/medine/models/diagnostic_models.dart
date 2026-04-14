import 'package:equatable/equatable.dart';

/// A diagnostic question from the backend.
class DiagnosticQuestion extends Equatable {
  final String id;
  final String pool;
  final int difficulty;
  final String skillTested;
  final String? lessonRef;
  final String question;
  final List<String> options;
  final String? adaptiveHint;

  const DiagnosticQuestion({
    required this.id,
    required this.pool,
    required this.difficulty,
    required this.skillTested,
    this.lessonRef,
    required this.question,
    required this.options,
    this.adaptiveHint,
  });

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) =>
      DiagnosticQuestion(
        id: json['id'] ?? '',
        pool: json['pool'] ?? 'A',
        difficulty: json['difficulty'] ?? 1,
        skillTested: json['skill_tested'] ?? '',
        lessonRef: json['lesson_ref'],
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        adaptiveHint: json['adaptive_hint'],
      );

  @override
  List<Object?> get props => [id, pool, difficulty, question];
}

/// Response when starting a diagnostic session.
class DiagnosticSession extends Equatable {
  final String sessionId;
  final DiagnosticQuestion question;
  final String currentPool;
  final int questionIndex;

  const DiagnosticSession({
    required this.sessionId,
    required this.question,
    required this.currentPool,
    required this.questionIndex,
  });

  factory DiagnosticSession.fromJson(Map<String, dynamic> json) =>
      DiagnosticSession(
        sessionId: json['session_id'] ?? '',
        question: DiagnosticQuestion.fromJson(json['question'] ?? {}),
        currentPool: json['current_pool'] ?? 'A',
        questionIndex: json['question_index'] ?? 0,
      );

  @override
  List<Object?> get props => [sessionId, currentPool, questionIndex];
}

/// Response after answering a diagnostic question.
class DiagnosticAnswerResponse extends Equatable {
  final bool isCorrect;
  final int correctAnswer;
  final String? explanation;
  final bool isCompleted;
  final DiagnosticQuestion? nextQuestion;
  final String currentPool;
  final int questionIndex;

  const DiagnosticAnswerResponse({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
    required this.isCompleted,
    this.nextQuestion,
    required this.currentPool,
    required this.questionIndex,
  });

  factory DiagnosticAnswerResponse.fromJson(Map<String, dynamic> json) =>
      DiagnosticAnswerResponse(
        isCorrect: json['is_correct'] ?? false,
        correctAnswer: json['correct_answer'] ?? 0,
        explanation: json['explanation'],
        isCompleted: json['is_completed'] ?? false,
        nextQuestion: json['next_question'] != null
            ? DiagnosticQuestion.fromJson(json['next_question'])
            : null,
        currentPool: json['current_pool'] ?? 'A',
        questionIndex: json['question_index'] ?? 0,
      );

  @override
  List<Object?> get props => [isCorrect, isCompleted, currentPool, questionIndex];
}

/// Final diagnostic result.
class DiagnosticResult extends Equatable {
  final int score;
  final String level;
  final String? levelMessage;
  final Map<String, dynamic>? skillScores;
  final List<dynamic>? recommendedPath;
  final String? estimatedDuration;

  const DiagnosticResult({
    required this.score,
    required this.level,
    this.levelMessage,
    this.skillScores,
    this.recommendedPath,
    this.estimatedDuration,
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticResult(
        score: json['score'] ?? 0,
        level: json['level'] ?? 'explorateur',
        levelMessage: json['level_message'],
        skillScores: json['skill_scores'] != null
            ? Map<String, dynamic>.from(json['skill_scores'])
            : null,
        recommendedPath: json['recommended_path'],
        estimatedDuration: json['estimated_duration'],
      );

  @override
  List<Object?> get props => [score, level, levelMessage];
}

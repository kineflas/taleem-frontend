import 'package:equatable/equatable.dart';

// ── Letter Data ────────────────────────────────────────────────────────────

class SyllabeInfo extends Equatable {
  final String glyph;
  final String son;
  final String audioId;

  const SyllabeInfo({required this.glyph, required this.son, required this.audioId});

  factory SyllabeInfo.fromJson(Map<String, dynamic> json) => SyllabeInfo(
        glyph: json['glyph'] ?? '',
        son: json['son'] ?? '',
        audioId: json['audio_id'] ?? '',
      );

  @override
  List<Object?> get props => [glyph, son, audioId];
}

class FormesPositionnelles extends Equatable {
  final String isolee;
  final String debut;
  final String milieu;
  final String fin;

  const FormesPositionnelles({
    required this.isolee,
    required this.debut,
    required this.milieu,
    required this.fin,
  });

  factory FormesPositionnelles.fromJson(Map<String, dynamic> json) =>
      FormesPositionnelles(
        isolee: json['isolee'] ?? '',
        debut: json['debut'] ?? '',
        milieu: json['milieu'] ?? '',
        fin: json['fin'] ?? '',
      );

  @override
  List<Object?> get props => [isolee, debut, milieu, fin];
}

class LetterData extends Equatable {
  final String id;
  final String glyph;
  final String nameFr;
  final String nameAr;
  final String mnemoniqueVisuelle;
  final String conseilAnatomique;
  final String audioId;
  final String famille;
  final bool connectante;
  final FormesPositionnelles formes;
  final Map<String, SyllabeInfo> syllabes; // fatha, damma, kasra

  const LetterData({
    required this.id,
    required this.glyph,
    required this.nameFr,
    required this.nameAr,
    required this.mnemoniqueVisuelle,
    required this.conseilAnatomique,
    required this.audioId,
    required this.famille,
    required this.connectante,
    required this.formes,
    this.syllabes = const {},
  });

  factory LetterData.fromJson(Map<String, dynamic> json) {
    final syllMap = <String, SyllabeInfo>{};
    final rawSyll = json['syllabes'] as Map<String, dynamic>? ?? {};
    for (final entry in rawSyll.entries) {
      syllMap[entry.key] = SyllabeInfo.fromJson(entry.value);
    }
    return LetterData(
      id: json['id'] ?? '',
      glyph: json['glyph'] ?? '',
      nameFr: json['name_fr'] ?? '',
      nameAr: json['name_ar'] ?? '',
      mnemoniqueVisuelle: json['mnemonique_visuelle'] ?? '',
      conseilAnatomique: json['conseil_anatomique'] ?? '',
      audioId: json['audio_id'] ?? '',
      famille: json['famille'] ?? '',
      connectante: json['connectante'] ?? true,
      formes: FormesPositionnelles.fromJson(
          json['formes_positionnelles'] ?? {}),
      syllabes: syllMap,
    );
  }

  @override
  List<Object?> get props => [
        id, glyph, nameFr, nameAr, mnemoniqueVisuelle,
        conseilAnatomique, audioId, famille, connectante, formes, syllabes,
      ];
}

// ── Écoute ─────────────────────────────────────────────────────────────────

class EcouteSequenceItem extends Equatable {
  final String audioId;
  final String label;

  const EcouteSequenceItem({required this.audioId, required this.label});

  factory EcouteSequenceItem.fromJson(Map<String, dynamic> json) =>
      EcouteSequenceItem(
        audioId: json['audio_id'] ?? '',
        label: json['label'] ?? '',
      );

  @override
  List<Object?> get props => [audioId, label];
}

class AnatomieItem extends Equatable {
  final String lettreId;
  final String zone;
  final String description;

  const AnatomieItem({
    required this.lettreId,
    required this.zone,
    required this.description,
  });

  factory AnatomieItem.fromJson(Map<String, dynamic> json) => AnatomieItem(
        lettreId: json['lettre_id'] ?? '',
        zone: json['zone'] ?? '',
        description: json['description'] ?? '',
      );

  @override
  List<Object?> get props => [lettreId, zone, description];
}

class EcouteData extends Equatable {
  final String instruction;
  final List<EcouteSequenceItem> sequence;
  final List<AnatomieItem> anatomie;

  const EcouteData({
    required this.instruction,
    this.sequence = const [],
    this.anatomie = const [],
  });

  factory EcouteData.fromJson(Map<String, dynamic> json) => EcouteData(
        instruction: json['instruction'] ?? '',
        sequence: (json['sequence'] as List? ?? [])
            .map((e) => EcouteSequenceItem.fromJson(e))
            .toList(),
        anatomie: (json['anatomie'] as List? ?? [])
            .map((e) => AnatomieItem.fromJson(e))
            .toList(),
      );

  @override
  List<Object?> get props => [instruction, sequence, anatomie];
}

// ── Mini-lecture (Karaoké) ─────────────────────────────────────────────────

class KaraokeItem extends Equatable {
  final String text;
  final String son;
  final String audioId;
  final int delayMs;

  const KaraokeItem({
    required this.text,
    required this.son,
    required this.audioId,
    this.delayMs = 0,
  });

  factory KaraokeItem.fromJson(Map<String, dynamic> json) => KaraokeItem(
        text: json['text'] ?? '',
        son: json['son'] ?? '',
        audioId: json['audio_id'] ?? '',
        delayMs: json['delay_ms'] ?? 0,
      );

  @override
  List<Object?> get props => [text, son, audioId, delayMs];
}

class MiniLectureData extends Equatable {
  final String type;
  final String instruction;
  final List<KaraokeItem> items;

  const MiniLectureData({
    required this.type,
    required this.instruction,
    this.items = const [],
  });

  factory MiniLectureData.fromJson(Map<String, dynamic> json) =>
      MiniLectureData(
        type: json['type'] ?? 'KARAOKE',
        instruction: json['instruction'] ?? '',
        items: (json['items'] as List? ?? [])
            .map((e) => KaraokeItem.fromJson(e))
            .toList(),
      );

  @override
  List<Object?> get props => [type, instruction, items];
}

// ── Exercise (polymorphic) ─────────────────────────────────────────────────

class OdysseeExercise extends Equatable {
  final String type; // FUSION, POINTS, AUDIO_QUIZ, COMPLETER_SYLLABE, etc.
  final String? promptFr;
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final int? timeLimitSeconds;

  const OdysseeExercise({
    required this.type,
    this.promptFr,
    this.items = const [],
    this.categories = const [],
    this.timeLimitSeconds,
  });

  factory OdysseeExercise.fromJson(Map<String, dynamic> json) =>
      OdysseeExercise(
        type: json['type'] ?? '',
        promptFr: json['prompt_fr'],
        items: (json['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        categories: List<String>.from(json['categories'] ?? []),
        timeLimitSeconds: json['time_limit_seconds'],
      );

  @override
  List<Object?> get props => [type, promptFr, items, categories, timeLimitSeconds];
}

// ── Quiz ───────────────────────────────────────────────────────────────────

class OdysseeQuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correct;
  final String? explanation;

  const OdysseeQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    this.explanation,
  });

  factory OdysseeQuizQuestion.fromJson(Map<String, dynamic> json) =>
      OdysseeQuizQuestion(
        id: json['id']?.toString() ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correct: json['correct'] ?? 0,
        explanation: json['explanation'],
      );

  @override
  List<Object?> get props => [id, question, options, correct, explanation];
}

// ── Flashcard ──────────────────────────────────────────────────────────────

class OdysseeFlashcard extends Equatable {
  final String? id;
  final String frontAr;
  final String backFr;
  final String? category;
  final String? exampleAr;
  final String? exampleFr;

  const OdysseeFlashcard({
    this.id,
    required this.frontAr,
    required this.backFr,
    this.category,
    this.exampleAr,
    this.exampleFr,
  });

  factory OdysseeFlashcard.fromJson(Map<String, dynamic> json) =>
      OdysseeFlashcard(
        id: json['id']?.toString(),
        frontAr: json['front_ar'] ?? '',
        backFr: json['back_fr'] ?? '',
        category: json['category'],
        exampleAr: json['example_ar'],
        exampleFr: json['example_fr'],
      );

  @override
  List<Object?> get props => [id, frontAr, backFr, category, exampleAr, exampleFr];
}

// ── Lesson Content ─────────────────────────────────────────────────────────

class OdysseeLessonContent extends Equatable {
  final int lessonNumber;
  final String titleFr;
  final String? titleAr;
  final int phaseNumber;
  final String phaseName;
  final String? objective;
  final List<LetterData> letters;
  final EcouteData? ecoute;
  final List<OdysseeExercise> exercises;
  final MiniLectureData? miniLecture;
  final List<OdysseeQuizQuestion> quizQuestions;
  final List<OdysseeFlashcard> flashcards;

  const OdysseeLessonContent({
    required this.lessonNumber,
    required this.titleFr,
    this.titleAr,
    required this.phaseNumber,
    required this.phaseName,
    this.objective,
    this.letters = const [],
    this.ecoute,
    this.exercises = const [],
    this.miniLecture,
    this.quizQuestions = const [],
    this.flashcards = const [],
  });

  factory OdysseeLessonContent.fromJson(Map<String, dynamic> json) =>
      OdysseeLessonContent(
        lessonNumber: json['lesson_number'] ?? 0,
        titleFr: json['title_fr'] ?? '',
        titleAr: json['title_ar'],
        phaseNumber: json['phase_number'] ?? 1,
        phaseName: json['phase_name'] ?? '',
        objective: json['objective'],
        letters: (json['letters'] as List? ?? [])
            .map((l) => LetterData.fromJson(l))
            .toList(),
        ecoute: json['ecoute'] != null
            ? EcouteData.fromJson(json['ecoute'])
            : null,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => OdysseeExercise.fromJson(e))
            .toList(),
        miniLecture: json['mini_lecture'] != null
            ? MiniLectureData.fromJson(json['mini_lecture'])
            : null,
        quizQuestions: (json['quiz_questions'] as List? ?? [])
            .map((q) => OdysseeQuizQuestion.fromJson(q))
            .toList(),
        flashcards: (json['flashcards'] as List? ?? [])
            .map((f) => OdysseeFlashcard.fromJson(f))
            .toList(),
      );

  @override
  List<Object?> get props => [
        lessonNumber, titleFr, titleAr, phaseNumber, phaseName,
        objective, letters, ecoute, exercises, miniLecture,
        quizQuestions, flashcards,
      ];
}

// ── List Item ──────────────────────────────────────────────────────────────

class OdysseeLessonListItem extends Equatable {
  final int lessonNumber;
  final String titleFr;
  final String? titleAr;
  final int phaseNumber;
  final String phaseName;
  final int stars;
  final bool isCompleted;
  final bool isUnlocked;

  const OdysseeLessonListItem({
    required this.lessonNumber,
    required this.titleFr,
    this.titleAr,
    required this.phaseNumber,
    required this.phaseName,
    this.stars = 0,
    this.isCompleted = false,
    this.isUnlocked = true,
  });

  factory OdysseeLessonListItem.fromJson(Map<String, dynamic> json) =>
      OdysseeLessonListItem(
        lessonNumber: json['lesson_number'] ?? 0,
        titleFr: json['title_fr'] ?? '',
        titleAr: json['title_ar'],
        phaseNumber: json['phase_number'] ?? 1,
        phaseName: json['phase_name'] ?? '',
        stars: json['stars'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        isUnlocked: json['is_unlocked'] ?? true,
      );

  @override
  List<Object?> get props => [
        lessonNumber, titleFr, titleAr, phaseNumber, phaseName,
        stars, isCompleted, isUnlocked,
      ];
}

// ── Quiz Result ────────────────────────────────────────────────────────────

class OdysseeQuizResult extends Equatable {
  final double score;
  final int total;
  final int correct;
  final int stars;
  final int xpEarned;
  final List<Map<String, dynamic>> results;

  const OdysseeQuizResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.xpEarned,
    this.results = const [],
  });

  factory OdysseeQuizResult.fromJson(Map<String, dynamic> json) =>
      OdysseeQuizResult(
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

class OdysseeBossQuizContent extends Equatable {
  final int phaseNumber;
  final String title;
  final List<int> lessonsCovered;
  final int timeLimit;
  final int passingScore;
  final List<OdysseeQuizQuestion> questions;

  const OdysseeBossQuizContent({
    required this.phaseNumber,
    required this.title,
    this.lessonsCovered = const [],
    this.timeLimit = 15,
    this.passingScore = 70,
    this.questions = const [],
  });

  factory OdysseeBossQuizContent.fromJson(Map<String, dynamic> json) =>
      OdysseeBossQuizContent(
        phaseNumber: json['phase_number'] ?? 0,
        title: json['title'] ?? '',
        lessonsCovered: List<int>.from(json['lessons_covered'] ?? []),
        timeLimit: json['time_limit'] ?? 15,
        passingScore: json['passing_score'] ?? 70,
        questions: (json['questions'] as List? ?? [])
            .map((q) => OdysseeQuizQuestion.fromJson(q))
            .toList(),
      );

  @override
  List<Object?> get props => [
        phaseNumber, title, lessonsCovered, timeLimit, passingScore, questions,
      ];
}

class OdysseeBossQuizResult extends Equatable {
  final double score;
  final int total;
  final int correct;
  final int stars;
  final int xpEarned;
  final bool passed;
  final List<Map<String, dynamic>> results;

  const OdysseeBossQuizResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.xpEarned,
    required this.passed,
    this.results = const [],
  });

  factory OdysseeBossQuizResult.fromJson(Map<String, dynamic> json) =>
      OdysseeBossQuizResult(
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

// ── Stats ──────────────────────────────────────────────────────────────────

class OdysseeStats extends Equatable {
  final int totalLessons;
  final int completedLessons;
  final int totalStars;
  final int totalXp;
  final int lettersLearned;
  final int currentPhase;

  const OdysseeStats({
    required this.totalLessons,
    required this.completedLessons,
    required this.totalStars,
    required this.totalXp,
    required this.lettersLearned,
    required this.currentPhase,
  });

  factory OdysseeStats.fromJson(Map<String, dynamic> json) => OdysseeStats(
        totalLessons: json['total_lessons'] ?? 0,
        completedLessons: json['completed_lessons'] ?? 0,
        totalStars: json['total_stars'] ?? 0,
        totalXp: json['total_xp'] ?? 0,
        lettersLearned: json['letters_learned'] ?? 0,
        currentPhase: json['current_phase'] ?? 1,
      );

  @override
  List<Object?> get props => [
        totalLessons, completedLessons, totalStars, totalXp,
        lettersLearned, currentPhase,
      ];
}

// ── Progress ───────────────────────────────────────────────────────────────

class OdysseeLessonProgress extends Equatable {
  final int currentStep;
  final bool ecouteDone;
  final bool discoveryDone;
  final double? exercisesScore;
  final bool miniLectureDone;
  final double? quizScore;
  final int stars;
  final bool isCompleted;
  final int xpEarned;

  const OdysseeLessonProgress({
    this.currentStep = 0,
    this.ecouteDone = false,
    this.discoveryDone = false,
    this.exercisesScore,
    this.miniLectureDone = false,
    this.quizScore,
    this.stars = 0,
    this.isCompleted = false,
    this.xpEarned = 0,
  });

  factory OdysseeLessonProgress.fromJson(Map<String, dynamic> json) =>
      OdysseeLessonProgress(
        currentStep: json['current_step'] ?? 0,
        ecouteDone: json['ecoute_done'] ?? false,
        discoveryDone: json['discovery_done'] ?? false,
        exercisesScore: (json['exercises_score'] as num?)?.toDouble(),
        miniLectureDone: json['mini_lecture_done'] ?? false,
        quizScore: (json['quiz_score'] as num?)?.toDouble(),
        stars: json['stars'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        xpEarned: json['xp_earned'] ?? 0,
      );

  @override
  List<Object?> get props => [
        currentStep, ecouteDone, discoveryDone, exercisesScore,
        miniLectureDone, quizScore, stars, isCompleted, xpEarned,
      ];
}

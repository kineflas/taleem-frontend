class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String setParentPin = '/auth/set-parent-pin';
  static const String verifyParentPin = '/auth/verify-parent-pin';

  // Teacher
  static const String teacherStudents = '/teacher/students';
  static const String teacherInvite = '/teacher/students/invite';
  static const String teacherTasks = '/teacher/tasks';

  // Programs
  static const String programs = '/programs';

  // Tasks
  static const String tasks = '/tasks';
  static const String quranLastForStudent = '/tasks/quran/last-for-student';

  // Student
  static const String studentTasksToday = '/student/tasks/today';
  static const String studentTasksAgenda = '/student/tasks/agenda';
  static const String studentStreak = '/student/streak';
  static const String studentJokers = '/student/jokers';
  static const String studentJokersUse = '/student/jokers/use';
  static const String studentProgress = '/student/progress';
  static const String studentProgressHeatmap = '/student/progress/heatmap';

  // Notifications
  static const String notifications = '/notifications';

  // Autonomous Learning
  static const String learnWords = '/learn/words';
  static const String learnRoots = '/learn/roots';
  static const String learnChunks = '/learn/chunks';
  static const String studentLearnModules = '/student/learn/modules';
  static const String studentLearnSrsDue = '/student/learn/srs/due';
  static const String studentLearnSrsReview = '/student/learn/srs/review';
  static const String studentLearnSrsStats = '/student/learn/srs/stats';
  static const String studentLearnSessions = '/student/learn/sessions';
  static const String studentLearnFlashRecall = '/student/learn/exercises/flash-recall';
  static const String studentLearnRootIntruder = '/student/learn/exercises/root-intruder';
  static const String studentLearnVerseScan = '/student/learn/exercises/verse-scan';

  // Hifz Master
  static const String studentHifzGoals = '/student/hifz/goals';
  static const String studentHifzSessions = '/student/hifz/sessions';
  static const String studentHifzVersesDue = '/student/hifz/verses/due';
  static const String studentHifzVersesAll  = '/student/hifz/verses';
  static const String studentHifzVersesReview = '/student/hifz/verses/review';
  static const String studentHifzXp = '/student/hifz/xp';
  static const String studentHifzReciters = '/student/hifz/reciters';

  // Medine Lessons
  static const String lessons = '/api/lessons';
  static String lessonDetail(int n) => '/api/lessons/$n';
  static String lessonProgress(int n) => '/api/lessons/$n/progress';
  static String lessonQuizSubmit(int n) => '/api/lessons/$n/quiz/submit';

  // Flashcards (SRS)
  static const String flashcardsDue = '/api/flashcards/due';
  static String flashcardsNew(int lesson) => '/api/flashcards/new/$lesson';
  static String flashcardReview(String id) => '/api/flashcards/$id/review';
  static const String flashcardsStats = '/api/flashcards/stats';

  // Diagnostic
  static const String diagnosticStart = '/api/diagnostic/start';
  static String diagnosticAnswer(String id) => '/api/diagnostic/$id/answer';
  static String diagnosticResult(String id) => '/api/diagnostic/$id/result';

  // ASR (Quran Recitation Validator)
  static const String asrBaseUrl = String.fromEnvironment(
    'ASR_BASE_URL',
    defaultValue: 'https://asr.taleem.cksyndic.ma',
  );
  static const String asrValidate = '/api/validate';
  static const String asrValidateReplay = '/api/validate-replay';
  static const String asrTranscribe = '/api/transcribe';
  static const String asrFindVerse = '/api/find-verse';
  static const String asrHealth = '/api/health';

  // Hifz V2 — Wird & SRS
  static const String studentHifzSurahsSuggested = '/student/hifz/v2/surahs/suggested';
  static const String studentHifzWirdToday = '/student/hifz/v2/wird/today';
  static const String studentHifzWirdStart = '/student/hifz/v2/wird/start';
  static String studentHifzWirdComplete(String id) => '/student/hifz/v2/wird/$id/complete';
  static const String studentHifzExerciseAnswer = '/student/hifz/v2/exercises/answer';
  static const String studentHifzStepResult = '/student/hifz/v2/steps/result';
  static const String studentHifzCheckpointComplete = '/student/hifz/v2/checkpoint/complete';
  static String studentHifzSurahContent(int n) => '/student/hifz/v2/surah/$n/content';
  static const String studentHifzMap = '/student/hifz/v2/map';
  static String studentHifzVerseProgress(int surah, int verse) =>
      '/student/hifz/v2/verse/$surah/$verse/progress';

  // Medine V2
  static const String lessonsV2 = '/api/v2/lessons';
  static String lessonV2Detail(int n) => '/api/v2/lessons/$n';
  static String lessonV2Progress(int n) => '/api/v2/lessons/$n/progress';
  static String lessonV2QuizSubmit(int n) => '/api/v2/lessons/$n/quiz/submit';
}

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
  static const String studentHifzVersesReview = '/student/hifz/verses/review';
  static const String studentHifzXp = '/student/hifz/xp';
  static const String studentHifzReciters = '/student/hifz/reciters';
}

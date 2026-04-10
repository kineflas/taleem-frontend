class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Taliem';

  // Auth
  static const String login = 'Se connecter';
  static const String register = "S'inscrire";
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String fullName = 'Nom complet';
  static const String iAmTeacher = 'Je suis enseignant';
  static const String iAmStudent = 'Je suis élève';
  static const String invitationCode = "Code d'invitation";
  static const String enterInvitationCode = "Saisir le code d'invitation de votre enseignant";
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = "Pas encore de compte ? S'inscrire";
  static const String alreadyAccount = 'Déjà un compte ? Se connecter';

  // Dashboard teacher
  static const String myStudents = 'Mes élèves';
  static const String addStudent = 'Ajouter un élève';
  static const String inviteStudent = 'Inviter un élève';
  static const String noStudents = 'Aucun élève pour le moment.\nInvitez votre premier élève !';

  // Dashboard student
  static const String today = "Aujourd'hui";
  static const String agenda = 'Agenda';
  static const String progress = 'Ma Progression';
  static const String settings = 'Réglages';
  static const String iReviewed = "✅ J'ai révisé";
  static const String toReviewToday = "À RÉVISER AUJOURD'HUI";
  static const String late = 'EN RETARD';
  static const String upcoming = 'À VENIR';
  static const String noTasksToday = "Pas de tâches aujourd'hui. Bonne journée !";

  // Task
  static const String quran = 'Coran';
  static const String arabic = 'Arabe';
  static const String memorization = 'Mémorisation';
  static const String revision = 'Révision';
  static const String reading = 'Lecture';
  static const String grammar = 'Grammaire';
  static const String vocabulary = 'Vocabulaire';
  static const String surah = 'Sourate';
  static const String verseFrom = 'Verset de';
  static const String verseTo = 'Verset à';
  static const String dueDate = "Date d'échéance";
  static const String createTask = 'Créer une tâche';
  static const String assignTask = 'Confirmer et assigner';
  static const String automaticSuggestion = 'Suggestion automatique';

  // Difficulty
  static const String difficulty = 'Difficulté';
  static const String easy = '😊 Facile';
  static const String medium = '😐 Moyen';
  static const String hard = '😓 Difficile';

  // Streak
  static const String currentStreak = 'Série actuelle';
  static const String bestStreak = 'Meilleure série';
  static const String days = 'jours';
  static const String jokers = 'Jokers';
  static const String jokersThisMonth = 'jokers ce mois';

  // Joker
  static const String useJoker = 'Utiliser un joker';
  static const String jokerDanger = 'Ta série est en danger !';
  static const String jokerDangerBody = "Tu n'as encore rien révisé aujourd'hui.";
  static const String jokerReason = 'Raison';
  static const String jokerIllness = '🤒 Maladie';
  static const String jokerTravel = '✈️ Voyage';
  static const String jokerFamily = '👨‍👩‍👧 Obligations familiales';
  static const String jokerOther = '💬 Autre';
  static const String jokerNote = 'Note (optionnel)';
  static const String jokerConfirm = "Confirmer l'utilisation du joker";
  static const String jokerUsed = 'Joker utilisé. Ta série est préservée. Courage pour demain !';

  // Parental PIN
  static const String parentValidation = 'Validation parentale';
  static const String parentPin = 'Fais valider par un parent';
  static const String pinIncorrect = 'PIN incorrect';
  static const String pinBlocked = 'Trop d\'essais. Réessaie dans 5 minutes.';

  // Offline
  static const String offlineMode = 'Mode hors-ligne — Tes révisions seront synchronisées dès que tu seras connecté.';
  static const String connectionLost = 'Connexion perdue. Vérifie ta connexion internet.';
  static const String retry = 'Réessayer';

  // Errors
  static const String genericError = 'Une erreur est survenue. Réessaie.';
  static const String requiredField = 'Ce champ est requis';
  static const String invalidEmail = 'Email invalide';
  static const String passwordTooShort = 'Minimum 8 caractères';
}

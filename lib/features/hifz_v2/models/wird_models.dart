/// Modèles de données pour le Hifz Master V2 — Le Voyage du Hafiz.
///
/// Conventions :
///  - Noms arabes translittérés pour les concepts coraniques (wird, nour, tikrar…)
///  - Enums string-compatible pour la sérialisation JSON
///  - Immutabilité via constructeurs const

// ── Étapes du flow verset ─────────────────────────────────────────

enum WirdStep {
  nour,    // Étape 1 — Illumination (sens)
  tikrar,  // Étape 2 — Répétition guidée (karaoke 6446)
  tamrin,  // Étape 3 — Exercices interactifs
  tasmi,   // Étape 4 — Récitation intégrale
  natija,  // Étape 5 — Résultat & étoiles
}

// ── Paliers SRS (7 niveaux) ───────────────────────────────────────

enum SrsTier {
  nouveau(1, 'Nouveau', 1, 0),
  fragile(2, 'Fragile', 2, 20),
  enCours(3, 'En cours', 4, 40),
  acquis(4, 'Acquis', 7, 55),
  solide(5, 'Solide', 14, 70),
  maitrise(6, 'Maîtrisé', 30, 85),
  ancre(7, 'Ancré', 90, 95);

  const SrsTier(this.level, this.label, this.intervalDays, this.minScore);
  final int level;
  final String label;
  final int intervalDays;
  final int minScore;

  static SrsTier fromScore(int score) {
    if (score >= 95) return ancre;
    if (score >= 85) return maitrise;
    if (score >= 70) return solide;
    if (score >= 55) return acquis;
    if (score >= 40) return enCours;
    if (score >= 20) return fragile;
    return nouveau;
  }
}

// ── Types d'exercices ──────────────────────────────────────────────

enum ExerciseType {
  puzzleLumiere('puzzle_lumiere', 'Le Puzzle de Lumière'),   // Remise en ordre
  motManquant('mot_manquant', 'Le Mot Manquant'),           // QCM trou
  versetSuivant('verset_suivant', 'Quel est le suivant ?'),  // Continuité
  ecouteIdentifie('ecoute_identifie', 'Écoute & identifie'),
  versetMiroir('verset_miroir', 'Le Verset Miroir'),         // Récitation ASR
  vraiOuFaux('vrai_ou_faux', 'Vrai ou Faux'),
  debutFin('debut_fin', 'Début / Fin');

  const ExerciseType(this.key, this.label);
  final String key;
  final String label;
}

// ── Bloc du Wird ──────────────────────────────────────────────────

enum WirdBloc {
  jadid,  // Nouveaux versets — flow complet 5 étapes
  qarib,  // Révision proche (J+1 à J+7) — 2 exercices + récitation
  baid,   // Révision lointaine (J+7+) — 1 exercice + récitation
}

// ── Étapes du Checkpoint (Phase 2) ───────────────────────────────

enum CheckpointStep {
  istima,   // Écoute globale (pas de score)
  tartib,   // Ordonnancement des versets
  takamul,  // Complétion multi-versets (trous)
  tasmi,    // Récitation cumulée
  natija,   // Résultats du checkpoint
}

// ── Verset enrichi ────────────────────────────────────────────────

class EnrichedVerse {
  const EnrichedVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.textAr,
    required this.words,
    this.textFr,
    this.contextFr,
    this.audioTimings,
    this.keyWordAr,
    this.keyWordFr,
  });

  final int surahNumber;
  final int verseNumber;
  final String textAr;
  final List<String> words;         // Mots individuels (avec tashkeel)
  final String? textFr;             // Traduction française
  final String? contextFr;          // Note de contexte (1-2 lignes)
  final List<double>? audioTimings; // Timings karaoke [start0, start1, …, endN]
  final String? keyWordAr;          // Mot-clé arabe
  final String? keyWordFr;          // Mot-clé français

  /// Référence courte : « Al-Fatiha : 3 »
  String get reference => '$surahNumber:$verseNumber';

  factory EnrichedVerse.fromJson(Map<String, dynamic> json) => EnrichedVerse(
        surahNumber: json['surah_number'] as int,
        verseNumber: json['number'] as int,
        textAr: json['text_ar'] as String,
        words: List<String>.from(json['words'] ?? (json['text_ar'] as String).split(' ')),
        textFr: json['text_fr'] as String?,
        contextFr: json['context_fr'] as String?,
        audioTimings: (json['audio_timing'] as List?)?.map((e) => (e as num).toDouble()).toList(),
        keyWordAr: json['key_word']?['ar'] as String?,
        keyWordFr: json['key_word']?['fr'] as String?,
      );
}

// ── Session Wird ──────────────────────────────────────────────────

class WirdSession {
  WirdSession({
    required this.date,
    required this.jadidVerses,
    this.qaribVerses = const [],
    this.baidVerses = const [],
    this.reciterFolder = 'Alafasy_128kbps',
  });

  final DateTime date;
  final List<EnrichedVerse> jadidVerses;
  final List<EnrichedVerse> qaribVerses;
  final List<EnrichedVerse> baidVerses;
  final String reciterFolder;

  int get totalVerses =>
      jadidVerses.length + qaribVerses.length + baidVerses.length;

  Duration get estimatedDuration => Duration(
        minutes: jadidVerses.length * 10 +
            qaribVerses.length * 2 +
            baidVerses.length * 1,
      );
}

// ── Progression verset (SRS) ──────────────────────────────────────

class VerseProgress {
  VerseProgress({
    required this.surahNumber,
    required this.verseNumber,
    this.masteryScore = 0,
    this.stars = 0,
    this.reviewCount = 0,
    this.consecutiveSuccesses = 0,
    DateTime? nextReviewDate,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  final int surahNumber;
  final int verseNumber;
  int masteryScore;  // 0-100
  int stars;         // 0-3
  int reviewCount;
  int consecutiveSuccesses;
  DateTime nextReviewDate;

  SrsTier get tier => SrsTier.fromScore(masteryScore);

  /// Met à jour le score après un exercice.
  void updateScore({required bool success, int weight = 10}) {
    if (success) {
      masteryScore = (masteryScore + weight).clamp(0, 100);
      consecutiveSuccesses++;
    } else {
      masteryScore = (masteryScore - (weight * 1.5).round()).clamp(0, 100);
      consecutiveSuccesses = 0;
    }
    reviewCount++;
    nextReviewDate = DateTime.now().add(Duration(days: tier.intervalDays));
    stars = masteryScore >= 90 ? 3 : masteryScore >= 70 ? 2 : masteryScore >= 50 ? 1 : 0;
  }
}

// ── Résultat d'un exercice ────────────────────────────────────────

class ExerciseResult {
  const ExerciseResult({
    required this.type,
    required this.isCorrect,
    required this.responseTimeMs,
    this.score = 0,
    this.details,
  });

  final ExerciseType type;
  final bool isCorrect;
  final int responseTimeMs;
  final int score;       // 0-100 pour cet exercice
  final String? details;
}

// ── Résultat d'une étape ──────────────────────────────────────────

class StepResult {
  const StepResult({
    required this.step,
    required this.score,
    this.exerciseResults = const [],
    this.durationSeconds = 0,
  });

  final WirdStep step;
  final int score;  // 0-100
  final List<ExerciseResult> exerciseResults;
  final int durationSeconds;
}

// ── Résultat global du verset (Natija) ────────────────────────────

class VerseSessionResult {
  const VerseSessionResult({
    required this.verse,
    required this.stepResults,
    required this.finalScore,
    required this.stars,
    required this.xpEarned,
  });

  final EnrichedVerse verse;
  final List<StepResult> stepResults;
  final int finalScore;  // 0-100 combiné
  final int stars;       // 1-3
  final int xpEarned;
}

// ── Résultat Checkpoint (Phase 2) ────────────────────────────────

class CheckpointResult {
  const CheckpointResult({
    required this.verses,
    required this.scoresByStep,
    required this.globalScore,
    required this.stars,
    required this.xpEarned,
    this.versesUpdated = 0,
  });

  final List<EnrichedVerse> verses;
  final Map<String, int> scoresByStep; // {"tartib": 80, "takamul": 90, "tasmi": 85}
  final int globalScore;
  final int stars;
  final int xpEarned;
  final int versesUpdated;
}

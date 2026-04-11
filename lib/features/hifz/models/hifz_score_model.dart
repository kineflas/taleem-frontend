/// Modèle partagé — protocole SILSILA (TIKRAR + MURAJA'A SMART)
/// Importé par hifz_session_screen.dart et hifz_revision_screen.dart

// ─────────────────────────────────────────────────────────────────────────────
// ReviewScore — auto-évaluation à 3 niveaux
//   green  → Mémorisé    → J+7
//   orange → Hésitation  → J+3
//   red    → Oublié      → J+1
// ─────────────────────────────────────────────────────────────────────────────

enum ReviewScore { green, orange, red }

/// Intervalles de révision adaptatifs (jours)
const Map<ReviewScore, int> reviewIntervals = {
  ReviewScore.green:  7,
  ReviewScore.orange: 3,
  ReviewScore.red:    1,
};

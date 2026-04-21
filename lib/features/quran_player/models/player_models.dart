/// Modèles de données pour le Lecteur Audio Coran.
///
/// Deux modes :
///   - Lecture libre (choix d'une sourate + plage de versets)
///   - Révision SRS (playlist auto basée sur les versets proches de l'oubli)

// ── Mode de lecture ─────────────────────────────────────────────

enum PlaybackMode {
  lecture('Lecture', 'قراءة'),
  revision('Révision', 'مراجعة');

  const PlaybackMode(this.labelFr, this.labelAr);
  final String labelFr;
  final String labelAr;
}

// ── Récitateurs ─────────────────────────────────────────────────

enum ReciterChoice {
  husary('Husary_64kbps', 'الحصري', 'Al-Husary', 'Apprentissage (lent)'),
  alafasy('Alafasy_64kbps', 'العفاسي', 'Al-Afasy', 'Fluide & mélodieux'),
  minshawi('Minshawy_Murattal_128kbps', 'المنشاوي', 'Al-Minshawi', 'Murattal classique');

  const ReciterChoice(this.folder, this.nameAr, this.nameFr, this.description);
  final String folder;
  final String nameAr;
  final String nameFr;
  final String description;

  /// URL audio pour un verset donné via le CDN EveryAyah.
  String audioUrl(int surah, int verse) {
    final s = surah.toString().padLeft(3, '0');
    final v = verse.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$folder/$s$v.mp3';
  }
}

// ── Entrée de playlist ──────────────────────────────────────────

class PlaylistEntry {
  const PlaylistEntry({
    required this.surah,
    required this.verse,
    this.repeatCount = 1,
    this.srsTier,
  });

  final int surah;
  final int verse;
  final int repeatCount;
  final String? srsTier; // null en mode lecture libre

  @override
  String toString() => 'PlaylistEntry($surah:$verse x$repeatCount)';
}

// ── Info sourate (pour affichage) ───────────────────────────────

class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.nameAr,
    required this.nameFr,
    required this.totalVerses,
  });

  final int number;
  final String nameAr;
  final String nameFr;
  final int totalVerses;

  factory SurahInfo.fromJson(Map<String, dynamic> json) => SurahInfo(
        number: json['surah_number'] as int,
        nameAr: json['surah_name_ar'] as String,
        nameFr: json['surah_name_fr'] as String,
        totalVerses: json['total_verses'] as int,
      );
}

// ── Verset pour la playlist SRS ─────────────────────────────────

class RevisionVerse {
  const RevisionVerse({
    required this.surah,
    required this.verse,
    required this.surahNameAr,
    required this.tier,
    required this.masteryScore,
    required this.nextReviewDate,
  });

  final int surah;
  final int verse;
  final String surahNameAr;
  final String tier;
  final int masteryScore;
  final String nextReviewDate;

  factory RevisionVerse.fromJson(Map<String, dynamic> json) => RevisionVerse(
        surah: json['surah_number'] as int,
        verse: json['verse_number'] as int,
        surahNameAr: json['surah_name_ar'] as String? ?? '',
        tier: json['tier'] as String? ?? 'nouveau',
        masteryScore: json['mastery_score'] as int? ?? 0,
        nextReviewDate: json['next_review_date'] as String? ?? '',
      );

  /// Nombre de répétitions adaptatif selon le tier SRS.
  int get adaptiveRepeat {
    switch (tier.toLowerCase()) {
      case 'fragile':
        return 3;
      case 'en_cours':
        return 2;
      default:
        return 1;
    }
  }
}

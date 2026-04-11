// ─────────────────────────────────────────────────────────────────────────────
// BASE VOCABULAIRE CORAN — 220+ mots répartis sur 5 modules
//
// Sources :
//   • Corpus du Coran (corpus.quran.com) — fréquences
//   • Hamidullah / Berque — traductions françaises
//   • Lisân al-Arab — étymologies et racines
//   • Audio mot par mot : https://audio.qurancdn.com/wbw/{surah}/{verse}/{word}.mp3
//
// Structure d'un mot (QuranWord) :
//   id              → identifiant unique
//   arabicWord      → orthographe arabe avec tachkîl complet
//   transliteration → phonétique (système simple)
//   meaningFr       → traduction française principale
//   root            → racine trilatère (null pour particules)
//   moduleNumber    → module 1‑5
//   frequency       → occurrences dans le Coran
//   category        → particle | noun | verb | adjective | phrase
//   exampleSurah    → sourate de référence
//   exampleVerse    → verset de référence
//   exampleWordPos  → position du mot dans le verset (1-indexed, pour audio WBW)
//   relatedIds      → ids de mots de la même racine (pour module 4)
//   distractorIds   → ids de mots utilisés comme faux choix (QCM module 1)
// ─────────────────────────────────────────────────────────────────────────────

class QuranWord {
  final int id;
  final String arabicWord;
  final String transliteration;
  final String meaningFr;
  final String? root;
  final int moduleNumber;
  final int frequency;
  final String category; // particle | noun | verb | adjective | phrase
  final int exampleSurah;
  final int exampleVerse;
  final int exampleWordPos;
  final List<int> relatedIds;

  const QuranWord({
    required this.id,
    required this.arabicWord,
    required this.transliteration,
    required this.meaningFr,
    this.root,
    required this.moduleNumber,
    required this.frequency,
    required this.category,
    required this.exampleSurah,
    required this.exampleVerse,
    required this.exampleWordPos,
    this.relatedIds = const [],
  });

  /// URL audio mot par mot (qurancdn.com)
  String get audioUrl =>
      'https://audio.qurancdn.com/wbw/$exampleSurah/$exampleVerse/$exampleWordPos.mp3';

  /// URL audio du verset entier (fallback everyayah.com)
  String get verseAudioUrl {
    final s = exampleSurah.toString().padLeft(3, '0');
    final v = exampleVerse.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$s$v.mp3';
  }
}

/// Racine arabe avec ses dérivations
class ArabicRoot {
  final String root;        // ex: 'ك-ت-ب'
  final String meaningFr;  // ex: 'Écrire, inscrire'
  final int moduleNumber;  // toujours 4
  final List<RootDerivation> derivations;
  final RootDerivation intruder; // mot d'une autre racine pour l'exercice

  const ArabicRoot({
    required this.root,
    required this.meaningFr,
    required this.moduleNumber,
    required this.derivations,
    required this.intruder,
  });
}

class RootDerivation {
  final String word;
  final String transliteration;
  final String meaningFr;
  final String? context; // exemple coranique

  const RootDerivation({
    required this.word,
    required this.transliteration,
    required this.meaningFr,
    this.context,
  });
}

/// Bloc sémantique (formule coranique)
class QuranChunk {
  final int id;
  final String arabicText;
  final String meaningFr;
  final String context;    // sourate / nom de la formule
  final int orderInVerse;  // pour l'exercice de réordonnancement

  const QuranChunk({
    required this.id,
    required this.arabicText,
    required this.meaningFr,
    required this.context,
    required this.orderInVerse,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE 1 — Les 50 mots-clés du Coran (particles + mots fréquents)
// ─────────────────────────────────────────────────────────────────────────────
const List<QuranWord> kModule1Words = [
  // ── Particules grammaticales (ultra-fréquentes) ────────────────────────
  QuranWord(id: 101, arabicWord: 'مِنْ', transliteration: 'min', meaningFr: 'De / parmi', root: null, moduleNumber: 1, frequency: 2756, category: 'particle', exampleSurah: 1, exampleVerse: 2, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 102, arabicWord: 'فِي', transliteration: 'fī', meaningFr: 'Dans / en', root: null, moduleNumber: 1, frequency: 1722, category: 'particle', exampleSurah: 2, exampleVerse: 2, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 103, arabicWord: 'عَلَى', transliteration: 'ʿalā', meaningFr: 'Sur / au sujet de', root: null, moduleNumber: 1, frequency: 1443, category: 'particle', exampleSurah: 1, exampleVerse: 7, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 104, arabicWord: 'إِلَى', transliteration: 'ilā', meaningFr: 'Vers / jusqu\'à', root: null, moduleNumber: 1, frequency: 742, category: 'particle', exampleSurah: 1, exampleVerse: 6, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 105, arabicWord: 'عَنْ', transliteration: 'ʿan', meaningFr: 'Au sujet de / loin de', root: null, moduleNumber: 1, frequency: 503, category: 'particle', exampleSurah: 2, exampleVerse: 48, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 106, arabicWord: 'مَعَ', transliteration: 'maʿa', meaningFr: 'Avec / en compagnie de', root: null, moduleNumber: 1, frequency: 183, category: 'particle', exampleSurah: 2, exampleVerse: 153, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 107, arabicWord: 'إِنَّ', transliteration: 'inna', meaningFr: 'En vérité / certes', root: null, moduleNumber: 1, frequency: 1614, category: 'particle', exampleSurah: 1, exampleVerse: 6, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 108, arabicWord: 'أَنَّ', transliteration: 'anna', meaningFr: 'Que (conjonction)', root: null, moduleNumber: 1, frequency: 1388, category: 'particle', exampleSurah: 2, exampleVerse: 26, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 109, arabicWord: 'لَا', transliteration: 'lā', meaningFr: 'Non / il n\'y a pas', root: null, moduleNumber: 1, frequency: 2900, category: 'particle', exampleSurah: 2, exampleVerse: 255, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 110, arabicWord: 'وَ', transliteration: 'wa', meaningFr: 'Et (conjonction)', root: null, moduleNumber: 1, frequency: 18000, category: 'particle', exampleSurah: 1, exampleVerse: 1, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 111, arabicWord: 'ثُمَّ', transliteration: 'thumma', meaningFr: 'Puis / ensuite', root: null, moduleNumber: 1, frequency: 341, category: 'particle', exampleSurah: 2, exampleVerse: 28, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 112, arabicWord: 'أَوْ', transliteration: 'aw', meaningFr: 'Ou (disjonction)', root: null, moduleNumber: 1, frequency: 265, category: 'particle', exampleSurah: 2, exampleVerse: 19, exampleWordPos: 1, relatedIds: []),

  // ── Pronoms ───────────────────────────────────────────────────────────────
  QuranWord(id: 121, arabicWord: 'هُوَ', transliteration: 'huwa', meaningFr: 'Il / lui', root: null, moduleNumber: 1, frequency: 543, category: 'particle', exampleSurah: 112, exampleVerse: 1, exampleWordPos: 3, relatedIds: [122, 123]),
  QuranWord(id: 122, arabicWord: 'هِيَ', transliteration: 'hiya', meaningFr: 'Elle', root: null, moduleNumber: 1, frequency: 100, category: 'particle', exampleSurah: 97, exampleVerse: 5, exampleWordPos: 1, relatedIds: [121, 123]),
  QuranWord(id: 123, arabicWord: 'هُمْ', transliteration: 'hum', meaningFr: 'Ils / eux', root: null, moduleNumber: 1, frequency: 2041, category: 'particle', exampleSurah: 2, exampleVerse: 5, exampleWordPos: 1, relatedIds: [121, 122]),
  QuranWord(id: 124, arabicWord: 'أَنْتَ', transliteration: 'anta', meaningFr: 'Toi (masc. sing.)', root: null, moduleNumber: 1, frequency: 153, category: 'particle', exampleSurah: 5, exampleVerse: 116, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 125, arabicWord: 'نَحْنُ', transliteration: 'naḥnu', meaningFr: 'Nous', root: null, moduleNumber: 1, frequency: 95, category: 'particle', exampleSurah: 15, exampleVerse: 9, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 126, arabicWord: 'أَنَا', transliteration: 'anā', meaningFr: 'Moi / je', root: null, moduleNumber: 1, frequency: 60, category: 'particle', exampleSurah: 20, exampleVerse: 14, exampleWordPos: 1, relatedIds: []),

  // ── Noms (substantifs) fréquents ─────────────────────────────────────────
  QuranWord(id: 131, arabicWord: 'اللَّه', transliteration: 'Allāh', meaningFr: 'Dieu / Allah', root: 'إ-ل-ه', moduleNumber: 1, frequency: 2699, category: 'noun', exampleSurah: 1, exampleVerse: 1, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 132, arabicWord: 'رَبّ', transliteration: 'rabb', meaningFr: 'Seigneur / Maître', root: 'ر-ب-ب', moduleNumber: 1, frequency: 970, category: 'noun', exampleSurah: 1, exampleVerse: 2, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 133, arabicWord: 'يَوْم', transliteration: 'yawm', meaningFr: 'Jour', root: 'ي-و-م', moduleNumber: 1, frequency: 405, category: 'noun', exampleSurah: 1, exampleVerse: 4, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 134, arabicWord: 'أَرْض', transliteration: 'arḍ', meaningFr: 'Terre', root: 'أ-ر-ض', moduleNumber: 1, frequency: 461, category: 'noun', exampleSurah: 2, exampleVerse: 22, exampleWordPos: 4, relatedIds: [135]),
  QuranWord(id: 135, arabicWord: 'سَمَاء', transliteration: 'samāʾ', meaningFr: 'Ciel', root: 'س-م-و', moduleNumber: 1, frequency: 310, category: 'noun', exampleSurah: 2, exampleVerse: 22, exampleWordPos: 2, relatedIds: [134]),
  QuranWord(id: 136, arabicWord: 'نَاس', transliteration: 'nās', meaningFr: 'Gens / humanité', root: 'أ-ن-س', moduleNumber: 1, frequency: 241, category: 'noun', exampleSurah: 114, exampleVerse: 1, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 137, arabicWord: 'كِتَاب', transliteration: 'kitāb', meaningFr: 'Livre', root: 'ك-ت-ب', moduleNumber: 1, frequency: 255, category: 'noun', exampleSurah: 2, exampleVerse: 2, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 138, arabicWord: 'نَفْس', transliteration: 'nafs', meaningFr: 'Âme / être / soi', root: 'ن-ف-س', moduleNumber: 1, frequency: 298, category: 'noun', exampleSurah: 2, exampleVerse: 48, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 139, arabicWord: 'حَقّ', transliteration: 'ḥaqq', meaningFr: 'Vérité / droit / juste', root: 'ح-ق-ق', moduleNumber: 1, frequency: 287, category: 'noun', exampleSurah: 2, exampleVerse: 26, exampleWordPos: 9, relatedIds: []),
  QuranWord(id: 140, arabicWord: 'رَحْمَة', transliteration: 'raḥma', meaningFr: 'Miséricorde / grâce', root: 'ر-ح-م', moduleNumber: 1, frequency: 114, category: 'noun', exampleSurah: 1, exampleVerse: 3, exampleWordPos: 2, relatedIds: [148, 149]),
  QuranWord(id: 141, arabicWord: 'عَذَاب', transliteration: 'ʿadhāb', meaningFr: 'Châtiment / supplice', root: 'ع-ذ-ب', moduleNumber: 1, frequency: 322, category: 'noun', exampleSurah: 2, exampleVerse: 7, exampleWordPos: 6, relatedIds: []),
  QuranWord(id: 142, arabicWord: 'آيَة', transliteration: 'āya', meaningFr: 'Signe / verset', root: 'أ-ي-ي', moduleNumber: 1, frequency: 382, category: 'noun', exampleSurah: 2, exampleVerse: 99, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 143, arabicWord: 'دِين', transliteration: 'dīn', meaningFr: 'Religion / jugement', root: 'د-ي-ن', moduleNumber: 1, frequency: 92, category: 'noun', exampleSurah: 1, exampleVerse: 4, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 144, arabicWord: 'صَلَاة', transliteration: 'ṣalāh', meaningFr: 'Prière / connexion', root: 'ص-ل-و', moduleNumber: 1, frequency: 67, category: 'noun', exampleSurah: 2, exampleVerse: 3, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 145, arabicWord: 'إِيمَان', transliteration: 'īmān', meaningFr: 'Foi / croyance', root: 'أ-م-ن', moduleNumber: 1, frequency: 45, category: 'noun', exampleSurah: 2, exampleVerse: 93, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 146, arabicWord: 'قَلْب', transliteration: 'qalb', meaningFr: 'Cœur', root: 'ق-ل-ب', moduleNumber: 1, frequency: 132, category: 'noun', exampleSurah: 2, exampleVerse: 7, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 147, arabicWord: 'عَقْل', transliteration: 'ʿaql', meaningFr: 'Raison / intellect', root: 'ع-ق-ل', moduleNumber: 1, frequency: 49, category: 'noun', exampleSurah: 2, exampleVerse: 44, exampleWordPos: 5, relatedIds: []),

  // ── Verbes fréquents ──────────────────────────────────────────────────────
  QuranWord(id: 151, arabicWord: 'قَالَ', transliteration: 'qāla', meaningFr: 'Il dit / dit-il', root: 'ق-و-ل', moduleNumber: 1, frequency: 1722, category: 'verb', exampleSurah: 2, exampleVerse: 30, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 152, arabicWord: 'كَانَ', transliteration: 'kāna', meaningFr: 'Il était / existait', root: 'ك-و-ن', moduleNumber: 1, frequency: 1361, category: 'verb', exampleSurah: 2, exampleVerse: 14, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 153, arabicWord: 'خَلَقَ', transliteration: 'khalaqa', meaningFr: 'Il créa', root: 'خ-ل-ق', moduleNumber: 1, frequency: 260, category: 'verb', exampleSurah: 96, exampleVerse: 2, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 154, arabicWord: 'عَلِمَ', transliteration: 'ʿalima', meaningFr: 'Il sut / connut', root: 'ع-ل-م', moduleNumber: 1, frequency: 280, category: 'verb', exampleSurah: 2, exampleVerse: 30, exampleWordPos: 8, relatedIds: [162, 163]),
  QuranWord(id: 155, arabicWord: 'آمَنَ', transliteration: 'āmana', meaningFr: 'Il crut / fit confiance', root: 'أ-م-ن', moduleNumber: 1, frequency: 537, category: 'verb', exampleSurah: 2, exampleVerse: 3, exampleWordPos: 2, relatedIds: [145]),
  QuranWord(id: 156, arabicWord: 'هَدَى', transliteration: 'hadā', meaningFr: 'Il guida', root: 'ه-د-ي', moduleNumber: 1, frequency: 316, category: 'verb', exampleSurah: 1, exampleVerse: 6, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 157, arabicWord: 'رَزَقَ', transliteration: 'razaqa', meaningFr: 'Il pourvut / subsista', root: 'ر-ز-ق', moduleNumber: 1, frequency: 123, category: 'verb', exampleSurah: 2, exampleVerse: 3, exampleWordPos: 6, relatedIds: []),
  QuranWord(id: 158, arabicWord: 'غَفَرَ', transliteration: 'ghafara', meaningFr: 'Il pardonna', root: 'غ-ف-ر', moduleNumber: 1, frequency: 234, category: 'verb', exampleSurah: 2, exampleVerse: 52, exampleWordPos: 2, relatedIds: [165]),
  QuranWord(id: 159, arabicWord: 'جَعَلَ', transliteration: 'jaʿala', meaningFr: 'Il fit / établit', root: 'ج-ع-ل', moduleNumber: 1, frequency: 346, category: 'verb', exampleSurah: 2, exampleVerse: 22, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 160, arabicWord: 'أَرْسَلَ', transliteration: 'arsala', meaningFr: 'Il envoya / dépêcha', root: 'ر-س-ل', moduleNumber: 1, frequency: 211, category: 'verb', exampleSurah: 2, exampleVerse: 252, exampleWordPos: 6, relatedIds: []),

  // ── Adjectifs / Noms divins ───────────────────────────────────────────────
  QuranWord(id: 148, arabicWord: 'رَحْمَان', transliteration: 'raḥmān', meaningFr: 'Infiniment Miséricordieux', root: 'ر-ح-م', moduleNumber: 1, frequency: 57, category: 'adjective', exampleSurah: 1, exampleVerse: 3, exampleWordPos: 1, relatedIds: [140, 149]),
  QuranWord(id: 149, arabicWord: 'رَحِيم', transliteration: 'raḥīm', meaningFr: 'Très Miséricordieux', root: 'ر-ح-م', moduleNumber: 1, frequency: 114, category: 'adjective', exampleSurah: 1, exampleVerse: 3, exampleWordPos: 2, relatedIds: [140, 148]),
  QuranWord(id: 161, arabicWord: 'عَظِيم', transliteration: 'ʿaẓīm', meaningFr: 'Immense / majestueux', root: 'ع-ظ-م', moduleNumber: 1, frequency: 360, category: 'adjective', exampleSurah: 2, exampleVerse: 255, exampleWordPos: 16, relatedIds: []),
  QuranWord(id: 162, arabicWord: 'عَلِيم', transliteration: 'ʿalīm', meaningFr: 'Omniscient / Très Savant', root: 'ع-ل-م', moduleNumber: 1, frequency: 157, category: 'adjective', exampleSurah: 2, exampleVerse: 29, exampleWordPos: 8, relatedIds: [154, 163]),
  QuranWord(id: 163, arabicWord: 'عِلْم', transliteration: 'ʿilm', meaningFr: 'Science / savoir', root: 'ع-ل-م', moduleNumber: 1, frequency: 105, category: 'noun', exampleSurah: 2, exampleVerse: 32, exampleWordPos: 4, relatedIds: [154, 162]),
  QuranWord(id: 164, arabicWord: 'حَكِيم', transliteration: 'ḥakīm', meaningFr: 'Sage / Omniscient', root: 'ح-ك-م', moduleNumber: 1, frequency: 97, category: 'adjective', exampleSurah: 2, exampleVerse: 32, exampleWordPos: 7, relatedIds: []),
  QuranWord(id: 165, arabicWord: 'غَفُور', transliteration: 'ghafūr', meaningFr: 'Pardonneur / Très Indulgent', root: 'غ-ف-ر', moduleNumber: 1, frequency: 91, category: 'adjective', exampleSurah: 2, exampleVerse: 173, exampleWordPos: 9, relatedIds: [158]),
  QuranWord(id: 166, arabicWord: 'قَدِير', transliteration: 'qadīr', meaningFr: 'Tout-Puissant / Omnipotent', root: 'ق-د-ر', moduleNumber: 1, frequency: 45, category: 'adjective', exampleSurah: 2, exampleVerse: 20, exampleWordPos: 10, relatedIds: []),
  QuranWord(id: 167, arabicWord: 'حَسَن', transliteration: 'ḥasan', meaningFr: 'Bon / beau / excellent', root: 'ح-س-ن', moduleNumber: 1, frequency: 194, category: 'adjective', exampleSurah: 2, exampleVerse: 83, exampleWordPos: 6, relatedIds: []),
  QuranWord(id: 168, arabicWord: 'كَثِير', transliteration: 'kathīr', meaningFr: 'Nombreux / abondant', root: 'ك-ث-ر', moduleNumber: 1, frequency: 157, category: 'adjective', exampleSurah: 2, exampleVerse: 26, exampleWordPos: 14, relatedIds: []),

  // ── Mots supplémentaires module 1 (pour atteindre 50) ────────────────────
  QuranWord(id: 169, arabicWord: 'مُؤْمِن', transliteration: 'muʾmin', meaningFr: 'Croyant / fidèle', root: 'أ-م-ن', moduleNumber: 1, frequency: 120, category: 'noun', exampleSurah: 2, exampleVerse: 6, exampleWordPos: 4, relatedIds: [145, 155]),
  QuranWord(id: 170, arabicWord: 'كَافِر', transliteration: 'kāfir', meaningFr: 'Incroyant / ingrat', root: 'ك-ف-ر', moduleNumber: 1, frequency: 154, category: 'noun', exampleSurah: 2, exampleVerse: 6, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 171, arabicWord: 'صَادِق', transliteration: 'ṣādiq', meaningFr: 'Véridique / sincère', root: 'ص-د-ق', moduleNumber: 1, frequency: 47, category: 'adjective', exampleSurah: 2, exampleVerse: 23, exampleWordPos: 10, relatedIds: []),
  QuranWord(id: 172, arabicWord: 'عَمَل', transliteration: 'ʿamal', meaningFr: 'Acte / action / œuvre', root: 'ع-م-ل', moduleNumber: 1, frequency: 360, category: 'noun', exampleSurah: 2, exampleVerse: 25, exampleWordPos: 7, relatedIds: []),
  QuranWord(id: 173, arabicWord: 'نَبِيّ', transliteration: 'nabiyy', meaningFr: 'Prophète', root: 'ن-ب-أ', moduleNumber: 1, frequency: 75, category: 'noun', exampleSurah: 2, exampleVerse: 61, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 174, arabicWord: 'رَسُول', transliteration: 'rasūl', meaningFr: 'Messager / envoyé', root: 'ر-س-ل', moduleNumber: 1, frequency: 332, category: 'noun', exampleSurah: 2, exampleVerse: 87, exampleWordPos: 3, relatedIds: [160]),
  QuranWord(id: 175, arabicWord: 'مَلَك', transliteration: 'malak', meaningFr: 'Ange', root: 'م-ل-ك', moduleNumber: 1, frequency: 88, category: 'noun', exampleSurah: 2, exampleVerse: 30, exampleWordPos: 5, relatedIds: []),
  QuranWord(id: 176, arabicWord: 'جَنَّة', transliteration: 'janna', meaningFr: 'Jardin / Paradis', root: 'ج-ن-ن', moduleNumber: 1, frequency: 147, category: 'noun', exampleSurah: 2, exampleVerse: 25, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 177, arabicWord: 'نَار', transliteration: 'nār', meaningFr: 'Feu / Enfer', root: 'ن-و-ر', moduleNumber: 1, frequency: 145, category: 'noun', exampleSurah: 2, exampleVerse: 24, exampleWordPos: 3, relatedIds: []),
  QuranWord(id: 178, arabicWord: 'مَوْت', transliteration: 'mawt', meaningFr: 'Mort', root: 'م-و-ت', moduleNumber: 1, frequency: 72, category: 'noun', exampleSurah: 2, exampleVerse: 28, exampleWordPos: 4, relatedIds: []),
  QuranWord(id: 179, arabicWord: 'حَيَاة', transliteration: 'ḥayāt', meaningFr: 'Vie', root: 'ح-ي-ي', moduleNumber: 1, frequency: 76, category: 'noun', exampleSurah: 2, exampleVerse: 85, exampleWordPos: 8, relatedIds: [178]),
  QuranWord(id: 180, arabicWord: 'وَقْت', transliteration: 'waqt', meaningFr: 'Temps / moment', root: 'و-ق-ت', moduleNumber: 1, frequency: 54, category: 'noun', exampleSurah: 2, exampleVerse: 203, exampleWordPos: 3, relatedIds: [133]),
];

// ─────────────────────────────────────────────────────────────────────────────
// MODULE 2 — Les Particules Spatiales (prépositions de lieu)
// ─────────────────────────────────────────────────────────────────────────────
const List<QuranWord> kModule2Words = [
  QuranWord(id: 201, arabicWord: 'فَوْقَ', transliteration: 'fawqa', meaningFr: 'Au-dessus de', root: null, moduleNumber: 2, frequency: 19, category: 'particle', exampleSurah: 2, exampleVerse: 22, exampleWordPos: 2, relatedIds: [202]),
  QuranWord(id: 202, arabicWord: 'تَحْتَ', transliteration: 'taḥta', meaningFr: 'En dessous de / sous', root: null, moduleNumber: 2, frequency: 17, category: 'particle', exampleSurah: 9, exampleVerse: 100, exampleWordPos: 9, relatedIds: [201]),
  QuranWord(id: 203, arabicWord: 'أَمَامَ', transliteration: 'amāma', meaningFr: 'Devant / en face de', root: null, moduleNumber: 2, frequency: 5, category: 'particle', exampleSurah: 75, exampleVerse: 5, exampleWordPos: 2, relatedIds: [204]),
  QuranWord(id: 204, arabicWord: 'خَلْفَ', transliteration: 'khalfa', meaningFr: 'Derrière / après', root: null, moduleNumber: 2, frequency: 11, category: 'particle', exampleSurah: 2, exampleVerse: 255, exampleWordPos: 8, relatedIds: [203]),
  QuranWord(id: 205, arabicWord: 'بَيْنَ', transliteration: 'bayna', meaningFr: 'Entre / parmi', root: null, moduleNumber: 2, frequency: 110, category: 'particle', exampleSurah: 2, exampleVerse: 136, exampleWordPos: 6, relatedIds: []),
  QuranWord(id: 206, arabicWord: 'عِنْدَ', transliteration: 'ʿinda', meaningFr: 'Auprès de / chez', root: null, moduleNumber: 2, frequency: 171, category: 'particle', exampleSurah: 2, exampleVerse: 19, exampleWordPos: 8, relatedIds: []),
  QuranWord(id: 207, arabicWord: 'حَوْلَ', transliteration: 'ḥawla', meaningFr: 'Autour de', root: null, moduleNumber: 2, frequency: 17, category: 'particle', exampleSurah: 39, exampleVerse: 75, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 208, arabicWord: 'قَبْلَ', transliteration: 'qabla', meaningFr: 'Avant / précédemment', root: null, moduleNumber: 2, frequency: 100, category: 'particle', exampleSurah: 2, exampleVerse: 4, exampleWordPos: 6, relatedIds: [209]),
  QuranWord(id: 209, arabicWord: 'بَعْدَ', transliteration: 'baʿda', meaningFr: 'Après / ensuite', root: null, moduleNumber: 2, frequency: 95, category: 'particle', exampleSurah: 2, exampleVerse: 27, exampleWordPos: 4, relatedIds: [208]),
  QuranWord(id: 210, arabicWord: 'حَتَّى', transliteration: 'ḥattā', meaningFr: 'Jusqu\'à / afin que', root: null, moduleNumber: 2, frequency: 242, category: 'particle', exampleSurah: 2, exampleVerse: 55, exampleWordPos: 1, relatedIds: []),
  QuranWord(id: 211, arabicWord: 'إِلَى', transliteration: 'ilā', meaningFr: 'Vers / en direction de', root: null, moduleNumber: 2, frequency: 742, category: 'particle', exampleSurah: 1, exampleVerse: 6, exampleWordPos: 2, relatedIds: []),
  QuranWord(id: 212, arabicWord: 'مِنْ', transliteration: 'min', meaningFr: 'De / en provenance de', root: null, moduleNumber: 2, frequency: 2756, category: 'particle', exampleSurah: 1, exampleVerse: 7, exampleWordPos: 4, relatedIds: []),
];

// ─────────────────────────────────────────────────────────────────────────────
// MODULE 3 — Les Blocs de Sens (formules et expressions coraniques)
// ─────────────────────────────────────────────────────────────────────────────
const List<QuranChunk> kModule3Chunks = [
  QuranChunk(id: 301, arabicText: 'بِسْمِ اللَّهِ', meaningFr: 'Au nom de Dieu', context: 'Basmala (Al-Fatiha 1:1)', orderInVerse: 1),
  QuranChunk(id: 302, arabicText: 'الرَّحْمَنِ الرَّحِيمِ', meaningFr: 'Infiniment Miséricordieux, Très Miséricordieux', context: 'Basmala (Al-Fatiha 1:1)', orderInVerse: 2),
  QuranChunk(id: 303, arabicText: 'الْحَمْدُ لِلَّهِ', meaningFr: 'Louange à Dieu', context: 'Al-Fatiha 1:2 — formule de gratitude', orderInVerse: 1),
  QuranChunk(id: 304, arabicText: 'رَبِّ الْعَالَمِينَ', meaningFr: 'Seigneur des univers', context: 'Al-Fatiha 1:2', orderInVerse: 2),
  QuranChunk(id: 305, arabicText: 'إِيَّاكَ نَعْبُدُ', meaningFr: 'C\'est Toi seul que nous adorons', context: 'Al-Fatiha 1:5 — Engagement d\'adoration', orderInVerse: 1),
  QuranChunk(id: 306, arabicText: 'وَإِيَّاكَ نَسْتَعِينُ', meaningFr: 'Et c\'est Toi seul dont nous implorons l\'aide', context: 'Al-Fatiha 1:5', orderInVerse: 2),
  QuranChunk(id: 307, arabicText: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', meaningFr: 'Guide-nous sur le droit chemin', context: 'Al-Fatiha 1:6 — Supplication centrale', orderInVerse: 1),
  QuranChunk(id: 308, arabicText: 'لَا إِلَهَ إِلَّا اللَّه', meaningFr: 'Il n\'y a de divinité qu\'Allah', context: 'Shahada — Profession de foi', orderInVerse: 1),
  QuranChunk(id: 309, arabicText: 'مُحَمَّدٌ رَسُولُ اللَّه', meaningFr: 'Muhammad est le Messager d\'Allah', context: 'Shahada — 2ème partie', orderInVerse: 2),
  QuranChunk(id: 310, arabicText: 'إِنَّ اللَّهَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', meaningFr: 'Allah est certes Tout-Puissant sur toute chose', context: 'Expression récurrente (e.g. Al-Baqara 2:20)', orderInVerse: 1),
  QuranChunk(id: 311, arabicText: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً', meaningFr: 'Seigneur ! Accorde-nous du bien en ce monde', context: 'Du\'a Rabbanā (Al-Baqara 2:201)', orderInVerse: 1),
  QuranChunk(id: 312, arabicText: 'وَفِي الْآخِرَةِ حَسَنَةً', meaningFr: 'Et du bien dans l\'au-delà', context: 'Du\'a Rabbanā (Al-Baqara 2:201)', orderInVerse: 2),
  QuranChunk(id: 313, arabicText: 'وَقِنَا عَذَابَ النَّارِ', meaningFr: 'Et préserve-nous du châtiment du Feu', context: 'Du\'a Rabbanā (Al-Baqara 2:201)', orderInVerse: 3),
  QuranChunk(id: 314, arabicText: 'إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ', meaningFr: 'Nous appartenons à Allah et c\'est vers Lui que nous retournons', context: 'Istirja\' — Al-Baqara 2:156', orderInVerse: 1),
  QuranChunk(id: 315, arabicText: 'اللَّهُ أَكْبَرُ', meaningFr: 'Allah est le Plus Grand', context: 'Takbir — formule récurrente dans la prière', orderInVerse: 1),
];

// ─────────────────────────────────────────────────────────────────────────────
// MODULE 4 — L'ADN des Mots (racines et dérivations)
// ─────────────────────────────────────────────────────────────────────────────
const List<ArabicRoot> kModule4Roots = [
  ArabicRoot(
    root: 'ك-ت-ب',
    meaningFr: 'Écrire, inscrire, décréter',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'كَتَبَ', transliteration: 'kataba', meaningFr: 'Il écrivit', context: 'Al-Baqara 2:235'),
      RootDerivation(word: 'كِتَاب', transliteration: 'kitāb', meaningFr: 'Livre / écrit', context: 'Al-Baqara 2:2'),
      RootDerivation(word: 'مَكْتُوب', transliteration: 'maktūb', meaningFr: 'Écrit / prescrit', context: 'Al-Ahzab 33:6'),
      RootDerivation(word: 'كَاتِب', transliteration: 'kātib', meaningFr: 'Scribe / celui qui écrit', context: 'Al-Baqara 2:282'),
    ],
    intruder: RootDerivation(word: 'سَفَرَ', transliteration: 'safara', meaningFr: 'Il voyagea (racine س-ف-ر)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'ع-ل-م',
    meaningFr: 'Savoir, connaître, enseigner',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'عَلِمَ', transliteration: 'ʿalima', meaningFr: 'Il sut / connut', context: 'Al-Baqara 2:30'),
      RootDerivation(word: 'عِلْم', transliteration: 'ʿilm', meaningFr: 'Science / savoir', context: 'Al-Baqara 2:32'),
      RootDerivation(word: 'عَلِيم', transliteration: 'ʿalīm', meaningFr: 'Omniscient', context: 'Al-Baqara 2:29'),
      RootDerivation(word: 'مُعَلِّم', transliteration: 'muʿallim', meaningFr: 'Enseignant / maître', context: 'Usage courant'),
    ],
    intruder: RootDerivation(word: 'فَهِمَ', transliteration: 'fahima', meaningFr: 'Il comprit (racine ف-ه-م)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'ق-و-ل',
    meaningFr: 'Dire, parler, énoncer',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'قَالَ', transliteration: 'qāla', meaningFr: 'Il dit', context: 'Al-Baqara 2:30'),
      RootDerivation(word: 'قَوْل', transliteration: 'qawl', meaningFr: 'Parole / propos', context: 'Al-Baqara 2:235'),
      RootDerivation(word: 'يَقُول', transliteration: 'yaqūl', meaningFr: 'Il dit (présent)', context: 'Récurrent'),
      RootDerivation(word: 'مَقَال', transliteration: 'maqāl', meaningFr: 'Discours / article', context: 'Usage courant'),
    ],
    intruder: RootDerivation(word: 'سَمِعَ', transliteration: 'samiʿa', meaningFr: 'Il entendit (racine س-م-ع)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'خ-ل-ق',
    meaningFr: 'Créer, former, donner l\'existence',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'خَلَقَ', transliteration: 'khalaqa', meaningFr: 'Il créa', context: 'Al-\'Alaq 96:2'),
      RootDerivation(word: 'خَلْق', transliteration: 'khalq', meaningFr: 'Création', context: 'Al-Baqara 2:164'),
      RootDerivation(word: 'خَالِق', transliteration: 'khāliq', meaningFr: 'Créateur', context: 'Al-Ra\'d 13:16'),
      RootDerivation(word: 'مَخْلُوق', transliteration: 'makhlūq', meaningFr: 'Créature / ce qui est créé', context: 'Usage courant'),
    ],
    intruder: RootDerivation(word: 'رَزَقَ', transliteration: 'razaqa', meaningFr: 'Il pourvut (racine ر-ز-ق)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'ر-ح-م',
    meaningFr: 'Avoir de la miséricorde, être clément',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'رَحِمَ', transliteration: 'raḥima', meaningFr: 'Il fut miséricordieux', context: 'Al-A\'raf 7:151'),
      RootDerivation(word: 'رَحْمَة', transliteration: 'raḥma', meaningFr: 'Miséricorde', context: 'Al-Fatiha 1:1'),
      RootDerivation(word: 'رَحْمَان', transliteration: 'raḥmān', meaningFr: 'Infiniment Miséricordieux', context: 'Al-Fatiha 1:1'),
      RootDerivation(word: 'رَحِيم', transliteration: 'raḥīm', meaningFr: 'Très Miséricordieux', context: 'Al-Fatiha 1:1'),
    ],
    intruder: RootDerivation(word: 'كَرِيم', transliteration: 'karīm', meaningFr: 'Généreux (racine ك-ر-م)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'ه-د-ي',
    meaningFr: 'Guider, orienter sur la bonne voie',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'هَدَى', transliteration: 'hadā', meaningFr: 'Il guida', context: 'Al-Fatiha 1:6'),
      RootDerivation(word: 'هِدَايَة', transliteration: 'hidāya', meaningFr: 'Guidance / direction', context: 'Al-Baqara 2:2'),
      RootDerivation(word: 'هَادٍ', transliteration: 'hādī', meaningFr: 'Guide / celui qui oriente', context: 'Al-Ra\'d 13:7'),
      RootDerivation(word: 'هَدِيَّة', transliteration: 'hadiyya', meaningFr: 'Cadeau / don', context: 'Al-Naml 27:35'),
    ],
    intruder: RootDerivation(word: 'أَضَلَّ', transliteration: 'aḍalla', meaningFr: 'Il égara (racine ض-ل-ل)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'أ-م-ن',
    meaningFr: 'Croire, faire confiance, être en sécurité',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'آمَنَ', transliteration: 'āmana', meaningFr: 'Il crut', context: 'Al-Baqara 2:3'),
      RootDerivation(word: 'إِيمَان', transliteration: 'īmān', meaningFr: 'Foi / croyance', context: 'Al-Baqara 2:93'),
      RootDerivation(word: 'مُؤْمِن', transliteration: 'muʾmin', meaningFr: 'Croyant', context: 'Al-Baqara 2:6'),
      RootDerivation(word: 'أَمَان', transliteration: 'amān', meaningFr: 'Sécurité / protection', context: 'At-Tawbah 9:6'),
    ],
    intruder: RootDerivation(word: 'صَبَرَ', transliteration: 'ṣabara', meaningFr: 'Il patienta (racine ص-ب-ر)', context: 'Intrus'),
  ),
  ArabicRoot(
    root: 'س-ج-د',
    meaningFr: 'Se prosterner, se soumettre',
    moduleNumber: 4,
    derivations: [
      RootDerivation(word: 'سَجَدَ', transliteration: 'sajada', meaningFr: 'Il se prosterna', context: 'Al-Baqara 2:34'),
      RootDerivation(word: 'سُجُود', transliteration: 'sujūd', meaningFr: 'Prosternation', context: 'Al-Hajj 22:77'),
      RootDerivation(word: 'مَسْجِد', transliteration: 'masjid', meaningFr: 'Mosquée / lieu de prosternation', context: 'Al-Baqara 2:144'),
      RootDerivation(word: 'سَاجِد', transliteration: 'sājid', meaningFr: 'Celui qui se prosterne', context: 'Al-Zumar 39:9'),
    ],
    intruder: RootDerivation(word: 'رَكَعَ', transliteration: 'rakaʿa', meaningFr: 'Il s\'inclina (racine ر-ك-ع)', context: 'Intrus'),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MODULE 5 — Lecture Guidée (versets avec analyse mot par mot)
// ─────────────────────────────────────────────────────────────────────────────
/// Versets célèbres avec leur découpage pour l'exercice VerseScan
const List<Map<String, dynamic>> kModule5Verses = [
  {
    'surah': 1,
    'verse': 1,
    'name': 'Al-Fatiha — Basmala',
    'words': [
      {'ar': 'بِسْمِ', 'fr': 'Au nom de', 'known': true},
      {'ar': 'اللَّهِ', 'fr': 'Dieu (Allah)', 'known': true},
      {'ar': 'الرَّحْمَنِ', 'fr': 'Infiniment Miséricordieux', 'known': true},
      {'ar': 'الرَّحِيمِ', 'fr': 'Très Miséricordieux', 'known': true},
    ],
  },
  {
    'surah': 1,
    'verse': 2,
    'name': 'Al-Fatiha v.2',
    'words': [
      {'ar': 'الْحَمْدُ', 'fr': 'Louange / gloire', 'known': true},
      {'ar': 'لِلَّهِ', 'fr': 'à Dieu', 'known': true},
      {'ar': 'رَبِّ', 'fr': 'Seigneur de', 'known': true},
      {'ar': 'الْعَالَمِينَ', 'fr': 'tous les univers', 'known': false},
    ],
  },
  {
    'surah': 112,
    'verse': 1,
    'name': 'Al-Ikhlas v.1',
    'words': [
      {'ar': 'قُلْ', 'fr': 'Dis', 'known': true},
      {'ar': 'هُوَ', 'fr': 'Il est', 'known': true},
      {'ar': 'اللَّهُ', 'fr': 'Dieu', 'known': true},
      {'ar': 'أَحَدٌ', 'fr': 'Un / Unique', 'known': false},
    ],
  },
  {
    'surah': 2,
    'verse': 255,
    'name': 'Âyat al-Kursî',
    'words': [
      {'ar': 'اللَّهُ', 'fr': 'Dieu', 'known': true},
      {'ar': 'لَا', 'fr': 'il n\'y a pas', 'known': true},
      {'ar': 'إِلَهَ', 'fr': 'de divinité', 'known': false},
      {'ar': 'إِلَّا', 'fr': 'sauf / excepté', 'known': true},
      {'ar': 'هُوَ', 'fr': 'Lui', 'known': true},
      {'ar': 'الْحَيُّ', 'fr': 'le Vivant', 'known': false},
      {'ar': 'الْقَيُّومُ', 'fr': 'le Subsistant', 'known': false},
    ],
  },
  {
    'surah': 96,
    'verse': 1,
    'name': 'Al-\'Alaq v.1 — Premier révélé',
    'words': [
      {'ar': 'اقْرَأْ', 'fr': 'Lis !', 'known': false},
      {'ar': 'بِاسْمِ', 'fr': 'au nom de', 'known': true},
      {'ar': 'رَبِّكَ', 'fr': 'ton Seigneur', 'known': true},
      {'ar': 'الَّذِي', 'fr': 'Celui qui', 'known': false},
      {'ar': 'خَلَقَ', 'fr': 'créa', 'known': true},
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Accesseurs globaux
// ─────────────────────────────────────────────────────────────────────────────

/// Tous les mots du module 1 + 2 (pour flashcards)
List<QuranWord> get kAllWords => [...kModule1Words, ...kModule2Words];

/// Mots d'un module donné
List<QuranWord> wordsForModule(int moduleNumber) =>
    kAllWords.where((w) => w.moduleNumber == moduleNumber).toList();

/// Génère 3 distracteurs pour un mot (pour QCM)
/// Choisit des mots de la même catégorie dans le module, sauf le mot cible
List<QuranWord> distractorsFor(QuranWord target, {int count = 3}) {
  final pool = kAllWords
      .where((w) =>
          w.id != target.id &&
          w.meaningFr != target.meaningFr)
      .toList();
  pool.shuffle();
  return pool.take(count).toList();
}

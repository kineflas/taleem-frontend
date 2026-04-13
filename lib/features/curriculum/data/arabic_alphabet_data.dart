import 'package:flutter/material.dart';

/// Static data for the Arabic Alphabet learning module.
/// No backend dependency — pure constants used by intro, families, quiz.

// ── Introduction sections ────────────────────────────────────────────────────

class IntroSection {
  final String titleFr;
  final String contentFr;
  final IconData icon;
  const IntroSection({
    required this.titleFr,
    required this.contentFr,
    required this.icon,
  });
}

const List<IntroSection> alphabetIntroSections = [
  IntroSection(
    titleFr: '28 lettres, toutes des consonnes',
    contentFr:
        'L\'alphabet arabe comporte 28 lettres. Contrairement au français, '
        'ce sont toutes des consonnes. Les voyelles courtes (a, i, u) sont '
        'indiquées par de petits signes au-dessus ou en dessous des lettres, '
        'appelés « tashkeel » ou « harakat ».',
    icon: Icons.abc,
  ),
  IntroSection(
    titleFr: 'Une écriture de droite à gauche',
    contentFr:
        'L\'arabe s\'écrit et se lit de droite à gauche. Les livres arabes '
        's\'ouvrent donc par ce qui serait la dernière page en français. '
        'Les chiffres, en revanche, se lisent de gauche à droite.',
    icon: Icons.swap_horiz,
  ),
  IntroSection(
    titleFr: '4 formes selon la position',
    contentFr:
        'Chaque lettre change de forme selon sa position dans le mot :\n'
        '• Isolée — la lettre seule\n'
        '• Initiale — en début de mot\n'
        '• Médiane — au milieu du mot\n'
        '• Finale — en fin de mot\n\n'
        'Ne vous inquiétez pas : les formes se ressemblent beaucoup, '
        'seules les connexions changent.',
    icon: Icons.transform,
  ),
  IntroSection(
    titleFr: 'Les points font la différence',
    contentFr:
        'Beaucoup de lettres partagent la même forme de base et ne se '
        'distinguent que par le nombre et la position des points :\n'
        '• ب (1 point en bas) / ت (2 points en haut) / ث (3 points en haut)\n'
        '• ج (1 point en bas) / ح (sans point) / خ (1 point en haut)\n\n'
        'Apprendre ces « familles » de lettres similaires facilite '
        'grandement la mémorisation.',
    icon: Icons.fiber_manual_record,
  ),
  IntroSection(
    titleFr: 'Les lettres non-connectantes',
    contentFr:
        'Six lettres ne se connectent jamais à la lettre qui les suit '
        '(à gauche) : ا د ذ ر ز و\n\n'
        'Après l\'une de ces lettres, la suivante reprend sa forme isolée '
        'ou initiale. C\'est une règle simple mais importante pour '
        'l\'écriture fluide.',
    icon: Icons.link_off,
  ),
  IntroSection(
    titleFr: 'Conseils pour bien commencer',
    contentFr:
        '• Écoutez la prononciation de chaque lettre avant d\'essayer '
        'de la reproduire.\n'
        '• Concentrez-vous d\'abord sur la forme isolée, puis découvrez '
        'les autres positions.\n'
        '• Certains sons n\'existent pas en français (ع, ح, خ, ق...). '
        'Soyez patient et répétez souvent.\n'
        '• Entraînez-vous à reconnaître les familles de lettres similaires.',
    icon: Icons.tips_and_updates,
  ),
];

// ── Letter families (similar shapes, differ by dots) ─────────────────────────

class LetterFamily {
  final List<String> letters; // isolated glyphs
  final String descriptionFr;
  final Color color;
  const LetterFamily({
    required this.letters,
    required this.descriptionFr,
    required this.color,
  });
}

const List<LetterFamily> letterFamilies = [
  LetterFamily(
    letters: ['ب', 'ت', 'ث'],
    descriptionFr: 'Même forme, 1/2/3 points',
    color: Color(0xFF2196F3), // blue
  ),
  LetterFamily(
    letters: ['ج', 'ح', 'خ'],
    descriptionFr: 'Point en bas / sans / en haut',
    color: Color(0xFF4CAF50), // green
  ),
  LetterFamily(
    letters: ['د', 'ذ'],
    descriptionFr: 'Sans point / avec point',
    color: Color(0xFFFF9800), // orange
  ),
  LetterFamily(
    letters: ['ر', 'ز'],
    descriptionFr: 'Sans point / avec point',
    color: Color(0xFF9C27B0), // purple
  ),
  LetterFamily(
    letters: ['س', 'ش'],
    descriptionFr: 'Sans points / 3 points',
    color: Color(0xFFE91E63), // pink
  ),
  LetterFamily(
    letters: ['ص', 'ض'],
    descriptionFr: 'Sans point / avec point',
    color: Color(0xFF00BCD4), // cyan
  ),
  LetterFamily(
    letters: ['ط', 'ظ'],
    descriptionFr: 'Sans point / avec point',
    color: Color(0xFF795548), // brown
  ),
  LetterFamily(
    letters: ['ع', 'غ'],
    descriptionFr: 'Sans point / avec point',
    color: Color(0xFF607D8B), // blue-grey
  ),
  LetterFamily(
    letters: ['ف', 'ق'],
    descriptionFr: '1 point en haut / 2 points en haut',
    color: Color(0xFFFF5722), // deep orange
  ),
];

/// Map isolated glyph → family index (null if the letter is unique)
final Map<String, int> glyphToFamilyIndex = {
  for (int i = 0; i < letterFamilies.length; i++)
    for (final glyph in letterFamilies[i].letters) glyph: i,
};

// ── Non-connecting letters ───────────────────────────────────────────────────

const Set<String> nonConnectingLetters = {'ا', 'د', 'ذ', 'ر', 'ز', 'و'};

// ── Glyph → name mapping (for quiz choices) ─────────────────────────────────

const Map<String, String> glyphToName = {
  'ا': 'Alif',
  'ب': 'Ba',
  'ت': 'Ta',
  'ث': 'Tha',
  'ج': 'Jim',
  'ح': 'Ha',
  'خ': 'Kha',
  'د': 'Dal',
  'ذ': 'Dhal',
  'ر': 'Ra',
  'ز': 'Zay',
  'س': 'Sin',
  'ش': 'Shin',
  'ص': 'Sad',
  'ض': 'Dad',
  'ط': 'Ta emphatique',
  'ظ': 'Dha emphatique',
  'ع': 'Ayn',
  'غ': 'Ghayn',
  'ف': 'Fa',
  'ق': 'Qaf',
  'ك': 'Kaf',
  'ل': 'Lam',
  'م': 'Mim',
  'ن': 'Nun',
  'ه': 'Ha',
  'و': 'Waw',
  'ي': 'Ya',
};

/// All 28 letter names for quiz answer generation
final List<String> allLetterNames = glyphToName.values.toSet().toList();

// ── Glyph → exact audio filename (without .mp3) ──────────────────────────────
// Filenames verified against /static/audio/letters/ on the backend.
// Use this map everywhere instead of deriving from glyphToName.

const Map<String, String> glyphToAudioFilename = {
  'ا': 'alif',
  'ب': 'ba',
  'ت': 'taa',
  'ث': 'tha',
  'ج': 'jiim',
  'ح': 'hha',   // distinct from ه (ha)
  'خ': 'kha',
  'د': 'daal',
  'ذ': 'thaal',
  'ر': 'ra',
  'ز': 'zay',
  'س': 'siin',
  'ش': 'shiin',
  'ص': 'saad',
  'ض': 'daad',
  'ط': 'ta',     // emphatic T — file is 'ta.mp3'
  'ظ': 'thaa',   // emphatic Dh — file is 'thaa.mp3'
  'ع': 'ayn',
  'غ': 'ghayn',
  'ف': 'fa',
  'ق': 'qaf',
  'ك': 'kaf',
  'ل': 'lam',
  'م': 'miim',
  'ن': 'nuun',
  'ه': 'ha',
  'و': 'waw',
  'ي': 'ya',
};

// ── Pronunciation guide ────────────────────────────────────────────────────

enum PronunciationDifficulty { easy, medium, hard, expert }

class LetterPronunciation {
  final String letterName;
  final PronunciationDifficulty difficulty;
  final String categoryFr; // e.g. "Lettre familière", "Son de gorge"
  final String equivalentFr; // short summary: "Comme le B de Bateau"
  final String? equivalentLanguage; // e.g. "anglais", "espagnol"
  final String descriptionFr; // detailed explanation
  final String? astuceFr; // practical tip
  final String? erreurFr; // common mistake
  final String? paireFr; // minimal pair comparison
  final String? paireGlyph; // the paired letter glyph for comparison

  const LetterPronunciation({
    required this.letterName,
    required this.difficulty,
    required this.categoryFr,
    required this.equivalentFr,
    this.equivalentLanguage,
    required this.descriptionFr,
    this.astuceFr,
    this.erreurFr,
    this.paireFr,
    this.paireGlyph,
  });
}

const Map<String, LetterPronunciation> letterPronunciations = {
  // ── 1. Lettres familières ──────────────────────────────────────────────

  'ا': LetterPronunciation(
    letterName: 'Alif',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Semi-voyelle',
    equivalentFr: 'Support de voyelle ou A long',
    descriptionFr:
        'L\'Alif ne produit pas de son consonantique propre. Il sert de '
        'support pour les voyelles ou marque un A long, comme dans « pâte ».',
    astuceFr:
        'L\'Alif porte aussi le hamza (ء), le petit coup de glotte qu\'on '
        'entend entre les deux voyelles de « co-opérer ».',
  ),

  'ب': LetterPronunciation(
    letterName: 'Ba',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le B français',
    descriptionFr:
        'Identique au B de « Bateau », « Bébé ». Aucune difficulté.',
  ),

  'ت': LetterPronunciation(
    letterName: 'Ta',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le T français',
    descriptionFr:
        'Identique au T de « Table ». En arabe, le T est dental : '
        'la langue touche les dents, pas le palais.',
    astuceFr:
        'Ne pas confondre avec le ط (Ta emphatique) qui est plus '
        'lourd et grave.',
    paireFr: 'ت (léger) ↔ ط (lourd)',
    paireGlyph: 'ط',
  ),

  'ث': LetterPronunciation(
    letterName: 'Tha',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Langue entre les dents',
    equivalentFr: 'Comme le TH anglais de « Think »',
    equivalentLanguage: 'anglais',
    descriptionFr:
        'Placez le bout de la langue entre les incisives supérieures '
        'et inférieures, puis soufflez doucement. C\'est le TH sourd anglais '
        'comme dans « three », « think », « math ». La langue dépasse '
        'légèrement — vous devez pouvoir la voir dans un miroir.',
    astuceFr:
        'Posez vos doigts sur votre gorge : vous ne devez sentir '
        'aucune vibration (contrairement au ذ). Si ça vibre, c\'est '
        'que vous prononcez un ذ. Pensez à un « zézaiement » contrôlé.',
    erreurFr:
        'Ne pas replier la langue derrière les dents (ça donnerait '
        'un س ou un ت). La langue doit rester visible entre les dents.',
    paireFr: 'ث (sourd, « think ») ↔ ذ (sonore, « this »)',
    paireGlyph: 'ذ',
  ),

  'ج': LetterPronunciation(
    letterName: 'Jim',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Son DJ',
    equivalentFr: 'Comme DJ dans « Djebel »',
    descriptionFr:
        'Proche du DJ de « Django », « Adjoint », « Djibouti ». Le milieu '
        'de la langue touche le palais dur et produit un son qui commence '
        'par un D suivi d\'un J. C\'est « dj » (comme « judge » en anglais), '
        'et non le J doux français de « Jour ».',
    astuceFr:
        'Dites le mot anglais « juice » ou « jump » : le J anglais est '
        'exactement le ج arabe. Si vous n\'avez que le J français en tête, '
        'essayez d\'ajouter un mini D devant : « d-jebel », « d-jardin ».',
    erreurFr:
        'Ne pas prononcer comme un simple J français (« Jour ») ni comme '
        'un G dur (« Garage »). Le ج commence toujours par un léger D.',
  ),

  'ح': LetterPronunciation(
    letterName: 'Ha profond',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Son de gorge',
    equivalentFr: 'H très appuyé, plus profond que le ه',
    descriptionFr:
        'Le son vient du milieu de la gorge (pharynx). Imaginez que '
        'vous expirez très fort par temps glacial, ou que vous soufflez '
        'sur vos lunettes pour les nettoyer — mais beaucoup plus fort. '
        'Les parois de la gorge se rapprochent sans se toucher, créant '
        'un passage étroit pour l\'air. C\'est un son « sans voix » : '
        'aucune vibration des cordes vocales.',
    astuceFr:
        'Mettez votre main devant la bouche : vous devez sentir un '
        'souffle chaud et puissant. Si vous ne sentez rien, vous faites '
        'un ه (trop léger). Le ح est un effort, le ه est un murmure. '
        'Exercice : dites « Haaa » en soufflant comme si vous essuyiez '
        'un miroir, puis poussez le son plus profond dans la gorge.',
    erreurFr:
        'Ne pas confondre avec le خ (Kha). Le ح est un souffle pur, '
        'sans aucun frottement ni raclement. Et ne pas le remplacer '
        'par un simple H léger (ه).',
    paireFr: 'ح (souffle profond, pur) ↔ ه (souffle léger, glottal)',
    paireGlyph: 'ه',
  ),

  'خ': LetterPronunciation(
    letterName: 'Kha',
    difficulty: PronunciationDifficulty.hard,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Comme la Jota espagnole (« Juan »)',
    equivalentLanguage: 'espagnol / allemand',
    descriptionFr:
        'Un frottement sec au fond de la bouche : l\'arrière de la langue '
        'se rapproche du voile du palais (ou de la luette) et l\'air frotte '
        'en passant. Comme le J espagnol de « Juan », « jamón », ou '
        'le « ch » allemand de « Bach », « Achtung ».',
    astuceFr:
        'Commencez par prononcer un K, puis relâchez la langue pour '
        'laisser l\'air frotter au lieu de claquer. Pensez au bruit '
        'd\'un chat qui crache ou au raclement de gorge léger quand '
        'on a une arête de poisson coincée.',
    erreurFr:
        'Ne pas confondre avec le غ (Ghayn = R français). Le خ est '
        'sourd (sans vibration), le غ est sonore (avec vibration). '
        'Posez les doigts sur la gorge pour vérifier.',
    paireFr: 'خ (sourd, sec) ↔ غ (sonore, R français)',
    paireGlyph: 'غ',
  ),

  'د': LetterPronunciation(
    letterName: 'Dal',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le D français',
    descriptionFr:
        'Identique au D de « Dimanche ». En arabe, le D est dental : '
        'la langue touche les dents du haut.',
    paireFr: 'د (léger) ↔ ض (lourd, emphatique)',
    paireGlyph: 'ض',
  ),

  'ذ': LetterPronunciation(
    letterName: 'Dhal',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Langue entre les dents',
    equivalentFr: 'Comme le TH anglais de « This »',
    equivalentLanguage: 'anglais',
    descriptionFr:
        'Même position que le ث (langue entre les dents) mais en version '
        'sonore : les cordes vocales vibrent. Comme le TH anglais de '
        '« This », « That », « The », « Mother ». La langue dépasse '
        'légèrement entre les dents et l\'air passe en faisant vibrer.',
    astuceFr:
        'La différence entre ث et ذ est la même qu\'entre S et Z, ou '
        'entre F et V : même position de bouche, mais l\'un vibre, '
        'l\'autre pas. Posez les doigts sur votre gorge : le ذ fait '
        'vibrer, le ث non. Alternez : « tha - dha - tha - dha ».',
    erreurFr:
        'Ne pas prononcer comme un Z ou un D. La langue doit rester '
        'visible entre les dents.',
    paireFr: 'ث (sourd, « think ») ↔ ذ (sonore, « this »)',
    paireGlyph: 'ث',
  ),

  'ر': LetterPronunciation(
    letterName: 'Ra',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'R roulé',
    equivalentFr: 'R roulé espagnol / italien',
    equivalentLanguage: 'espagnol / italien',
    descriptionFr:
        'Un R roulé avec la pointe de la langue, comme le R espagnol '
        'de « Ramos », « perro », le R italien de « Roma », ou le R roulé '
        'des régions du sud de la France. La pointe de la langue vibre '
        'rapidement contre la crête alvéolaire (le petit bourrelet juste '
        'derrière les dents du haut).',
    astuceFr:
        'Entraînez-vous en répétant rapidement « d-d-d-d-d » de plus en '
        'plus vite : à un moment, la langue commencera à vibrer toute seule. '
        'Autre exercice : dites « butter » (anglais américain) — le « tt » '
        'rapide est un mini-roulement, essayez de l\'allonger.',
    erreurFr:
        'Ne jamais utiliser le R guttural parisien (celui du fond de la '
        'gorge). En arabe, ce son-là correspond au غ (Ghayn). Le ر arabe '
        'est TOUJOURS un son de la pointe de la langue.',
    paireFr: 'ر (pointe de langue, roulé) ↔ غ (fond de gorge, R français)',
    paireGlyph: 'غ',
  ),

  'ز': LetterPronunciation(
    letterName: 'Zay',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Son Z',
    equivalentFr: 'Comme le Z français',
    descriptionFr:
        'Identique au Z de « Zèbre », « Zoo ». Aucune difficulté.',
  ),

  'س': LetterPronunciation(
    letterName: 'Sin',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Son S',
    equivalentFr: 'Comme le S français',
    descriptionFr:
        'Identique au S de « Soleil », « Serpent ». Un S sourd et léger.',
    paireFr: 'س (léger) ↔ ص (lourd, emphatique)',
    paireGlyph: 'ص',
  ),

  'ش': LetterPronunciation(
    letterName: 'Shin',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Son CH',
    equivalentFr: 'Comme le CH français',
    descriptionFr:
        'Identique au CH de « Chat », « Chien ». Aucune difficulté.',
  ),

  'ص': LetterPronunciation(
    letterName: 'Sad',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'S lourd et grave (version emphatique de س)',
    descriptionFr:
        'Un S grave et profond. Le dos de la langue se soulève vers le '
        'palais (c\'est l\'« emphase »), les lèvres s\'arrondissent '
        'légèrement, et la cavité buccale s\'élargit. Le S qui en sort '
        'est plus bas, plus creux, plus « sombre » — comme un écho.',
    astuceFr:
        'Comparez « si » (léger, avec س) et « so » (lourd, arrondi, '
        'avec ص). Les emphatiques « assombrissent » les voyelles autour '
        'd\'elles : un « a » à côté d\'un ص sonne presque comme un « o ». '
        'Exercice : dites « sa - ṣa - sa - ṣa » en alternant. Le ص '
        'donne une résonance dans la poitrine.',
    erreurFr:
        'Ne pas prononcer comme un simple S. L\'emphase doit se sentir : '
        'la voix devient plus grave et la bouche plus ouverte.',
    paireFr: 'س (léger, « si ») ↔ ص (lourd, « so »)',
    paireGlyph: 'س',
  ),

  'ض': LetterPronunciation(
    letterName: 'Dad',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'D lourd (version emphatique de د)',
    descriptionFr:
        'Un D lourd et grave, considéré comme le son le plus caractéristique '
        'de l\'arabe — d\'où le surnom « la langue du ض ». Les bords latéraux '
        'de la langue appuient contre les molaires supérieures, le dos de la '
        'langue se soulève vers le palais, et les lèvres s\'arrondissent.',
    astuceFr:
        'Technique : appuyez le milieu de la langue contre le palais, '
        'arrondissez les lèvres, puis prononcez un D. Alternez : '
        '« da - ḍa - da - ḍa » pour entraîner votre oreille. Le ض '
        'résonne plus profondément dans la bouche et la poitrine.',
    erreurFr:
        'Ne pas prononcer comme un D normal ou un Z. Le ض est un D '
        'emphatique : la résonance doit être plus grave et « creuse ».',
    paireFr: 'د (léger, en avant) ↔ ض (lourd, emphatique)',
    paireGlyph: 'د',
  ),

  'ط': LetterPronunciation(
    letterName: 'Ta emphatique',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'T lourd et sec (version emphatique de ت)',
    descriptionFr:
        'Un T lourd et sec. La langue claque contre le palais avec plus '
        'de masse et de résonance. Le dos de la langue se soulève vers le '
        'palais (emphase), les lèvres s\'arrondissent, et le son qui sort '
        'est plus grave, plus « plein », comme un coup sourd.',
    astuceFr:
        'Alternez « ta - ṭa - ta - ṭa » pour bien sentir la différence. '
        'Le ط donne une impression de son « creux » et résonant, comme si '
        'vous parliez dans un tube. Observez aussi l\'effet sur les voyelles : '
        'le « a » après un ط sonne presque comme un « o ».',
    erreurFr:
        'Ne pas confondre avec un simple T (ت). Le ط est toujours plus '
        'grave, avec une résonance supplémentaire dans la cavité buccale.',
    paireFr: 'ت (léger, clair) ↔ ط (lourd, sombre)',
    paireGlyph: 'ت',
  ),

  'ظ': LetterPronunciation(
    letterName: 'Dha emphatique',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'TH lourd (version emphatique de ذ)',
    descriptionFr:
        'Un TH sonore lourd. La langue dépasse entre les dents (comme '
        'pour le ذ), mais en même temps le dos de la langue se soulève '
        'vers le palais et les lèvres s\'arrondissent — l\'emphase '
        'assombrit et alourdit le son considérablement.',
    astuceFr:
        'Pensez à un ذ (« this » en anglais) mais prononcé avec une '
        'voix plus grave, les lèvres arrondies, et la gorge plus ouverte. '
        'Alternez : « dha - ẓa - dha - ẓa » pour sentir l\'emphase.',
    erreurFr:
        'Ne pas replier la langue derrière les dents (ça donnerait un ض). '
        'La langue doit rester visible entre les incisives, comme pour le ذ.',
    paireFr: 'ذ (léger, clair) ↔ ظ (lourd, emphatique)',
    paireGlyph: 'ذ',
  ),

  'ع': LetterPronunciation(
    letterName: 'Ayn',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Aucun équivalent européen',
    descriptionFr:
        'LE son le plus difficile pour les francophones. C\'est une '
        'contraction musculaire active de la gorge : le pharynx (les '
        'muscles au fond de la gorge) se resserre comme un poing, '
        'comprimant le passage de l\'air. C\'est la version sonore '
        '(avec vibration) du ح.',
    astuceFr:
        'Imaginez le son réflexe quand on soulève un objet très lourd '
        '(« Aaargh ! »), ou une exclamation de surprise douloureuse qui '
        'vient du ventre. Exercice : dites « aaa » normalement, puis '
        'serrez votre gorge au milieu du son — le moment où ça se '
        'resserre et que le son devient « étranglé », c\'est le ع. '
        'Autre image : le bruit du bébé qui pleure (le « Waa ! » guttural).',
    erreurFr:
        'Ne pas remplacer par un simple A ou par un coup de glotte (ء). '
        'Le ع demande un vrai effort musculaire continu de la gorge, '
        'pas juste un blocage bref.',
    paireFr: 'ع (contraction sonore) ↔ ح (souffle sourd)',
    paireGlyph: 'ح',
  ),

  'غ': LetterPronunciation(
    letterName: 'Ghayn',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Le R grasseyé français !',
    descriptionFr:
        'Bonne nouvelle : c\'est le son le plus facile de cette catégorie '
        'pour un francophone ! C\'est votre R quotidien : le R de « Rat », '
        '« Rien », « Paris ». L\'arrière de la langue frotte contre la '
        'luette, créant ce frottement sonore caractéristique.',
    astuceFr:
        'Prononcez « garage » en français : le R que vous faites, c\'est '
        'exactement le غ arabe. En arabe, le R (ر) est roulé (espagnol), '
        'donc le غ occupe la niche du R français. Vous avez un avantage '
        'considérable sur les anglophones : ce son est natif pour vous !',
    erreurFr:
        'Ne pas confondre avec le خ (Kha) qui est sourd (sans vibration). '
        'Le غ vibre (comme le R de « garage »), le خ ne vibre pas '
        '(comme la jota espagnole).',
    paireFr: 'غ (sonore, R français) ↔ خ (sourd, jota espagnole)',
    paireGlyph: 'خ',
  ),

  'ف': LetterPronunciation(
    letterName: 'Fa',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le F français',
    descriptionFr:
        'Identique au F de « Fleur », « France ». Aucune difficulté.',
  ),

  'ق': LetterPronunciation(
    letterName: 'Qaf',
    difficulty: PronunciationDifficulty.hard,
    categoryFr: 'K profond',
    equivalentFr: 'Un K prononcé au niveau de la luette',
    descriptionFr:
        'Un K articulé très en arrière : l\'extrême arrière de la langue '
        'touche la luette (pas le voile du palais comme pour le ك). Le son '
        'est plus « creux », plus profond, et résonne dans la gorge — '
        'comme le croassement d\'un corbeau ou le bruit d\'un bouchon.',
    astuceFr:
        'Dites un K normal, puis reculez progressivement le point de '
        'contact de la langue vers l\'arrière de la bouche, jusqu\'à '
        'toucher la luette. Alternez : « ka - qa - ka - qa ». Le ق '
        'est plus sec et plus percutant que le ك. Dans certains dialectes, '
        'le ق se prononce comme un coup de glotte (ء) — mais en arabe '
        'classique, c\'est bien un K uvulaire.',
    erreurFr:
        'Ne pas confondre avec le ك (simple K). Le ق est plus en arrière, '
        'plus profond, et plus « percutant ».',
    paireFr: 'ك (léger, palais) ↔ ق (profond, luette)',
    paireGlyph: 'ك',
  ),

  'ك': LetterPronunciation(
    letterName: 'Kaf',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le K français',
    descriptionFr:
        'Identique au K de « Kilo », « Karaté ». Aucune difficulté.',
    paireFr: 'ك (léger) ↔ ق (lourd, profond)',
    paireGlyph: 'ق',
  ),

  'ل': LetterPronunciation(
    letterName: 'Lam',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le L français',
    descriptionFr:
        'Identique au L de « Lune », « Lumière ». Aucune difficulté.',
  ),

  'م': LetterPronunciation(
    letterName: 'Mim',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le M français',
    descriptionFr:
        'Identique au M de « Maman », « Maison ». Aucune difficulté.',
  ),

  'ن': LetterPronunciation(
    letterName: 'Nun',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le N français',
    descriptionFr:
        'Identique au N de « Nuage », « Nature ». Aucune difficulté.',
  ),

  'ه': LetterPronunciation(
    letterName: 'Ha',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'H aspiré',
    equivalentFr: 'Comme le H anglais de « Hello »',
    equivalentLanguage: 'anglais',
    descriptionFr:
        'Un souffle léger qui vient de la glotte (le tout fond de la gorge), '
        'comme le H anglais de « Hello », « House », « Happy ». Ou comme '
        'quand on fait de la buée sur une vitre, ou qu\'on souffle '
        'doucement pour réchauffer ses mains en hiver.',
    astuceFr:
        'Les francophones ont tendance à ne pas le prononcer du tout '
        '(car le H est muet en français). Il faut s\'entraîner à bien '
        'le souffler à chaque fois. Exercice : mettez votre main devant '
        'la bouche et dites « ha, hi, hou » — vous devez sentir le '
        'souffle. Si vous ne sentez rien, vous oubliez le ه.',
    erreurFr:
        'Ne pas confondre avec le ح (Ha profond) qui est beaucoup plus '
        'appuyé et vient de plus profond dans la gorge. Le ه est un '
        'murmure, le ح est un effort.',
    paireFr: 'ه (souffle léger, glottal) ↔ ح (souffle profond, pharyngal)',
    paireGlyph: 'ح',
  ),

  'و': LetterPronunciation(
    letterName: 'Waw',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Semi-voyelle',
    equivalentFr: 'Comme le W ou OU français',
    descriptionFr:
        'Comme le W de « Week-end » (anglais) ou le OU de « Oui ». '
        'Peut aussi servir de voyelle longue « OU ».',
  ),

  'ي': LetterPronunciation(
    letterName: 'Ya',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Semi-voyelle',
    equivalentFr: 'Comme le Y ou I français',
    descriptionFr:
        'Comme le Y de « Yoga » ou le I de « Ici ». Peut aussi servir '
        'de voyelle longue « I ».',
  ),

  'ء': LetterPronunciation(
    letterName: 'Hamza',
    difficulty: PronunciationDifficulty.hard,
    categoryFr: 'Coup de glotte',
    equivalentFr: 'Petit blocage au fond de la gorge',
    descriptionFr:
        'Un arrêt brusque et instantané du flux d\'air au niveau de la '
        'glotte (les cordes vocales se ferment brièvement puis se '
        'rouvrent). C\'est le son qu\'on entend entre les deux voyelles '
        'de « co-opérer », « Hawaï-ien », ou l\'attaque du « oh-oh ! » '
        'quand on réalise une erreur.',
    astuceFr:
        'Dites « uh-oh » en anglais : le petit « clic » silencieux entre '
        'les deux syllabes, c\'est le hamza. En français, on le fait '
        'naturellement entre deux voyelles consécutives, mais en arabe '
        'il est une vraie consonne à part entière qu\'il faut marquer '
        'clairement.',
    erreurFr:
        'Ne pas confondre avec le ع (Ayn) qui est un resserrement '
        'musculaire prolongé de la gorge. Le ء est un blocage bref et '
        'instantané, le ع est un effort continu.',
    paireFr: 'ء (blocage bref, glottal) ↔ ع (effort continu, pharyngal)',
    paireGlyph: 'ع',
  ),
};

// ── Word examples with target letter highlighted ──────────────────────────────

class WordExample {
  final String before; // text before the highlighted letter (can be empty)
  final String highlight; // the letter form as it appears in this word
  final String after; // text after (can be empty)
  final String translitFr; // romanization e.g. "bayt"
  final String meaningFr; // French meaning e.g. "maison"

  const WordExample({
    required this.before,
    required this.highlight,
    required this.after,
    required this.translitFr,
    required this.meaningFr,
  });
}

// ── Letter mnemonics (memory hooks) ─────────────────────────────────────────

class LetterMnemonic {
  final String hookFr; // the memory hook sentence in plain French
  final String? imageFr; // optional description of a mental image

  const LetterMnemonic({
    required this.hookFr,
    this.imageFr,
  });
}

// ── Word examples for each letter ───────────────────────────────────────────

const Map<String, List<WordExample>> letterWordExamples = {
  'ا': [
    WordExample(
      before: '',
      highlight: 'أَ',
      after: 'سَد',
      translitFr: 'asad',
      meaningFr: 'lion',
    ),
    WordExample(
      before: 'بَ',
      highlight: 'ا',
      after: 'ب',
      translitFr: 'bāb',
      meaningFr: 'porte',
    ),
    WordExample(
      before: 'سَمَ',
      highlight: 'ا',
      after: 'ء',
      translitFr: 'samāʾ',
      meaningFr: 'ciel',
    ),
  ],
  'ب': [
    WordExample(
      before: '',
      highlight: 'بَ',
      after: 'يْت',
      translitFr: 'bayt',
      meaningFr: 'maison',
    ),
    WordExample(
      before: '',
      highlight: 'بَ',
      after: 'اب',
      translitFr: 'bāb',
      meaningFr: 'porte',
    ),
    WordExample(
      before: 'كِتَا',
      highlight: 'ب',
      after: '',
      translitFr: 'kitāb',
      meaningFr: 'livre',
    ),
  ],
  'ت': [
    WordExample(
      before: '',
      highlight: 'تُ',
      after: 'فَّاحَة',
      translitFr: 'tuffāḥa',
      meaningFr: 'pomme',
    ),
    WordExample(
      before: 'بَيْ',
      highlight: 'ت',
      after: '',
      translitFr: 'bayt',
      meaningFr: 'maison',
    ),
    WordExample(
      before: '',
      highlight: 'تَ',
      after: 'مْر',
      translitFr: 'tamr',
      meaningFr: 'dattes',
    ),
  ],
  'ث': [
    WordExample(
      before: '',
      highlight: 'ثَ',
      after: 'لْج',
      translitFr: 'thalj',
      meaningFr: 'neige',
    ),
    WordExample(
      before: '',
      highlight: 'ثَ',
      after: 'لَاثَة',
      translitFr: 'thalātha',
      meaningFr: 'trois',
    ),
    WordExample(
      before: '',
      highlight: 'ثَ',
      after: 'عْلَب',
      translitFr: 'thaʿlab',
      meaningFr: 'renard',
    ),
  ],
  'ج': [
    WordExample(
      before: '',
      highlight: 'جَ',
      after: 'مَل',
      translitFr: 'jamal',
      meaningFr: 'chameau',
    ),
    WordExample(
      before: 'نَ',
      highlight: 'جْ',
      after: 'مَة',
      translitFr: 'najma',
      meaningFr: 'étoile',
    ),
    WordExample(
      before: '',
      highlight: 'جِ',
      after: 'دَار',
      translitFr: 'jidār',
      meaningFr: 'mur',
    ),
  ],
  'ح': [
    WordExample(
      before: '',
      highlight: 'حِ',
      after: 'مَار',
      translitFr: 'ḥimār',
      meaningFr: 'âne',
    ),
    WordExample(
      before: 'بَ',
      highlight: 'حْ',
      after: 'ر',
      translitFr: 'baḥr',
      meaningFr: 'mer',
    ),
    WordExample(
      before: 'مِفْتَا',
      highlight: 'ح',
      after: '',
      translitFr: 'miftāḥ',
      meaningFr: 'clé',
    ),
  ],
  'خ': [
    WordExample(
      before: '',
      highlight: 'خُ',
      after: 'بْز',
      translitFr: 'khubz',
      meaningFr: 'pain',
    ),
    WordExample(
      before: '',
      highlight: 'خَ',
      after: 'يْل',
      translitFr: 'khayl',
      meaningFr: 'chevaux',
    ),
    WordExample(
      before: '',
      highlight: 'خَ',
      after: 'رُوف',
      translitFr: 'kharūf',
      meaningFr: 'mouton',
    ),
  ],
  'د': [
    WordExample(
      before: '',
      highlight: 'دَ',
      after: 'رَجَة',
      translitFr: 'daraja',
      meaningFr: 'degré',
    ),
    WordExample(
      before: 'وَلَ',
      highlight: 'د',
      after: '',
      translitFr: 'walad',
      meaningFr: 'enfant',
    ),
    WordExample(
      before: '',
      highlight: 'دَ',
      after: 'ار',
      translitFr: 'dār',
      meaningFr: 'demeure',
    ),
  ],
  'ذ': [
    WordExample(
      before: '',
      highlight: 'ذِ',
      after: 'ئْب',
      translitFr: 'dhiʾb',
      meaningFr: 'loup',
    ),
    WordExample(
      before: '',
      highlight: 'ذَ',
      after: 'هَب',
      translitFr: 'dhahab',
      meaningFr: 'or',
    ),
    WordExample(
      before: 'هَ',
      highlight: 'ذَ',
      after: 'ا',
      translitFr: 'hādhā',
      meaningFr: 'celui-ci',
    ),
  ],
  'ر': [
    WordExample(
      before: '',
      highlight: 'رَ',
      after: 'جُل',
      translitFr: 'rajul',
      meaningFr: 'homme',
    ),
    WordExample(
      before: 'نَهْ',
      highlight: 'ر',
      after: '',
      translitFr: 'nahr',
      meaningFr: 'fleuve',
    ),
    WordExample(
      before: 'أَ',
      highlight: 'رْ',
      after: 'ض',
      translitFr: 'arḍ',
      meaningFr: 'terre',
    ),
  ],
  'ز': [
    WordExample(
      before: '',
      highlight: 'زَ',
      after: 'هْرَة',
      translitFr: 'zahra',
      meaningFr: 'fleur',
    ),
    WordExample(
      before: '',
      highlight: 'زَ',
      after: 'يْت',
      translitFr: 'zayt',
      meaningFr: 'huile',
    ),
    WordExample(
      before: 'مَنْ',
      highlight: 'زِ',
      after: 'ل',
      translitFr: 'manzil',
      meaningFr: 'maison',
    ),
  ],
  'س': [
    WordExample(
      before: '',
      highlight: 'سَ',
      after: 'مَاء',
      translitFr: 'samāʾ',
      meaningFr: 'ciel',
    ),
    WordExample(
      before: 'شَمْ',
      highlight: 'س',
      after: '',
      translitFr: 'shams',
      meaningFr: 'soleil',
    ),
    WordExample(
      before: '',
      highlight: 'سَ',
      after: 'مَكَة',
      translitFr: 'samaka',
      meaningFr: 'poisson',
    ),
  ],
  'ش': [
    WordExample(
      before: '',
      highlight: 'شَ',
      after: 'مْس',
      translitFr: 'shams',
      meaningFr: 'soleil',
    ),
    WordExample(
      before: '',
      highlight: 'شَ',
      after: 'جَرَة',
      translitFr: 'shajara',
      meaningFr: 'arbre',
    ),
    WordExample(
      before: 'عَرْ',
      highlight: 'ش',
      after: '',
      translitFr: 'arsh',
      meaningFr: 'trône',
    ),
  ],
  'ص': [
    WordExample(
      before: '',
      highlight: 'صَ',
      after: 'بَاح',
      translitFr: 'ṣabāḥ',
      meaningFr: 'matin',
    ),
    WordExample(
      before: '',
      highlight: 'صَ',
      after: 'لَاة',
      translitFr: 'ṣalāh',
      meaningFr: 'prière',
    ),
    WordExample(
      before: 'قَ',
      highlight: 'صْ',
      after: 'ر',
      translitFr: 'qaṣr',
      meaningFr: 'château',
    ),
  ],
  'ض': [
    WordExample(
      before: '',
      highlight: 'ضَ',
      after: 'وْء',
      translitFr: 'ḍawʾ',
      meaningFr: 'lumière',
    ),
    WordExample(
      before: 'رَمَ',
      highlight: 'ضَ',
      after: 'ان',
      translitFr: 'ramaḍān',
      meaningFr: 'ramadan',
    ),
    WordExample(
      before: 'أَرْ',
      highlight: 'ض',
      after: '',
      translitFr: 'arḍ',
      meaningFr: 'terre',
    ),
  ],
  'ط': [
    WordExample(
      before: '',
      highlight: 'طَ',
      after: 'يْر',
      translitFr: 'ṭayr',
      meaningFr: 'oiseau',
    ),
    WordExample(
      before: '',
      highlight: 'طَ',
      after: 'رِيق',
      translitFr: 'ṭarīq',
      meaningFr: 'chemin',
    ),
    WordExample(
      before: 'بَ',
      highlight: 'طْ',
      after: 'ل',
      translitFr: 'baṭl',
      meaningFr: 'héros',
    ),
  ],
  'ظ': [
    WordExample(
      before: '',
      highlight: 'ظِ',
      after: 'لّ',
      translitFr: 'ẓill',
      meaningFr: 'ombre',
    ),
    WordExample(
      before: 'نَ',
      highlight: 'ظَ',
      after: 'ر',
      translitFr: 'naẓar',
      meaningFr: 'regard',
    ),
    WordExample(
      before: 'حَ',
      highlight: 'ظّ',
      after: '',
      translitFr: 'ḥaẓẓ',
      meaningFr: 'chance',
    ),
  ],
  'ع': [
    WordExample(
      before: '',
      highlight: 'عَ',
      after: 'يْن',
      translitFr: 'ʿayn',
      meaningFr: 'œil',
    ),
    WordExample(
      before: '',
      highlight: 'عِ',
      after: 'لْم',
      translitFr: 'ʿilm',
      meaningFr: 'savoir',
    ),
    WordExample(
      before: '',
      highlight: 'عَ',
      after: 'رَب',
      translitFr: 'ʿarab',
      meaningFr: 'arabe',
    ),
  ],
  'غ': [
    WordExample(
      before: '',
      highlight: 'غَ',
      after: 'يْم',
      translitFr: 'ghaym',
      meaningFr: 'nuage',
    ),
    WordExample(
      before: '',
      highlight: 'غَ',
      after: 'ابَة',
      translitFr: 'ghāba',
      meaningFr: 'forêt',
    ),
    WordExample(
      before: '',
      highlight: 'غُ',
      after: 'رْفَة',
      translitFr: 'ghurfa',
      meaningFr: 'chambre',
    ),
  ],
  'ف': [
    WordExample(
      before: '',
      highlight: 'فِ',
      after: 'يل',
      translitFr: 'fīl',
      meaningFr: 'éléphant',
    ),
    WordExample(
      before: '',
      highlight: 'فَ',
      after: 'رَح',
      translitFr: 'faraḥ',
      meaningFr: 'joie',
    ),
    WordExample(
      before: 'صَيْ',
      highlight: 'ف',
      after: '',
      translitFr: 'ṣayf',
      meaningFr: 'été',
    ),
  ],
  'ق': [
    WordExample(
      before: '',
      highlight: 'قَ',
      after: 'مَر',
      translitFr: 'qamar',
      meaningFr: 'lune',
    ),
    WordExample(
      before: '',
      highlight: 'قُ',
      after: 'رْآن',
      translitFr: 'qurʾān',
      meaningFr: 'Coran',
    ),
    WordExample(
      before: 'صَدِيْ',
      highlight: 'ق',
      after: '',
      translitFr: 'ṣadīq',
      meaningFr: 'ami',
    ),
  ],
  'ك': [
    WordExample(
      before: '',
      highlight: 'كِ',
      after: 'تَاب',
      translitFr: 'kitāb',
      meaningFr: 'livre',
    ),
    WordExample(
      before: '',
      highlight: 'كَ',
      after: 'لْب',
      translitFr: 'kalb',
      meaningFr: 'chien',
    ),
    WordExample(
      before: 'مَلَ',
      highlight: 'ك',
      after: '',
      translitFr: 'malak',
      meaningFr: 'ange',
    ),
  ],
  'ل': [
    WordExample(
      before: '',
      highlight: 'لَ',
      after: 'يْل',
      translitFr: 'layl',
      meaningFr: 'nuit',
    ),
    WordExample(
      before: '',
      highlight: 'لَ',
      after: 'وْن',
      translitFr: 'lawn',
      meaningFr: 'couleur',
    ),
    WordExample(
      before: 'وَ',
      highlight: 'لَ',
      after: 'د',
      translitFr: 'walad',
      meaningFr: 'enfant',
    ),
  ],
  'م': [
    WordExample(
      before: '',
      highlight: 'مَ',
      after: 'اء',
      translitFr: 'māʾ',
      meaningFr: 'eau',
    ),
    WordExample(
      before: '',
      highlight: 'مَ',
      after: 'سْجِد',
      translitFr: 'masjid',
      meaningFr: 'mosquée',
    ),
    WordExample(
      before: 'قَلَ',
      highlight: 'م',
      after: '',
      translitFr: 'qalam',
      meaningFr: 'stylo',
    ),
  ],
  'ن': [
    WordExample(
      before: '',
      highlight: 'نَ',
      after: 'هْر',
      translitFr: 'nahr',
      meaningFr: 'fleuve',
    ),
    WordExample(
      before: '',
      highlight: 'نُ',
      after: 'ور',
      translitFr: 'nūr',
      meaningFr: 'lumière',
    ),
    WordExample(
      before: 'أَذَا',
      highlight: 'ن',
      after: '',
      translitFr: 'adhān',
      meaningFr: 'appel à la prière',
    ),
  ],
  'ه': [
    WordExample(
      before: '',
      highlight: 'هَ',
      after: 'وَاء',
      translitFr: 'hawāʾ',
      meaningFr: 'air/vent',
    ),
    WordExample(
      before: '',
      highlight: 'هِ',
      after: 'لَال',
      translitFr: 'hilāl',
      meaningFr: 'croissant',
    ),
    WordExample(
      before: 'نَ',
      highlight: 'هْ',
      after: 'ر',
      translitFr: 'nahr',
      meaningFr: 'fleuve',
    ),
  ],
  'و': [
    WordExample(
      before: '',
      highlight: 'وَ',
      after: 'رْد',
      translitFr: 'ward',
      meaningFr: 'rose',
    ),
    WordExample(
      before: '',
      highlight: 'وَ',
      after: 'لَد',
      translitFr: 'walad',
      meaningFr: 'enfant',
    ),
    WordExample(
      before: 'لَ',
      highlight: 'وْ',
      after: 'ن',
      translitFr: 'lawn',
      meaningFr: 'couleur',
    ),
  ],
  'ي': [
    WordExample(
      before: '',
      highlight: 'يَ',
      after: 'د',
      translitFr: 'yad',
      meaningFr: 'main',
    ),
    WordExample(
      before: '',
      highlight: 'يَ',
      after: 'وْم',
      translitFr: 'yawm',
      meaningFr: 'jour',
    ),
    WordExample(
      before: 'بَ',
      highlight: 'يْ',
      after: 'ت',
      translitFr: 'bayt',
      meaningFr: 'maison',
    ),
  ],
};

// ── Letter mnemonics ────────────────────────────────────────────────────────

const Map<String, LetterMnemonic> letterMnemonics = {
  'ا': LetterMnemonic(
    hookFr: 'Un bâton droit — la première lettre, le pilier',
    imageFr: 'Une colonne verticale droite, début de tout',
  ),
  'ب': LetterMnemonic(
    hookFr: 'Un bateau avec un point en dessous — Ba comme Bateau',
    imageFr: 'La forme ressemble à une coque de bateau renversée',
  ),
  'ت': LetterMnemonic(
    hookFr:
        'Même bateau que ب, mais 2 points en haut — Deux gouttes de pluie',
    imageFr: 'Coque de bateau avec deux gouttes de pluie qui tombent',
  ),
  'ث': LetterMnemonic(
    hookFr: 'Même coque, 3 points — comme 3 dents qui sortent',
    imageFr: 'Trois petites dents au-dessus de la coque',
  ),
  'ج': LetterMnemonic(
    hookFr: 'Jim ressemble à un hameçon avec un point au bout',
    imageFr: 'Un hameçon de pêche avec l\'appât au bas',
  ),
  'ح': LetterMnemonic(
    hookFr:
        'Ha = Haleine chaude. Soufflez fort sur votre main — vous sentez la chaleur ?',
    imageFr: 'Vapeur qui sort de la bouche par temps froid',
  ),
  'خ': LetterMnemonic(
    hookFr:
        'Même forme que ح mais avec un point = le son racle, comme un chat mécontent',
    imageFr: 'Chat qui crache avec un point au-dessus de la tête',
  ),
  'د': LetterMnemonic(
    hookFr: 'Dal ressemble à une dent ou à la lettre D retournée',
    imageFr: 'Une dent coupée en deux vue de profil',
  ),
  'ذ': LetterMnemonic(
    hookFr:
        'Même dent que د mais avec un point — le son vibre comme une abeille',
    imageFr: 'Une dent avec une abeille qui bourdonne au-dessus',
  ),
  'ر': LetterMnemonic(
    hookFr: 'Ra ressemble à un crochet courbé — la langue roule comme une vague',
    imageFr: 'Une vague qui se courbe et roule',
  ),
  'ز': LetterMnemonic(
    hookFr:
        'Même courbe que ر mais avec un point — comme une vague avec une étincelle',
    imageFr: 'Vague avec un éclair/étincelle au-dessus',
  ),
  'س': LetterMnemonic(
    hookFr:
        'Sin ressemble à 3 petites dents de scie — comme le S de Serpent',
    imageFr: 'Une scie avec 3 dents',
  ),
  'ش': LetterMnemonic(
    hookFr:
        'Même scie que س mais avec 3 points — le CH fait un bruit de buisson',
    imageFr: 'Scie avec 3 petits points de rosée au-dessus',
  ),
  'ص': LetterMnemonic(
    hookFr:
        'Sad ressemble à un sac gonflé — le son sort comme de l\'air comprimé',
    imageFr: 'Un sac gonflé d\'air avec une petite queue',
  ),
  'ض': LetterMnemonic(
    hookFr: 'Le sac de ص avec un point — le Dad est unique à l\'arabe',
    imageFr: 'Sac gonflé avec un point distinctif',
  ),
  'ط': LetterMnemonic(
    hookFr:
        'Ta ressemble à une bassine retournée avec un bâton — lourd et solide',
    imageFr: 'Un chaudron ou une marmite retournée',
  ),
  'ظ': LetterMnemonic(
    hookFr: 'Même bassine que ط avec un point — encore plus lourd',
    imageFr: 'Chaudron avec un point qui l\'alourdit',
  ),
  'ع': LetterMnemonic(
    hookFr: 'Ayn signifie "œil" en arabe — et ça ressemble à un œil ouvert !',
    imageFr: 'Un œil allongé vu de face, avec la pupille en bas',
  ),
  'غ': LetterMnemonic(
    hookFr:
        'Même œil que ع mais avec un point — c\'est votre R français du fond de la gorge !',
    imageFr: 'Œil avec un sourcil froncé au-dessus',
  ),
  'ف': LetterMnemonic(
    hookFr: 'Fa ressemble à une fleur avec un point en haut — Fa comme Fleur',
    imageFr: 'Une fleur vue de profil avec la tige à gauche',
  ),
  'ق': LetterMnemonic(
    hookFr:
        'Qaf comme une couronne avec 2 points — le son sort du fond de la gorge comme un roi',
    imageFr: 'Une couronne royale avec deux joyaux au-dessus',
  ),
  'ك': LetterMnemonic(
    hookFr: 'Kaf ressemble à un K avec un toit — Kaf comme Karaté',
    imageFr: 'Lettre K avec un petit toit protecteur',
  ),
  'ل': LetterMnemonic(
    hookFr:
        'Lam ressemble à un bâton courbé vers la gauche — comme un berger qui tend sa houlette',
    imageFr: 'La houlette d\'un berger',
  ),
  'م': LetterMnemonic(
    hookFr: 'Mim ressemble à un M avec un cercle — Mim comme Maman',
    imageFr: 'Un M arrondi, comme une bulle de savon',
  ),
  'ن': LetterMnemonic(
    hookFr: 'Nun ressemble à un bol avec un point dedans — Nun comme Nuit',
    imageFr: 'Un bol avec une petite perle au fond',
  ),
  'ه': LetterMnemonic(
    hookFr: 'Ha ressemble à un visage souriant vu de face — soufflez doucement',
    imageFr: 'Un petit visage rond avec deux yeux',
  ),
  'و': LetterMnemonic(
    hookFr: 'Waw ressemble à un crochet ou un 9 — Waw comme Oui',
    imageFr: 'Un 9 stylisé avec une petite tête',
  ),
  'ي': LetterMnemonic(
    hookFr: 'Ya ressemble à un sourire avec 2 points dessous — Ya comme Yes !',
    imageFr: 'Un sourire renversé avec deux petits pieds',
  ),
};

// ── Letter groups for progressive unlocking ────────────────────────────────

const List<List<String>> letterGroups = [
  ['ا', 'ب', 'ت', 'ث'], // Groupe 1 — Famille Ba + Alif
  ['ج', 'ح', 'خ'], // Groupe 2 — Famille Jim
  ['د', 'ذ', 'ر', 'ز'], // Groupe 3 — Familles Dal/Ra
  ['س', 'ش', 'ص', 'ض'], // Groupe 4 — Sifflantes + emphatiques
  ['ط', 'ظ', 'ع', 'غ'], // Groupe 5 — Emphatiques + Ain
  ['ف', 'ق', 'ك', 'ل'], // Groupe 6 — Fa/Qaf/Kaf/Lam
  ['م', 'ن', 'ه', 'و', 'ي'], // Groupe 7 — Fin de l'alphabet
];

const List<String> letterGroupNames = [
  'Les premières lettres',
  'Les sons de gorge doux',
  'Les lettres rondes',
  'Les sifflantes',
  'Les sons profonds',
  'Les sons du palais',
  'Les finales',
];

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
  ),

  'ث': LetterPronunciation(
    letterName: 'Tha',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Langue entre les dents',
    equivalentFr: 'Comme le TH anglais de « Think »',
    equivalentLanguage: 'anglais',
    descriptionFr:
        'Placez le bout de la langue entre les incisives supérieures '
        'et inférieures, puis soufflez. C\'est le TH sourd anglais '
        'comme dans « three », « think », « math ».',
    astuceFr:
        'Posez vos doigts sur votre gorge : vous ne devez sentir '
        'aucune vibration (contrairement au ذ).',
    paireFr: 'ث (sourd, « think ») ↔ ذ (sonore, « this »)',
  ),

  'ج': LetterPronunciation(
    letterName: 'Jim',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Son DJ',
    equivalentFr: 'Comme DJ dans « Djebel »',
    descriptionFr:
        'Proche du DJ de « Django », « Adjoint ». Bien marquer le D '
        'initial : c\'est « dj » et non le J français de « Jour ».',
    erreurFr:
        'Ne pas prononcer comme un simple J français. Le ج commence '
        'toujours par un léger D.',
  ),

  'ح': LetterPronunciation(
    letterName: 'Ha profond',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Son de gorge',
    equivalentFr: 'H très appuyé, plus profond que le ه',
    descriptionFr:
        'Le son vient du milieu de la gorge (pharynx). Imaginez que '
        'vous expirez très fort par temps glacial, ou que vous soufflez '
        'sur vos lunettes pour les nettoyer — mais beaucoup plus fort.',
    astuceFr:
        'Mettez votre main devant la bouche : vous devez sentir un '
        'souffle chaud et puissant. Si vous ne sentez rien, vous faites '
        'un ه (trop léger). Le ح est un effort, le ه est un murmure.',
    erreurFr:
        'Ne pas confondre avec le خ (Kha). Le ح est un souffle pur, '
        'sans aucun frottement ni raclement.',
    paireFr: 'ح (souffle pur) ↔ خ (frottement, raclement)',
  ),

  'خ': LetterPronunciation(
    letterName: 'Kha',
    difficulty: PronunciationDifficulty.hard,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Comme la Jota espagnole (« Juan »)',
    equivalentLanguage: 'espagnol / allemand',
    descriptionFr:
        'Un frottement au fond de la bouche, entre le voile du palais '
        'et la luette. Comme le J espagnol de « Juan », « jamón », ou '
        'le « ch » allemand de « Bach ».',
    astuceFr:
        'Commencez par prononcer un K, puis relâchez la langue pour '
        'laisser l\'air frotter. Pensez au bruit d\'un chat qui crache.',
    erreurFr:
        'Ne pas confondre avec le R français. Le خ est plus sec et '
        'plus en arrière.',
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
  ),

  'ذ': LetterPronunciation(
    letterName: 'Dhal',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Langue entre les dents',
    equivalentFr: 'Comme le TH anglais de « This »',
    equivalentLanguage: 'anglais',
    descriptionFr:
        'Même position que le ث (langue entre les dents) mais en version '
        'sonore. Comme le TH anglais de « This », « That », « The ».',
    astuceFr:
        'La différence entre ث et ذ est la même qu\'entre S et Z : '
        'l\'un est sourd (sans vibration), l\'autre sonore (avec vibration). '
        'Posez vos doigts sur votre gorge pour sentir la différence.',
    paireFr: 'ث (sourd) ↔ ذ (sonore)',
  ),

  'ر': LetterPronunciation(
    letterName: 'Ra',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'R roulé',
    equivalentFr: 'R roulé espagnol / italien',
    equivalentLanguage: 'espagnol / italien',
    descriptionFr:
        'Un R roulé avec la pointe de la langue, comme le R espagnol '
        'de « Ramos », le R italien de « Roma », ou le R roulé des '
        'régions du sud de la France.',
    astuceFr:
        'La pointe de la langue tape rapidement contre la crête '
        'alvéolaire (juste derrière les dents du haut). Entraînez-vous '
        'en répétant rapidement « d-d-d-d » puis en laissant la langue vibrer.',
    erreurFr:
        'Ne jamais utiliser le R guttural parisien (celui du fond de '
        'la gorge). En arabe, ce son-là correspond au غ (Ghayn).',
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
        'Un S grave et sourd. Pour le produire : appuyez le milieu '
        'de la langue contre le palais, arrondissez les lèvres comme '
        'pour dire « O », puis prononcez un S — il sortira plus grave.',
    astuceFr:
        'Comparez « si » (léger, avec س) et « so » (lourd, arrondi, '
        'avec ص). Les emphatiques « assombrissent » les voyelles autour '
        'd\'elles : un « a » à côté d\'un ص sonne presque comme un « o ».',
    paireFr: 'س (léger, « si ») ↔ ص (lourd, « so »)',
  ),

  'ض': LetterPronunciation(
    letterName: 'Dad',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'D lourd (version emphatique de د)',
    descriptionFr:
        'Un D lourd et grave. On appuie les côtés de la langue contre '
        'les molaires supérieures. L\'arabe est surnommé « la langue du ض » '
        'car ce son est considéré comme unique à l\'arabe.',
    astuceFr:
        'Technique : appuyez le milieu de la langue contre le palais, '
        'arrondissez les lèvres, puis prononcez un D. Alternez : '
        '« da - ḍa - da - ḍa » pour entraîner votre oreille.',
    paireFr: 'د (léger) ↔ ض (lourd)',
  ),

  'ط': LetterPronunciation(
    letterName: 'Ta emphatique',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'T lourd et sec (version emphatique de ت)',
    descriptionFr:
        'Un T lourd et sec. La langue claque contre le palais avec '
        'plus de masse. Même technique que les autres emphatiques : '
        'langue contre le palais, lèvres arrondies.',
    astuceFr:
        'Alternez « ta - ṭa - ta - ṭa » pour bien sentir la différence. '
        'Le ط donne une impression de son « creux » et résonant.',
    paireFr: 'ت (léger) ↔ ط (lourd)',
  ),

  'ظ': LetterPronunciation(
    letterName: 'Dha emphatique',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Emphatique',
    equivalentFr: 'TH lourd (version emphatique de ذ)',
    descriptionFr:
        'Un TH sonore lourd. Même position interdentale que le ذ '
        '(langue entre les dents), mais avec la langue gonflée contre '
        'le palais et le son assombri.',
    astuceFr:
        'Pensez à un ذ (« this » en anglais) mais prononcé avec une '
        'voix plus grave et les lèvres arrondies.',
    paireFr: 'ذ (léger) ↔ ظ (lourd)',
  ),

  'ع': LetterPronunciation(
    letterName: 'Ayn',
    difficulty: PronunciationDifficulty.expert,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Aucun équivalent européen',
    descriptionFr:
        'LE son le plus difficile pour les francophones. C\'est une '
        'contraction musculaire de la gorge : le pharynx se resserre, '
        'comme si on étranglait momentanément le passage de l\'air.',
    astuceFr:
        'Imaginez le son réflexe quand on soulève un objet très lourd, '
        'ou une exclamation « Ah ! » de surprise douloureuse qui vient '
        'du ventre. Dites « aaa » normalement, puis serrez votre gorge '
        'au milieu du son : le moment où ça se resserre, c\'est le ع.',
    erreurFr:
        'Ne pas remplacer par un simple A ou par un coup de glotte. '
        'Le ع demande un vrai effort musculaire de la gorge.',
  ),

  'غ': LetterPronunciation(
    letterName: 'Ghayn',
    difficulty: PronunciationDifficulty.medium,
    categoryFr: 'Son de gorge',
    equivalentFr: 'Le R grasseyé français !',
    descriptionFr:
        'Bonne nouvelle : c\'est le son le plus facile de cette catégorie '
        'pour un francophone ! C\'est votre R quotidien : le R de « Rat », '
        '« Rien », « Paris ». Un frottement de la luette.',
    astuceFr:
        'Prononcez « garage » en français : le R que vous faites, c\'est '
        'exactement le غ arabe. En arabe, le R (ر) est roulé (espagnol), '
        'donc le غ occupe la niche du R français. Vous avez un avantage '
        'sur les anglophones : ce son est natif pour vous !',
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
        'Un K articulé très en arrière, au niveau de la luette. Le son '
        'est plus « creux » et résonne dans la gorge, comme le croassement '
        'd\'un corbeau.',
    astuceFr:
        'Dites un K normal, puis reculez progressivement le point de '
        'contact de la langue vers l\'arrière de la bouche, jusqu\'à '
        'toucher la luette. Alternez : « ka - qa - ka - qa » pour sentir '
        'la différence.',
    paireFr: 'ك (léger, en avant) ↔ ق (lourd, en arrière)',
  ),

  'ك': LetterPronunciation(
    letterName: 'Kaf',
    difficulty: PronunciationDifficulty.easy,
    categoryFr: 'Lettre familière',
    equivalentFr: 'Comme le K français',
    descriptionFr:
        'Identique au K de « Kilo », « Karaté ». Aucune difficulté.',
    paireFr: 'ك (léger) ↔ ق (lourd, profond)',
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
        'Un souffle léger qui vient du fond de la gorge, comme le H '
        'anglais de « Hello », « House », « Happy ». Ou comme quand '
        'on fait de la buée sur une vitre.',
    astuceFr:
        'Les francophones ont tendance à ne pas le prononcer du tout '
        '(car le H est muet en français). Il faut s\'entraîner à bien '
        'le souffler à chaque fois.',
    erreurFr:
        'Ne pas confondre avec le ح (Ha profond) qui est beaucoup plus '
        'appuyé et vient de plus profond dans la gorge.',
    paireFr: 'ه (souffle léger) ↔ ح (souffle profond)',
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
};

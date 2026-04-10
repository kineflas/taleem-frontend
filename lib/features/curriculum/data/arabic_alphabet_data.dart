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

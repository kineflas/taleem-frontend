import 'package:flutter/material.dart';
import '../../models/odyssee_models.dart';

/// Step 2: Discovery — Letter cards with mnemonics, forms, and syllables.
class OdysseeDiscoveryStep extends StatefulWidget {
  final OdysseeLessonContent lesson;
  final VoidCallback onComplete;

  const OdysseeDiscoveryStep({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<OdysseeDiscoveryStep> createState() => _OdysseeDiscoveryStepState();
}

class _OdysseeDiscoveryStepState extends State<OdysseeDiscoveryStep> {
  int _currentLetterIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.lesson.letters;
    if (letters.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
      return const SizedBox.shrink();
    }

    final isLast = _currentLetterIndex >= letters.length - 1;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Letter tabs
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(letters.length, (i) {
                final isActive = i == _currentLetterIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentLetterIndex = i);
                    _pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2A9D8F)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF2A9D8F)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      letters[i].glyph,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Amiri',
                        color: isActive ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Letter card (PageView)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: letters.length,
              onPageChanged: (i) => setState(() => _currentLetterIndex = i),
              itemBuilder: (context, index) {
                return _LetterCard(letter: letters[index]);
              },
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    widget.onComplete();
                  } else {
                    setState(() => _currentLetterIndex++);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLast ? 'Continuer' : 'Lettre suivante',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterData letter;
  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          // Big letter
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A9D8F).withOpacity(0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter.glyph,
                style: const TextStyle(
                  fontSize: 64,
                  fontFamily: 'Amiri',
                  color: Color(0xFF1A1A2E),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${letter.nameFr} — ${letter.nameAr}',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),

          // Mnemonic card
          _InfoCard(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFFF4A261),
            title: 'Mnémonique visuelle',
            content: letter.mnemoniqueVisuelle,
          ),
          const SizedBox(height: 12),

          // Anatomical advice
          _InfoCard(
            icon: Icons.medical_information_outlined,
            iconColor: const Color(0xFFE76F51),
            title: 'Conseil anatomique',
            content: letter.conseilAnatomique,
          ),
          const SizedBox(height: 16),

          // Positional forms
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Formes positionnelles',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FormChip('Isolée', letter.formes.isolee),
              _FormChip('Début', letter.formes.debut),
              _FormChip('Milieu', letter.formes.milieu),
              _FormChip('Fin', letter.formes.fin),
            ],
          ),
          const SizedBox(height: 16),

          // Syllables with vowels
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Syllabes (Harakat)',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: letter.syllabes.entries.map((e) {
              return _SyllabeChip(
                label: e.key == 'fatha'
                    ? 'Fatha'
                    : e.key == 'damma'
                        ? 'Damma'
                        : 'Kasra',
                glyph: e.value.glyph,
                son: e.value.son,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: iconColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}

class _FormChip extends StatelessWidget {
  final String label;
  final String glyph;
  const _FormChip(this.label, this.glyph);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              glyph,
              style: const TextStyle(fontSize: 28, fontFamily: 'Amiri'),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
      ],
    );
  }
}

class _SyllabeChip extends StatelessWidget {
  final String label;
  final String glyph;
  final String son;
  const _SyllabeChip({required this.label, required this.glyph, required this.son});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A9D8F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A9D8F))),
          const SizedBox(height: 4),
          Text(glyph,
              style: const TextStyle(fontSize: 28, fontFamily: 'Amiri'),
              textDirection: TextDirection.rtl),
          Text(son,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}

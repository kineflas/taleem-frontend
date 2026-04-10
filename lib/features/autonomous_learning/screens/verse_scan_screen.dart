import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Verse Scan screen (Module 5).
/// Students tap on words they recognize. Coverage percentage shown.
class VerseScanScreen extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int phase;

  const VerseScanScreen({
    super.key,
    required this.moduleNumber,
    required this.phase,
  });

  @override
  ConsumerState<VerseScanScreen> createState() => _VerseScanScreenState();
}

class _VerseScanScreenState extends ConsumerState<VerseScanScreen> {
  late Set<int> _recognizedWordIndices;
  int _currentVerseIndex = 0;

  // Mock verse data
  final List<Map<String, dynamic>> _verses = [
    {
      'surah': 'Al-Fatiha',
      'number': 1,
      'verse': 1,
      'arabicText': 'الحمد لله رب العالمين',
      'words': [
        {'arabicWord': 'الحمد', 'meaning': 'Louange', 'known': true},
        {'arabicWord': 'لله', 'meaning': 'à Allah', 'known': true},
        {'arabicWord': 'رب', 'meaning': 'Seigneur', 'known': true},
        {'arabicWord': 'العالمين', 'meaning': 'des mondes', 'known': true},
      ],
    },
    {
      'surah': 'Al-Fatiha',
      'number': 1,
      'verse': 2,
      'arabicText': 'الرحمن الرحيم',
      'words': [
        {'arabicWord': 'الرحمن', 'meaning': 'Le Miséricordieux', 'known': true},
        {'arabicWord': 'الرحيم', 'meaning': 'Le Très Miséricordieux', 'known': true},
      ],
    },
    {
      'surah': 'Al-Fatiha',
      'number': 1,
      'verse': 3,
      'arabicText': 'مالك يوم الدين',
      'words': [
        {'arabicWord': 'مالك', 'meaning': 'Maître', 'known': false},
        {'arabicWord': 'يوم', 'meaning': 'Jour', 'known': true},
        {'arabicWord': 'الدين', 'meaning': 'du Jugement', 'known': false},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _recognizedWordIndices = {};
  }

  void _toggleWordRecognition(int wordIndex) {
    setState(() {
      if (_recognizedWordIndices.contains(wordIndex)) {
        _recognizedWordIndices.remove(wordIndex);
      } else {
        _recognizedWordIndices.add(wordIndex);
      }
    });
  }

  int _getCoveragePercentage() {
    if (_verses[_currentVerseIndex]['words'].isEmpty) return 0;
    return ((_recognizedWordIndices.length /
            _verses[_currentVerseIndex]['words'].length) *
        100)
        .toInt();
  }

  void _nextVerse() {
    if (_currentVerseIndex < _verses.length - 1) {
      setState(() {
        _currentVerseIndex++;
        _recognizedWordIndices.clear();
      });
    }
  }

  void _previousVerse() {
    if (_currentVerseIndex > 0) {
      setState(() {
        _currentVerseIndex--;
        _recognizedWordIndices.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verse = _verses[_currentVerseIndex];
    final words = List<Map<String, dynamic>>.from(verse['words']);
    final coverage = _getCoveragePercentage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Lecture guidée'),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentVerseIndex + 1) / _verses.length,
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verse reference
                  Text(
                    'Sourate ${verse['surah']} (${verse['number']}:${verse['verse']})',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Coverage banner
                  _CoverageBanner(coverage: coverage),
                  const SizedBox(height: 20),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Tapez sur les mots que vous reconnaissez pour mesurer votre compréhension.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verse display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 12,
                        children: words.asMap().entries.map((entry) {
                          final index = entry.key;
                          final word = entry.value;
                          final isRecognized =
                              _recognizedWordIndices.contains(index);

                          return GestureDetector(
                            onTap: () => _toggleWordRecognition(index),
                            child: _WordToken(
                              word: word['arabicWord'],
                              isRecognized: isRecognized,
                              meaning: word['meaning'],
                              knownFromModule: word['known'],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Word legend
                  _WordLegend(),

                  const SizedBox(height: 20),

                  // Score summary
                  _ScoreSummary(
                    recognized: _recognizedWordIndices.length,
                    total: words.length,
                    coverage: coverage,
                  ),

                  const SizedBox(height: 20),

                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _currentVerseIndex > 0 ? _previousVerse : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Précédent'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: _currentVerseIndex < _verses.length - 1
                              ? _nextVerse
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Bravo! Vous avez terminé. 🎉'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.white),
                          label: Text(
                            _currentVerseIndex < _verses.length - 1
                                ? 'Suivant'
                                : 'Terminer',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageBanner extends StatelessWidget {
  final int coverage;

  const _CoverageBanner({required this.coverage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: coverage > 70
              ? [AppColors.success, AppColors.success.withOpacity(0.7)]
              : coverage > 40
                  ? [AppColors.accent, AppColors.accent.withOpacity(0.7)]
                  : [AppColors.warning, AppColors.warning.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            'Couverture du verset',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vous comprenez $coverage% de ce verset',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: coverage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordToken extends StatelessWidget {
  final String word;
  final bool isRecognized;
  final String meaning;
  final bool knownFromModule;

  const _WordToken({
    required this.word,
    required this.isRecognized,
    required this.meaning,
    required this.knownFromModule,
  });

  Color get _backgroundColor {
    if (isRecognized) {
      return AppColors.success.withOpacity(0.2);
    }
    if (knownFromModule) {
      return AppColors.accent.withOpacity(0.15);
    }
    return AppColors.textHint.withOpacity(0.1);
  }

  Color get _borderColor {
    if (isRecognized) {
      return AppColors.success;
    }
    if (knownFromModule) {
      return AppColors.accent;
    }
    return AppColors.textHint;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border.all(
          color: _borderColor,
          width: isRecognized ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Tooltip(
        message: meaning,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word,
              style: TextStyle(
                fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (isRecognized) ...[
              const SizedBox(height: 2),
              Text(
                meaning,
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordLegend extends StatelessWidget {
  const _WordLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Légende:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  border: Border.all(color: AppColors.success, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Reconnu',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  border: Border.all(color: AppColors.accent),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Partiellement connu',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.1),
                  border:
                      Border.all(color: AppColors.textHint, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Inconnu',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final int recognized;
  final int total;
  final int coverage;

  const _ScoreSummary({
    required this.recognized,
    required this.total,
    required this.coverage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Reconnus',
            value: '$recognized/$total',
            icon: '✅',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Couverture',
            value: '$coverage%',
            icon: '📊',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../data/quran_vocabulary_data.dart';
import '../providers/learning_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FLASH & RECALL — QCM exercice (Modules 1 & 2)
//
// Phase 1 (Voir)   : Affiche le mot + audio + translittération
// Phase 2 (Faire)  : QCM 4 choix avec audio, auto-avance après réponse
// Phase 3 (Appliquer) : même logique, sans translittération ni audio auto
//
// Audio : mot par mot (qurancdn.com/wbw) avec fallback verset complet (everyayah)
// Données : dataset local quran_vocabulary_data.dart
// ─────────────────────────────────────────────────────────────────────────────

class FlashRecallScreen extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int phase;

  const FlashRecallScreen({
    super.key,
    required this.moduleNumber,
    required this.phase,
  });

  @override
  ConsumerState<FlashRecallScreen> createState() => _FlashRecallScreenState();
}

class _FlashRecallScreenState extends ConsumerState<FlashRecallScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _showingChoices = false;
  int _selectedChoice = -1;
  bool _answered = false;
  bool _isPlayingAudio = false;
  bool _audioError = false;

  // Données réelles
  late List<QuranWord> _words;
  late List<_CardData> _cards;

  // Animation
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.92,
      upperBound: 1.0,
    )..value = 1.0;

    _words = ref.read(localWordsProvider(widget.moduleNumber));
    if (_words.isEmpty) {
      // Fallback module 1 si module vide
      _words = kModule1Words;
    }
    _words.shuffle();
    _cards = _words.take(10).map((w) => _CardData.fromWord(w, _words)).toList();

    _startCard();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ── Card logic ─────────────────────────────────────────────────────────────

  void _startCard() {
    setState(() {
      _showingChoices = widget.phase >= 2; // phase 1 → pas de QCM direct
      _selectedChoice = -1;
      _answered = false;
      _isPlayingAudio = false;
      _audioError = false;
    });
    _fadeController.forward(from: 0);
    _scaleController.forward(from: 0.92);

    // Phase 1 : afficher directement, audio auto
    // Phase 2 : audio auto puis QCM après délai
    // Phase 3 : QCM direct, pas audio auto
    if (widget.phase <= 2) {
      _playAudio();
    }
    if (widget.phase == 2) {
      // Délai avant choix (laisse entendre le mot)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showingChoices = true);
      });
    }
  }

  Future<void> _playAudio() async {
    if (_isPlayingAudio || _currentIndex >= _cards.length) return;
    final card = _cards[_currentIndex];
    setState(() {
      _isPlayingAudio = true;
      _audioError = false;
    });
    try {
      await _audioPlayer.stop();
      // Essai 1 : audio mot par mot (qurancdn)
      await _audioPlayer.play(UrlSource(card.word.audioUrl));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    } catch (_) {
      try {
        // Essai 2 : audio du verset complet (everyayah)
        await _audioPlayer.play(UrlSource(card.word.verseAudioUrl));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingAudio = false);
        });
      } catch (_) {
        if (mounted) setState(() { _isPlayingAudio = false; _audioError = true; });
      }
    }
  }

  void _selectAnswer(int choiceIndex) {
    if (_answered) return;
    final isCorrect = _cards[_currentIndex].choices[choiceIndex].isCorrect;
    setState(() {
      _selectedChoice = choiceIndex;
      _answered = true;
      if (isCorrect) _correctAnswers++;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_currentIndex < _cards.length - 1) {
        setState(() => _currentIndex++);
        _startCard();
      } else {
        _showSessionComplete();
      }
    });
  }

  void _showSessionComplete() {
    final accuracy = _cards.isEmpty ? 0 : (_correctAnswers / _cards.length * 100).round();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              accuracy >= 80 ? '🏆' : accuracy >= 60 ? '✅' : '🔄',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'Session terminée !',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge('$_correctAnswers/${_cards.length}', 'Bonnes réponses', AppColors.success),
                const SizedBox(width: 16),
                _statBadge('$accuracy%', 'Précision', accuracy >= 80 ? AppColors.success : accuracy >= 60 ? AppColors.warning : AppColors.danger),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _currentIndex = 0;
                        _correctAnswers = 0;
                        _words.shuffle();
                        _cards = _words.take(10).map((w) => _CardData.fromWord(w, _words)).toList();
                        _startCard();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recommencer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Terminer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Flash & Recall'),
        ),
        body: const Center(child: Text('Aucun mot disponible pour ce module.')),
      );
    }

    final card = _cards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_appBarTitle()),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            minHeight: 4,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stats ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Carte ${_currentIndex + 1} / ${_cards.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '$_correctAnswers correct',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Carte mot ─────────────────────────────────────────────────
            ScaleTransition(
              scale: _scaleController,
              child: FadeTransition(
                opacity: _fadeController,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Badge catégorie + fréquence
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _categoryBadge(card.word.category),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${card.word.frequency}× dans le Coran',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Mot arabe
                      Text(
                        card.word.arabicWord,
                        style: GoogleFonts.scheherazadeNew(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),

                      // Translittération (phase 1 & 2 uniquement)
                      if (widget.phase <= 2) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.word.transliteration,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Bouton audio
                      GestureDetector(
                        onTap: _audioError ? null : _playAudio,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isPlayingAudio
                                ? AppColors.accent
                                : _audioError
                                    ? AppColors.danger.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _audioError
                                    ? Icons.wifi_off
                                    : _isPlayingAudio
                                        ? Icons.stop
                                        : Icons.volume_up,
                                size: 18,
                                color: _isPlayingAudio
                                    ? Colors.white
                                    : _audioError
                                        ? AppColors.danger
                                        : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _audioError
                                    ? 'Audio indisponible'
                                    : _isPlayingAudio
                                        ? 'En cours...'
                                        : 'Écouter',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isPlayingAudio
                                      ? Colors.white
                                      : _audioError
                                          ? AppColors.danger
                                          : AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Phase 1 : afficher la traduction directement
                      if (widget.phase == 1) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Text(
                            card.word.meaningFr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Exemple : ${_exampleLabel(card.word)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── QCM (phase 2 & 3) ─────────────────────────────────────────
            if (_showingChoices && widget.phase >= 2) ...[
              const SizedBox(height: 24),
              Text(
                'Quelle est la traduction de ce mot ?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...List.generate(card.choices.length, (i) => _buildChoice(i, card)),
            ],

            // Phase 1 : bouton "Suivant" manuel
            if (widget.phase == 1) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_currentIndex < _cards.length - 1) {
                      setState(() => _currentIndex++);
                      _startCard();
                    } else {
                      // Phase 1 : pas de score, juste révision
                      _correctAnswers = _cards.length;
                      _showSessionComplete();
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_currentIndex < _cards.length - 1 ? 'Suivant' : 'Terminer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChoice(int i, _CardData card) {
    final choice = card.choices[i];
    final isSelected = _selectedChoice == i;
    final showResult = _answered && isSelected;
    final showCorrect = _answered && choice.isCorrect;

    Color borderColor = AppColors.divider;
    Color bgColor = Colors.white;
    if (showResult) {
      borderColor = choice.isCorrect ? AppColors.success : AppColors.danger;
      bgColor = (choice.isCorrect ? AppColors.success : AppColors.danger).withOpacity(0.08);
    } else if (showCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.06);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: showResult || showCorrect ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _answered ? null : () => _selectAnswer(i),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Lettre A/B/C/D
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: showResult || showCorrect ? borderColor : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i), // A, B, C, D
                        style: TextStyle(
                          color: showResult || showCorrect ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      choice.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: showResult
                            ? (choice.isCorrect ? AppColors.success : AppColors.danger)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (showResult)
                    Icon(
                      choice.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: choice.isCorrect ? AppColors.success : AppColors.danger,
                    ),
                  if (showCorrect && !isSelected)
                    const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _appBarTitle() {
    switch (widget.phase) {
      case 1: return '👁️ Voir — Module ${widget.moduleNumber}';
      case 2: return '✋ Faire — Module ${widget.moduleNumber}';
      case 3: return '🎯 Appliquer — Module ${widget.moduleNumber}';
      default: return 'Flash & Recall';
    }
  }

  String _exampleLabel(QuranWord word) {
    return 'Sourate ${word.exampleSurah}, verset ${word.exampleVerse}';
  }

  Widget _categoryBadge(String category) {
    final Map<String, ({String label, Color color})> cats = {
      'particle':  (label: 'Particule', color: AppColors.accent),
      'noun':      (label: 'Nom', color: AppColors.primary),
      'verb':      (label: 'Verbe', color: const Color(0xFF6B46C1)),
      'adjective': (label: 'Adjectif', color: const Color(0xFF0891B2)),
      'phrase':    (label: 'Expression', color: AppColors.warning),
    };
    final cat = cats[category] ?? (label: category, color: AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cat.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cat.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cat.color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modèle de carte pour l'exercice
// ─────────────────────────────────────────────────────────────────────────────

class _Choice {
  final String text;
  final bool isCorrect;
  const _Choice(this.text, {this.isCorrect = false});
}

class _CardData {
  final QuranWord word;
  final List<_Choice> choices;

  const _CardData({required this.word, required this.choices});

  factory _CardData.fromWord(QuranWord word, List<QuranWord> allWords) {
    // Générer 3 distracteurs depuis le dataset complet
    final distractors = distractorsFor(word, count: 3);
    final choices = <_Choice>[
      _Choice(word.meaningFr, isCorrect: true),
      ...distractors.map((d) => _Choice(d.meaningFr)),
    ]..shuffle();
    return _CardData(word: word, choices: choices);
  }
}

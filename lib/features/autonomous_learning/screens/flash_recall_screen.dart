import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/learning_provider.dart';

/// Flash & Recall QCM exercise (Module 1, Phase 2).
/// Displays Arabic word with audio, timer, then multiple choice answers.
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
  late AnimationController _fadeController;
  int _currentCardIndex = 0;
  int _correctAnswers = 0;
  int _totalCards = 10;
  bool _showingChoices = false;
  int _selectedChoice = -1;
  bool _answered = false;
  final _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  // Mock card data
  final List<Map<String, dynamic>> _mockCards = [
    {
      'arabicWord': 'إِن',
      'audioUrl': '/audio/words/inn.mp3',
      'boxLevel': 2,
      'choices': [
        {'text': 'Si', 'correct': true},
        {'text': 'Quand', 'correct': false},
        {'text': 'Où', 'correct': false},
        {'text': 'Pourquoi', 'correct': false},
      ]
    },
    {
      'arabicWord': 'عَلَى',
      'audioUrl': '/audio/words/ala.mp3',
      'boxLevel': 1,
      'choices': [
        {'text': 'Sur', 'correct': true},
        {'text': 'Sous', 'correct': false},
        {'text': 'Vers', 'correct': false},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _totalCards = _mockCards.length;
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _startNewCard();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startNewCard() {
    setState(() {
      _showingChoices = false;
      _selectedChoice = -1;
      _answered = false;
      _isPlayingAudio = false;
    });
    _fadeController.forward(from: 0);
    _playAudio();
    _scheduleShowChoices();
  }

  void _scheduleShowChoices() {
    final boxLevel = _mockCards[_currentCardIndex]['boxLevel'] as int;
    final timerDuration = _getTimerDuration(boxLevel);
    Future.delayed(Duration(seconds: timerDuration), () {
      if (mounted) {
        setState(() => _showingChoices = true);
      }
    });
  }

  int _getTimerDuration(int boxLevel) {
    switch (boxLevel) {
      case 1:
        return 3;
      case 2:
        return 2;
      case 3:
        return 1;
      default:
        return 3;
    }
  }

  Future<void> _playAudio() async {
    try {
      setState(() => _isPlayingAudio = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _isPlayingAudio = false);
    } catch (e) {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  void _selectAnswer(int choiceIndex) {
    if (_answered) return;

    final card = _mockCards[_currentCardIndex];
    final choices = List<Map<String, dynamic>>.from(card['choices'] ?? []);
    final isCorrect = choices[choiceIndex]['correct'] as bool;

    setState(() {
      _selectedChoice = choiceIndex;
      _answered = true;
      if (isCorrect) _correctAnswers++;
    });

    if (isCorrect) {
      _showSuccessFlash();
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _currentCardIndex < _totalCards - 1) {
        setState(() => _currentCardIndex++);
        _startNewCard();
      } else if (mounted) {
        _showSessionComplete();
      }
    });
  }

  void _showSuccessFlash() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Correct!'),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Séance terminée! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_correctAnswers/$_totalCards',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Précision: ${((_correctAnswers / _totalCards) * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text(
              'Terminer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _mockCards[_currentCardIndex];
    final choices = List<Map<String, dynamic>>.from(card['choices'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Flash & Recall'),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentCardIndex + 1) / _totalCards,
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Carte ${_currentCardIndex + 1} / $_totalCards',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              card['arabicWord'],
                              style: TextStyle(
                                fontFamily:
                                    GoogleFonts.scheherazadeNew().fontFamily,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_showingChoices)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPlayingAudio
                                    ? AppColors.accent
                                    : AppColors.primary.withOpacity(0.1),
                                foregroundColor: _isPlayingAudio
                                    ? Colors.white
                                    : AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _playAudio,
                              icon: Icon(
                                _isPlayingAudio ? Icons.stop : Icons.volume_up,
                                size: 20,
                              ),
                              label: Text(
                                _isPlayingAudio ? 'Arrêter' : 'Écouter',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_showingChoices) ...[const SizedBox(height: 24)],
                  if (_showingChoices)
                    Column(
                      children: List.generate(choices.length, (index) {
                        final choice = choices[index];
                        final isSelected = _selectedChoice == index;
                        final isCorrect = choice['correct'] as bool;
                        final showResult = _answered && isSelected;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: showResult
                                  ? (isCorrect
                                      ? AppColors.success.withOpacity(0.15)
                                      : AppColors.danger.withOpacity(0.15))
                                  : Colors.white,
                              border: Border.all(
                                color: showResult
                                    ? (isCorrect
                                        ? AppColors.success
                                        : AppColors.danger)
                                    : AppColors.divider,
                                width: showResult ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _answered
                                    ? null
                                    : () => _selectAnswer(index),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          choice['text'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: showResult
                                                ? (isCorrect
                                                    ? AppColors.success
                                                    : AppColors.danger)
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (showResult)
                                        Icon(
                                          isCorrect ? Icons.check : Icons.close,
                                          color: isCorrect
                                              ? AppColors.success
                                              : AppColors.danger,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

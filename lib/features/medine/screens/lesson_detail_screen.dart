import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/lesson_models.dart';
import '../providers/lesson_provider.dart';
import '../widgets/energy_bar.dart';
import '../widgets/star_display.dart';
import 'tabs/theory_tab.dart';
import 'tabs/dialogue_tab.dart';
import 'tabs/exercises_tab.dart';
import 'tabs/quiz_tab.dart';

/// Full lesson detail: 4-tab layout with energy bar at top.
/// Tabs: Cours | Dialogue | Exercices | Quiz
class LessonDetailScreen extends ConsumerStatefulWidget {
  final int lessonNumber;
  const LessonDetailScreen({super.key, required this.lessonNumber});

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Track local completion (optimistic UI)
  bool _theoryDone = false;
  bool _dialogueDone = false;
  bool _exercisesDone = false;
  bool _quizDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markSegment(String segment) {
    setState(() {
      switch (segment) {
        case 'theory':
          _theoryDone = true;
        case 'dialogue':
          _dialogueDone = true;
        case 'exercises':
          _exercisesDone = true;
        case 'quiz':
          _quizDone = true;
      }
    });

    // Fire progress update (fire-and-forget)
    ref.read(medineLessonApiProvider).updateProgress(
          widget.lessonNumber,
          segment: segment,
          value: 1.0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(medineLessonDetailProvider(widget.lessonNumber));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text('Lecon ${widget.lessonNumber}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text('Lecon ${widget.lessonNumber}'),
        ),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (lesson) {
        // Sync server progress into local state once
        final p = lesson.progress;
        if (p != null) {
          _theoryDone = _theoryDone || p.theoryCompleted;
          _dialogueDone = _dialogueDone || p.dialogueCompleted;
          _exercisesDone = _exercisesDone || (p.exercisesScore != null && p.exercisesScore! > 0);
          _quizDone = _quizDone || (p.quizScore != null && p.quizScore! > 0);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.titleFr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    lesson.titleAr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            actions: [
              if (lesson.progress != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: StarDisplay(stars: lesson.progress!.stars, size: 22),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Cours'),
                Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Dialogue'),
                Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Exercices'),
                Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Quiz'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Energy bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: EnergyBar(
                  theoryDone: _theoryDone,
                  dialogueDone: _dialogueDone,
                  exercisesDone: _exercisesDone,
                  quizDone: _quizDone,
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TheoryTab(
                      theory: lesson.theory,
                      onComplete: () => _markSegment('theory'),
                    ),
                    DialogueTab(
                      lessonNumber: lesson.lessonNumber,
                      dialogue: lesson.theory.dialogue,
                      onComplete: () => _markSegment('dialogue'),
                    ),
                    ExercisesTab(
                      lessonNumber: lesson.lessonNumber,
                      quizQuestions: lesson.allQuizQuestions,
                      exercisesMd: lesson.theory.exercisesMd,
                      onComplete: () => _markSegment('exercises'),
                    ),
                    QuizTab(
                      lessonNumber: lesson.lessonNumber,
                      questions: lesson.allQuizQuestions,
                      onComplete: (result) {
                        _markSegment('quiz');
                        // Invalidate to refresh stars
                        ref.invalidate(medineLessonDetailProvider(widget.lessonNumber));
                        ref.invalidate(medineLessonsProvider);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

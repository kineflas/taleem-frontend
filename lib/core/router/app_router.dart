import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/invitation_code_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/student_detail_screen.dart';
import '../../features/teacher/screens/create_task_screen.dart';
import '../../features/teacher/screens/teacher_settings_screen.dart';
import '../../features/student/screens/student_shell_screen.dart';
import '../../features/student/screens/student_today_screen.dart';
import '../../features/student/screens/agenda_screen.dart';
import '../../features/student/screens/progress_screen.dart';
import '../../features/student/screens/student_settings_screen.dart';
import '../../features/curriculum/screens/curriculum_library_screen.dart';
import '../../features/curriculum/screens/curriculum_program_screen.dart';
import '../../features/curriculum/screens/curriculum_unit_screen.dart';
import '../../features/curriculum/screens/curriculum_item_screen.dart';
import '../../features/autonomous_learning/screens/learning_hub_screen.dart';
import '../../features/autonomous_learning/screens/module_detail_screen.dart';
import '../../features/autonomous_learning/screens/flash_recall_screen.dart';
import '../../features/autonomous_learning/screens/spatial_particles_screen.dart';
import '../../features/autonomous_learning/screens/chunking_screen.dart';
import '../../features/autonomous_learning/screens/root_discovery_screen.dart';
import '../../features/autonomous_learning/screens/verse_scan_screen.dart';
import '../../features/hifz/screens/hifz_hub_screen.dart';
import '../../features/hifz/screens/hifz_goal_create_screen.dart';
import '../../features/hifz/screens/hifz_session_screen.dart';
import '../../features/hifz/screens/hifz_revision_screen.dart';
import '../../features/hifz/screens/surah_heatmap_screen.dart';
import '../../features/hifz_v2/screens/wird_session_screen.dart';
import '../../features/hifz_v2/screens/wird_verse_flow_screen.dart';
import '../../features/hifz_v2/models/wird_models.dart';
import '../../features/medine/screens/lesson_list_screen.dart';
import '../../features/medine/screens/lesson_detail_screen.dart';
import '../../features/medine/screens/flashcard_review_screen.dart';
import '../../features/medine/screens/diagnostic_screen.dart';
import '../../features/medine/screens/gamification_screen.dart';
import '../../features/medine_v2/screens/caravane_map_screen.dart';
import '../../features/medine_v2/screens/lesson_flow_screen.dart';
import '../../features/medine_v2/screens/flashcard_review_screen_v2.dart';
import '../../features/medine_v2/screens/boss_quiz_screen.dart';
import '../../features/medine_v2/screens/final_exam_screen.dart';
import '../../features/medine_v2/screens/diagnostic_screen_v2.dart';
import '../../features/odyssee_lettres/screens/odyssee_map_screen.dart';
import '../../features/odyssee_lettres/screens/odyssee_lesson_flow_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // While auth is loading (token validation in progress), don't redirect
      // to avoid flashing the login page.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value?.accessToken != null;
      final isAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!isLoggedIn && !isAuth) return '/login';
      if (isLoggedIn && isAuth) {
        final role = authState.value?.role;
        return role == 'TEACHER' ? '/teacher' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/invitation',
        builder: (_, __) => const InvitationCodeScreen(),
      ),

      // Teacher routes
      GoRoute(
        path: '/teacher',
        builder: (_, __) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: 'student/:id',
            builder: (ctx, state) => StudentDetailScreen(
              studentId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'curriculum/:enrollmentId',
                builder: (ctx, state) => CurriculumProgramScreen(
                  enrollmentId: state.pathParameters['enrollmentId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'create-task',
            builder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateTaskScreen(preselectedStudentId: extra?['studentId']);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const TeacherSettingsScreen(),
          ),
        ],
      ),

      // Student shell with bottom nav
      ShellRoute(
        builder: (_, __, child) => StudentShellScreen(child: child),
        routes: [
          GoRoute(path: '/student', builder: (_, __) => const StudentTodayScreen()),
          GoRoute(path: '/student/agenda', builder: (_, __) => const AgendaScreen()),
          GoRoute(path: '/student/progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/student/curriculum', builder: (_, __) => const CurriculumLibraryScreen()),
          GoRoute(path: '/student/learn', builder: (_, __) => const LearningHubScreen()),
          GoRoute(path: '/student/hifz', builder: (_, __) => const HifzHubScreen()),
          GoRoute(path: '/student/medine', builder: (_, __) => const LessonListScreen()),
          GoRoute(path: '/student/medine-v2', builder: (_, __) => const CaravaneMapScreen()),
          GoRoute(path: '/student/odyssee', builder: (_, __) => const OdysseeMapScreen()),
          GoRoute(path: '/student/settings', builder: (_, __) => const StudentSettingsScreen()),
        ],
      ),

      // Medine deep routes (outside shell — full screen)
      GoRoute(
        path: '/medine/lesson/:lessonNumber',
        builder: (ctx, state) => LessonDetailScreen(
          lessonNumber: int.parse(state.pathParameters['lessonNumber']!),
        ),
      ),
      GoRoute(
        path: '/medine/flashcards',
        builder: (_, __) => const FlashcardReviewScreen(),
      ),
      GoRoute(
        path: '/medine/diagnostic',
        builder: (_, __) => const DiagnosticScreen(),
      ),
      GoRoute(
        path: '/medine/gamification',
        builder: (_, __) => const GamificationScreen(),
      ),

      // Medine V2 deep routes (full screen)
      GoRoute(
        path: '/medine-v2/lesson/:lessonNumber',
        builder: (ctx, state) => LessonFlowScreen(
          lessonNumber: int.parse(state.pathParameters['lessonNumber']!),
        ),
      ),
      GoRoute(
        path: '/medine-v2/flashcards',
        builder: (_, __) => const FlashcardReviewScreenV2(),
      ),
      GoRoute(
        path: '/medine-v2/boss-quiz/:partNumber',
        builder: (ctx, state) => BossQuizScreen(
          partNumber: int.parse(state.pathParameters['partNumber']!),
        ),
      ),
      GoRoute(
        path: '/medine-v2/exam',
        builder: (_, __) => const FinalExamScreen(),
      ),
      GoRoute(
        path: '/medine-v2/diagnostic',
        builder: (_, __) => const DiagnosticScreenV2(),
      ),

      // Odyssée des Lettres deep routes (full screen)
      GoRoute(
        path: '/odyssee/lesson/:lessonNumber',
        builder: (ctx, state) => OdysseeLessonFlowScreen(
          lessonNumber: int.parse(state.pathParameters['lessonNumber']!),
        ),
      ),

      // Curriculum deep routes (outside shell — full screen)
      GoRoute(
        path: '/student/curriculum/:enrollmentId',
        builder: (ctx, state) => CurriculumProgramScreen(
          enrollmentId: state.pathParameters['enrollmentId']!,
        ),
        routes: [
          GoRoute(
            path: 'unit/:unitId',
            builder: (ctx, state) => CurriculumUnitScreen(
              enrollmentId: state.pathParameters['enrollmentId']!,
              unitId: state.pathParameters['unitId']!,
            ),
          ),
          GoRoute(
            path: 'item/:itemId',
            builder: (ctx, state) => CurriculumItemScreen(
              enrollmentId: state.pathParameters['enrollmentId']!,
              itemId: state.pathParameters['itemId']!,
            ),
          ),
        ],
      ),

      // Autonomous Learning deep routes (full screen exercises)
      GoRoute(
        path: '/learn/module/:moduleNumber',
        builder: (ctx, state) => ModuleDetailScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber']!),
        ),
      ),

      // Route généré par ModuleDetailScreen → exercise par moduleId + phaseId
      GoRoute(
        path: '/learning/module/:moduleId/phase/:phaseId/exercise',
        builder: (ctx, state) {
          final moduleId = int.parse(state.pathParameters['moduleId'] ?? '1');
          final phaseId  = int.parse(state.pathParameters['phaseId']  ?? '1');
          switch (moduleId) {
            case 1:
              return FlashRecallScreen(moduleNumber: moduleId, phase: phaseId);
            case 2:
              return SpatialParticlesScreen(moduleNumber: moduleId, phase: phaseId);
            case 3:
              return ChunkingScreen(moduleNumber: moduleId, phase: phaseId);
            case 4:
              return RootDiscoveryScreen(moduleNumber: moduleId, phase: phaseId);
            case 5:
              return VerseScanScreen(moduleNumber: moduleId, phase: phaseId);
            default:
              return FlashRecallScreen(moduleNumber: moduleId, phase: phaseId);
          }
        },
      ),
      GoRoute(
        path: '/learn/flash-recall/:moduleNumber',
        builder: (ctx, state) => FlashRecallScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber'] ?? '1'),
          phase: int.parse(state.uri.queryParameters['phase'] ?? '1'),
        ),
      ),
      GoRoute(
        path: '/learn/spatial-particles/:moduleNumber',
        builder: (ctx, state) => SpatialParticlesScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber'] ?? '2'),
          phase: int.parse(state.uri.queryParameters['phase'] ?? '1'),
        ),
      ),
      GoRoute(
        path: '/learn/chunking/:moduleNumber',
        builder: (ctx, state) => ChunkingScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber'] ?? '3'),
          phase: int.parse(state.uri.queryParameters['phase'] ?? '1'),
        ),
      ),
      GoRoute(
        path: '/learn/root-discovery/:moduleNumber',
        builder: (ctx, state) => RootDiscoveryScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber'] ?? '4'),
          phase: int.parse(state.uri.queryParameters['phase'] ?? '1'),
        ),
      ),
      GoRoute(
        path: '/learn/verse-scan/:moduleNumber',
        builder: (ctx, state) => VerseScanScreen(
          moduleNumber: int.parse(state.pathParameters['moduleNumber'] ?? '5'),
          phase: int.parse(state.uri.queryParameters['phase'] ?? '1'),
        ),
      ),

      // Hifz Master deep routes (full screen)
      GoRoute(
        path: '/hifz/new-goal',
        builder: (_, __) => const HifzGoalCreateScreen(),
      ),
      GoRoute(
        path: '/hifz/session/:goalId',
        builder: (ctx, state) {
          // HifzSessionScreen is navigated to via Navigator.push with a goal object
          // This route is a fallback - redirect to hub
          return const HifzHubScreen();
        },
      ),
      GoRoute(
        path: '/hifz/revision',
        builder: (_, __) => const HifzRevisionScreen(),
      ),
      GoRoute(
        path: '/hifz/heatmap/:surahNumber',
        builder: (ctx, state) => SurahHeatmapScreen(
          surahNumber: int.parse(state.pathParameters['surahNumber']!),
          surahName: state.uri.queryParameters['name'] ?? 'Surah',
        ),
      ),

      // Hifz V2 — Wird session (full screen)
      GoRoute(
        path: '/hifz-v2/wird',
        builder: (ctx, state) {
          final session = state.extra as WirdSession;
          return WirdSessionScreen(session: session);
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable: ${state.error}')),
    ),
  );
});

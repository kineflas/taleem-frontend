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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
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
          GoRoute(path: '/student/settings', builder: (_, __) => const StudentSettingsScreen()),
        ],
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
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable: ${state.error}')),
    ),
  );
});

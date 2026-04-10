import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/database/app_database.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/models/task_model.dart';

const _uuid = Uuid();

// ─── Today's tasks ───────────────────────────────────────────────────────────

final todayTasksProvider = AsyncNotifierProvider<TodayTasksNotifier, List<TaskModel>>(
  () => TodayTasksNotifier(),
);

class TodayTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() => _fetch();

  Future<List<TaskModel>> _fetch() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiConstants.studentTasksToday);
    final tasks = (response.data as List)
        .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
        .toList();

    // Cache to local DB (mobile only)
    if (!kIsWeb) {
      final db = ref.read(dbProvider);
      await db.upsertTasks(tasks.map(_toLocalCompanion).toList());
    }

    return tasks;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> completeTask({
    required String taskId,
    required int? difficulty,
    required String? note,
    required String? parentToken,
  }) async {
    final dio = ref.read(dioProvider);
    final isOffline = ref.read(isOfflineForStudentProvider);

    if (isOffline && !kIsWeb) {
      // Queue locally
      final db = ref.read(dbProvider);
      await db.addPendingSync(PendingSyncsCompanion(
        id: Value(_uuid.v4()),
        taskId: Value(taskId),
        difficulty: Value(difficulty),
        studentNote: Value(note),
        createdAt: Value(DateTime.now()),
      ));
      // Optimistic update
      await db.updateTaskStatus(taskId, 'COMPLETED');
      state = AsyncData(
        (state.valueOrNull ?? []).map((t) {
          if (t.id == taskId) {
            return TaskModel(
              id: t.id,
              programId: t.programId,
              teacherId: t.teacherId,
              studentId: t.studentId,
              pillar: t.pillar,
              taskType: t.taskType,
              title: t.title,
              description: t.description,
              surahNumber: t.surahNumber,
              surahName: t.surahName,
              verseStart: t.verseStart,
              verseEnd: t.verseEnd,
              bookRef: t.bookRef,
              chapterNumber: t.chapterNumber,
              chapterTitle: t.chapterTitle,
              pageStart: t.pageStart,
              pageEnd: t.pageEnd,
              dueDate: t.dueDate,
              scheduledDate: t.scheduledDate,
              status: TaskStatus.completed,
              createdAt: t.createdAt,
              completion: TaskCompletionModel(
                id: _uuid.v4(),
                taskId: taskId,
                completedAt: DateTime.now(),
                difficulty: difficulty,
                studentNote: note,
                parentValidated: parentToken != null,
              ),
            );
          }
          return t;
        }).toList(),
      );
      return;
    }

    // Online completion
    await dio.post(
      '${ApiConstants.tasks}/$taskId/complete',
      data: {
        'difficulty': difficulty,
        'student_note': note,
        'parent_token': parentToken,
      },
    );
    await refresh();
    ref.invalidate(streakProvider);
  }
}

// ─── Streak ──────────────────────────────────────────────────────────────────

final streakProvider = AsyncNotifierProvider<StreakNotifier, StreakModel?>(() => StreakNotifier());

class StreakNotifier extends AsyncNotifier<StreakModel?> {
  @override
  Future<StreakModel?> build() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiConstants.studentStreak);
      final streak = StreakModel.fromJson(response.data as Map<String, dynamic>);

      // Cache locally
      if (!kIsWeb) {
        final db = ref.read(dbProvider);
        await db.upsertStreak(LocalStreakCompanion(
          studentId: Value(streak.studentId),
          currentStreakDays: Value(streak.currentStreakDays),
          longestStreakDays: Value(streak.longestStreakDays),
          jokersTotal: Value(streak.jokersTotal),
          jokersUsedThisMonth: Value(streak.jokersUsedThisMonth),
          updatedAt: Value(DateTime.now()),
        ));
      }
      return streak;
    } catch (_) {
      return null;
    }
  }

  Future<void> useJoker({required JokerReason reason, String? note}) async {
    final dio = ref.read(dioProvider);
    final reasonApi = {
      JokerReason.illness: 'ILLNESS',
      JokerReason.travel: 'TRAVEL',
      JokerReason.family: 'FAMILY',
      JokerReason.other: 'OTHER',
    }[reason]!;

    await dio.post(ApiConstants.studentJokersUse, data: {
      'reason': reasonApi,
      'note': note,
      'used_for_date': DateTime.now().toIso8601String().split('T').first,
    });
    ref.invalidateSelf();
  }
}

// ─── Agenda ──────────────────────────────────────────────────────────────────

final agendaProvider = FutureProvider<List<TaskModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.studentTasksAgenda);
  return (response.data as List)
      .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ─── Progress ────────────────────────────────────────────────────────────────

final progressProvider = FutureProvider<ProgressModel>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.studentProgress);
  return ProgressModel.fromJson(response.data as Map<String, dynamic>);
});

final heatmapProvider = FutureProvider.family<List<HeatmapDay>, ({int year, int month})>(
  (ref, args) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      ApiConstants.studentProgressHeatmap,
      queryParameters: {'year': args.year, 'month': args.month},
    );
    return (response.data as List)
        .map((j) => HeatmapDay.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

// ─── Jokers history ──────────────────────────────────────────────────────────

final jokersHistoryProvider = FutureProvider<List<JokerUsageModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.studentJokers);
  return (response.data as List)
      .map((j) => JokerUsageModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ─── Sync queue flusher ──────────────────────────────────────────────────────

final isOfflineForStudentProvider = Provider<bool>((ref) => false); // Simplified

LocalTasksCompanion _toLocalCompanion(TaskModel t) => LocalTasksCompanion(
      id: Value(t.id),
      programId: Value(t.programId),
      studentId: Value(t.studentId),
      pillar: Value(t.pillar == TaskPillar.quran ? 'QURAN' : 'ARABIC'),
      taskType: Value(t.taskType.name.toUpperCase()),
      title: Value(t.title),
      description: Value(t.description),
      surahName: Value(t.surahName),
      surahNumber: Value(t.surahNumber),
      verseStart: Value(t.verseStart),
      verseEnd: Value(t.verseEnd),
      bookRef: Value(t.bookRef?.apiValue),
      chapterNumber: Value(t.chapterNumber),
      pageStart: Value(t.pageStart),
      pageEnd: Value(t.pageEnd),
      dueDate: Value(t.dueDate.toIso8601String().split('T').first),
      status: Value(t.status.name.toUpperCase()),
    );

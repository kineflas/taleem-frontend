import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/user_model.dart';
import '../../shared/models/task_model.dart';

// ─── Students ───────────────────────────────────────────────────────────────

final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<StudentOverview>>(
  () => StudentsNotifier(),
);

class StudentsNotifier extends AsyncNotifier<List<StudentOverview>> {
  @override
  Future<List<StudentOverview>> build() => _fetch();

  Future<List<StudentOverview>> _fetch() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiConstants.teacherStudents);
    return (response.data as List)
        .map((j) => StudentOverview.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String> generateInviteCode() async {
    final dio = ref.read(dioProvider);
    final response = await dio.post(ApiConstants.teacherInvite);
    return response.data['code'] as String;
  }

  Future<void> removeStudent(String studentId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('${ApiConstants.teacherStudents}/$studentId');
    await refresh();
  }
}

// ─── Student detail ─────────────────────────────────────────────────────────

final studentDetailProvider = FutureProvider.family<StudentOverview, String>(
  (ref, studentId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('${ApiConstants.teacherStudents}/$studentId/overview');
    return StudentOverview.fromJson(response.data as Map<String, dynamic>);
  },
);

// ─── Teacher tasks ───────────────────────────────────────────────────────────

final teacherTasksProvider = FutureProvider.family<List<TaskModel>, String>(
  (ref, studentId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      ApiConstants.teacherTasks,
      queryParameters: {'student_id': studentId},
    );
    return (response.data as List)
        .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

// ─── Quran last task (continuity) ────────────────────────────────────────────

final quranLastTaskProvider = FutureProvider.family<TaskModel?, String>(
  (ref, studentId) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('${ApiConstants.quranLastForStudent}/$studentId');
      if (response.data == null) return null;
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  },
);

// ─── Task creation ───────────────────────────────────────────────────────────

final taskCreationProvider = AsyncNotifierProvider<TaskCreationNotifier, void>(
  () => TaskCreationNotifier(),
);

class TaskCreationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTask(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.tasks, data: payload);
      ref.invalidate(studentsProvider);
    });
  }

  Future<void> skipTask(String taskId) async {
    final dio = ref.read(dioProvider);
    await dio.patch('${ApiConstants.tasks}/$taskId/skip');
    ref.invalidate(teacherTasksProvider);
  }
}

// ─── Surahs ─────────────────────────────────────────────────────────────────

final surahsProvider = FutureProvider<List<SurahModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/quran/surahs');
  return (response.data as List)
      .map((j) => SurahModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ─── Student feedback ────────────────────────────────────────────────────────

final studentFeedbackProvider = FutureProvider.family<List<TaskCompletionModel>, String>(
  (ref, studentId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/teacher/students/$studentId/feedback');
    return (response.data as List)
        .map((j) => TaskCompletionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/curriculum_model.dart';

// ── API calls ──────────────────────────────────────────────────────────────

class CurriculumApi {
  final Dio _client;
  CurriculumApi(this._client);

  Future<List<CurriculumProgram>> fetchPrograms() async {
    final res = await _client.get('/curriculum/programs');
    return (res.data as List).map((j) => CurriculumProgram.fromJson(j)).toList();
  }

  Future<List<CurriculumUnit>> fetchUnits(String curriculumType) async {
    final res = await _client.get('/curriculum/programs/$curriculumType/units');
    return (res.data as List).map((j) => CurriculumUnit.fromJson(j)).toList();
  }

  Future<CurriculumUnit> fetchUnitDetail(String unitId) async {
    final res = await _client.get('/curriculum/units/$unitId');
    return CurriculumUnit.fromJson(res.data);
  }

  Future<CurriculumItem> fetchItem(String itemId) async {
    final res = await _client.get('/curriculum/items/$itemId');
    return CurriculumItem.fromJson(res.data);
  }

  // Student endpoints
  Future<List<StudentEnrollment>> fetchMyEnrollments() async {
    final res = await _client.get('/student/curriculum/enrollments');
    return (res.data as List).map((j) => StudentEnrollment.fromJson(j)).toList();
  }

  Future<StudentEnrollment> enroll(String programId, {DateTime? targetEndAt}) async {
    final res = await _client.post('/student/curriculum/enroll', data: {
      'curriculum_program_id': programId,
      if (targetEndAt != null) 'target_end_at': targetEndAt.toIso8601String().split('T')[0],
    });
    return StudentEnrollment.fromJson(res.data);
  }

  Future<EnrollmentProgress> fetchProgress(String enrollmentId) async {
    final res = await _client.get('/student/curriculum/enrollments/$enrollmentId/progress');
    return EnrollmentProgress.fromJson(res.data);
  }

  Future<Map<String, dynamic>> fetchNextItem(String enrollmentId) async {
    final res = await _client.get('/student/curriculum/enrollments/$enrollmentId/next-item');
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> completeItem(String itemId, {String? enrollmentId, int? masteryLevel}) async {
    await _client.post(
      '/student/curriculum/items/$itemId/complete',
      queryParameters: enrollmentId != null ? {'enrollment_id': enrollmentId} : null,
      data: {'mastery_level': masteryLevel},
    );
  }

  Future<StudentSubmission> createSubmission({
    required String enrollmentId,
    String? curriculumItemId,
    String? audioUrl,
    String? textContent,
  }) async {
    final res = await _client.post('/student/curriculum/submissions', data: {
      'enrollment_id': enrollmentId,
      if (curriculumItemId != null) 'curriculum_item_id': curriculumItemId,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (textContent != null) 'text_content': textContent,
    });
    return StudentSubmission.fromJson(res.data);
  }

  Future<List<StudentSubmission>> fetchMySubmissions() async {
    final res = await _client.get('/student/curriculum/submissions');
    return (res.data as List).map((j) => StudentSubmission.fromJson(j)).toList();
  }

  // Teacher endpoints
  Future<List<StudentEnrollment>> fetchStudentEnrollments(String studentId) async {
    final res = await _client.get('/teacher/curriculum/students/$studentId/enrollments');
    return (res.data as List).map((j) => StudentEnrollment.fromJson(j)).toList();
  }

  Future<StudentEnrollment> teacherEnroll(String studentId, String programId) async {
    final res = await _client.post(
        '/teacher/curriculum/students/$studentId/enroll',
        data: {'curriculum_program_id': programId, 'student_id': studentId});
    return StudentEnrollment.fromJson(res.data);
  }

  Future<EnrollmentProgress> fetchStudentProgress(String studentId, String enrollmentId) async {
    final res = await _client.get(
        '/teacher/curriculum/students/$studentId/progress/$enrollmentId');
    return EnrollmentProgress.fromJson(res.data);
  }

  Future<List<StudentSubmission>> fetchPendingSubmissions() async {
    final res = await _client.get('/teacher/curriculum/submissions',
        queryParameters: {'status_filter': 'PENDING_REVIEW'});
    return (res.data as List).map((j) => StudentSubmission.fromJson(j)).toList();
  }

  Future<StudentSubmission> reviewSubmission(
      String submissionId, String status, String? feedback) async {
    final res = await _client.patch('/teacher/curriculum/submissions/$submissionId/review',
        data: {'status': status, if (feedback != null) 'teacher_feedback': feedback});
    return StudentSubmission.fromJson(res.data);
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final curriculumApiProvider = Provider<CurriculumApi>(
  (ref) => CurriculumApi(ref.read(dioProvider)),
);

// All 5 programs
final curriculumProgramsProvider = FutureProvider<List<CurriculumProgram>>((ref) {
  return ref.read(curriculumApiProvider).fetchPrograms();
});

// Units for a given program type
final curriculumUnitsProvider =
    FutureProvider.family<List<CurriculumUnit>, String>((ref, type) {
  return ref.read(curriculumApiProvider).fetchUnits(type);
});

// Unit detail (with items)
final curriculumUnitDetailProvider =
    FutureProvider.family<CurriculumUnit, String>((ref, unitId) {
  return ref.read(curriculumApiProvider).fetchUnitDetail(unitId);
});

// Single item
final curriculumItemProvider =
    FutureProvider.family<CurriculumItem, String>((ref, itemId) {
  return ref.read(curriculumApiProvider).fetchItem(itemId);
});

// Student enrollments
final myEnrollmentsProvider = FutureProvider<List<StudentEnrollment>>((ref) {
  return ref.read(curriculumApiProvider).fetchMyEnrollments();
});

// Enrollment progress
final enrollmentProgressProvider =
    FutureProvider.family<EnrollmentProgress, String>((ref, enrollmentId) {
  return ref.read(curriculumApiProvider).fetchProgress(enrollmentId);
});

// My submissions
final mySubmissionsProvider = FutureProvider<List<StudentSubmission>>((ref) {
  return ref.read(curriculumApiProvider).fetchMySubmissions();
});

// Teacher: pending submissions
final teacherPendingSubmissionsProvider = FutureProvider<List<StudentSubmission>>((ref) {
  return ref.read(curriculumApiProvider).fetchPendingSubmissions();
});

// Teacher: student enrollments
final studentEnrollmentsProvider =
    FutureProvider.family<List<StudentEnrollment>, String>((ref, studentId) {
  return ref.read(curriculumApiProvider).fetchStudentEnrollments(studentId);
});

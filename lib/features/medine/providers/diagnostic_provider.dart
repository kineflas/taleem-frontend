import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/diagnostic_models.dart';

// ── API Service ───────────────────────────────────────────────────────────

class DiagnosticApi {
  final Dio _client;
  DiagnosticApi(this._client);

  /// Start a new diagnostic session
  Future<DiagnosticSession> startSession() async {
    final res = await _client.post(ApiConstants.diagnosticStart);
    return DiagnosticSession.fromJson(res.data);
  }

  /// Answer a diagnostic question
  Future<DiagnosticAnswerResponse> submitAnswer(
    String sessionId, {
    required String questionId,
    required int selected,
  }) async {
    final res = await _client.post(
      ApiConstants.diagnosticAnswer(sessionId),
      data: {'question_id': questionId, 'selected': selected},
    );
    return DiagnosticAnswerResponse.fromJson(res.data);
  }

  /// Get final diagnostic result
  Future<DiagnosticResult> getResult(String sessionId) async {
    final res = await _client.get(ApiConstants.diagnosticResult(sessionId));
    return DiagnosticResult.fromJson(res.data);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final diagnosticApiProvider = Provider<DiagnosticApi>(
  (ref) => DiagnosticApi(ref.read(dioProvider)),
);

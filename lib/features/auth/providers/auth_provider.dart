import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthTokenModel?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthTokenModel?> {
  @override
  Future<AuthTokenModel?> build() async {
    final storage = ref.read(localStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return null;

    // Restore from local (minimal user rebuild from prefs)
    final id = await storage.getUserId();
    final role = await storage.getUserRole();
    if (id == null || role == null) return null;

    // Try fetching current user profile to validate token
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/me');
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      final refreshToken = await storage.getRefreshToken();
      return AuthTokenModel(
        accessToken: token,
        refreshToken: refreshToken ?? '',
        user: user,
      );
    } catch (_) {
      await storage.clear();
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final storage = ref.read(localStorageProvider);

      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final auth = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
      await storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      await storage.saveUserInfo(
        id: auth.user.id,
        name: auth.user.fullName,
        role: auth.role,
        isChildProfile: auth.user.isChildProfile,
      );
      return auth;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final storage = ref.read(localStorageProvider);

      final response = await dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role == UserRole.teacher ? 'TEACHER' : 'STUDENT',
        },
      );

      final auth = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
      await storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      await storage.saveUserInfo(
        id: auth.user.id,
        name: auth.user.fullName,
        role: auth.role,
        isChildProfile: auth.user.isChildProfile,
      );
      return auth;
    });
  }

  Future<void> logout() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.logout);
    } catch (_) {}
    final storage = ref.read(localStorageProvider);
    await storage.clear();
    state = const AsyncData(null);
  }

  Future<void> linkInvitationCode(String code) async {
    final dio = ref.read(dioProvider);
    await dio.post('/student/link', data: {'invitation_code': code});
    ref.invalidateSelf();
  }

  Future<bool> setParentPin(String pin) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.setParentPin, data: {'pin': pin});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> verifyParentPin(String pin) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        ApiConstants.verifyParentPin,
        data: {'pin': pin},
      );
      return response.data['parent_token'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final isTeacherProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.teacher;
});

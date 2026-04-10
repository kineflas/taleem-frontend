import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

class LocalStorage {
  static const _accessToken = 'access_token';
  static const _refreshToken = 'refresh_token';
  static const _userRole = 'user_role';
  static const _userId = 'user_id';
  static const _userName = 'user_name';
  static const _isChildProfile = 'is_child_profile';
  static const _notifHour = 'notif_hour';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessToken, accessToken);
    await prefs.setString(_refreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshToken);
  }

  Future<void> saveUserInfo({
    required String id,
    required String name,
    required String role,
    required bool isChildProfile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, id);
    await prefs.setString(_userName, name);
    await prefs.setString(_userRole, role);
    await prefs.setBool(_isChildProfile, isChildProfile);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userId);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRole);
  }

  Future<bool> getIsChildProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isChildProfile) ?? false;
  }

  Future<int> getNotifHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifHour) ?? 18;
  }

  Future<void> setNotifHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifHour, hour);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

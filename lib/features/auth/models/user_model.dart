import 'package:equatable/equatable.dart';

enum UserRole { teacher, student }

enum TaskPillar { quran, arabic, both }

enum TaskType { memorization, revision, reading, grammar, vocabulary }

enum TaskStatus { pending, completed, missed, skipped }

enum JokerReason { illness, travel, family, other }

enum BookRef {
  medinaTome1,
  medinaTome2,
  medinaTome3,
  norania,
  qaidaBaghdadiya,
  other,
}

extension BookRefLabel on BookRef {
  String get label {
    switch (this) {
      case BookRef.medinaTome1:
        return "Cours d'arabe de Médine — Tome 1";
      case BookRef.medinaTome2:
        return "Cours d'arabe de Médine — Tome 2";
      case BookRef.medinaTome3:
        return "Cours d'arabe de Médine — Tome 3";
      case BookRef.norania:
        return "Qa'ida Nourania";
      case BookRef.qaidaBaghdadiya:
        return "Qa'ida Baghdadiya";
      case BookRef.other:
        return 'Autre';
    }
  }

  String get apiValue {
    switch (this) {
      case BookRef.medinaTome1:
        return 'MEDINA_T1';
      case BookRef.medinaTome2:
        return 'MEDINA_T2';
      case BookRef.medinaTome3:
        return 'MEDINA_T3';
      case BookRef.norania:
        return 'NORANIA';
      case BookRef.qaidaBaghdadiya:
        return 'QAIDA_BAGHDADIYA';
      case BookRef.other:
        return 'OTHER';
    }
  }

  static BookRef fromApi(String value) {
    switch (value) {
      case 'MEDINA_T1':
        return BookRef.medinaTome1;
      case 'MEDINA_T2':
        return BookRef.medinaTome2;
      case 'MEDINA_T3':
        return BookRef.medinaTome3;
      case 'NORANIA':
        return BookRef.norania;
      case 'QAIDA_BAGHDADIYA':
        return BookRef.qaidaBaghdadiya;
      default:
        return BookRef.other;
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String locale;
  final bool isActive;
  final bool isChildProfile;
  final bool hasParentPin;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.locale = 'ar',
    this.isActive = true,
    this.isChildProfile = false,
    this.hasParentPin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] == 'TEACHER' ? UserRole.teacher : UserRole.student,
      avatarUrl: json['avatar_url'] as String?,
      locale: json['locale'] as String? ?? 'ar',
      isActive: json['is_active'] as bool? ?? true,
      isChildProfile: json['is_child_profile'] as bool? ?? false,
      hasParentPin: json['has_parent_pin'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, role, isChildProfile];
}

class AuthTokenModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  String get role => user.role == UserRole.teacher ? 'TEACHER' : 'STUDENT';

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [accessToken, user];
}

class StudentOverview extends Equatable {
  final UserModel student;
  final int tasksToday;
  final int completedToday;
  final int pendingToday;
  final int currentStreak;
  final int jokersLeft;
  final int unreadHardFeedback;
  final bool isChildProfile;

  const StudentOverview({
    required this.student,
    required this.tasksToday,
    required this.completedToday,
    required this.pendingToday,
    required this.currentStreak,
    required this.jokersLeft,
    required this.unreadHardFeedback,
    required this.isChildProfile,
  });

  factory StudentOverview.fromJson(Map<String, dynamic> json) {
    return StudentOverview(
      student: UserModel.fromJson(json['student'] as Map<String, dynamic>),
      tasksToday: json['tasks_today'] as int? ?? 0,
      completedToday: json['completed_today'] as int? ?? 0,
      pendingToday: json['pending_today'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      jokersLeft: json['jokers_left'] as int? ?? 0,
      unreadHardFeedback: json['unread_hard_feedback'] as int? ?? 0,
      isChildProfile: json['is_child_profile'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [student.id];
}

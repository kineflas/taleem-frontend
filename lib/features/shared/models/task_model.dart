import 'package:equatable/equatable.dart';
import '../../auth/models/user_model.dart';

class SurahModel extends Equatable {
  final int number;
  final String nameAr;
  final String nameFr;
  final int totalVerses;
  final int juzNumber;
  final bool isMeccan;

  const SurahModel({
    required this.number,
    required this.nameAr,
    required this.nameFr,
    required this.totalVerses,
    required this.juzNumber,
    required this.isMeccan,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['surah_number'] as int,
      nameAr: json['surah_name_ar'] as String,
      nameFr: json['surah_name_fr'] as String,
      totalVerses: json['total_verses'] as int,
      juzNumber: json['juz_number'] as int,
      isMeccan: json['is_meccan'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [number];
}

class TaskModel extends Equatable {
  final String id;
  final String programId;
  final String teacherId;
  final String studentId;
  final TaskPillar pillar;
  final TaskType taskType;
  final String title;
  final String? description;

  // Quran fields
  final int? surahNumber;
  final String? surahName;
  final int? verseStart;
  final int? verseEnd;

  // Arabic fields
  final BookRef? bookRef;
  final int? chapterNumber;
  final String? chapterTitle;
  final int? pageStart;
  final int? pageEnd;
  final String? customRef;

  // Scheduling
  final DateTime dueDate;
  final DateTime? scheduledDate;

  // Status
  final TaskStatus status;
  final DateTime createdAt;

  // Completion data (if completed)
  final TaskCompletionModel? completion;

  const TaskModel({
    required this.id,
    required this.programId,
    required this.teacherId,
    required this.studentId,
    required this.pillar,
    required this.taskType,
    required this.title,
    this.description,
    this.surahNumber,
    this.surahName,
    this.verseStart,
    this.verseEnd,
    this.bookRef,
    this.chapterNumber,
    this.chapterTitle,
    this.pageStart,
    this.pageEnd,
    this.customRef,
    required this.dueDate,
    this.scheduledDate,
    required this.status,
    required this.createdAt,
    this.completion,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      teacherId: json['teacher_id'] as String,
      studentId: json['student_id'] as String,
      pillar: _pillarFromApi(json['pillar'] as String),
      taskType: _typeFromApi(json['task_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      surahNumber: json['surah_number'] as int?,
      surahName: json['surah_name'] as String?,
      verseStart: json['verse_start'] as int?,
      verseEnd: json['verse_end'] as int?,
      bookRef: json['book_ref'] != null ? BookRefLabel.fromApi(json['book_ref'] as String) : null,
      chapterNumber: json['chapter_number'] as int?,
      chapterTitle: json['chapter_title'] as String?,
      pageStart: json['page_start'] as int?,
      pageEnd: json['page_end'] as int?,
      customRef: json['custom_ref'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      status: _statusFromApi(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completion: json['completion'] != null
          ? TaskCompletionModel.fromJson(json['completion'] as Map<String, dynamic>)
          : null,
    );
  }

  String get subtitleDisplay {
    if (pillar == TaskPillar.quran && surahName != null) {
      final parts = <String>[surahName!];
      if (verseStart != null && verseEnd != null) {
        parts.add('Versets $verseStart → $verseEnd');
      }
      return parts.join(' · ');
    } else if (pillar == TaskPillar.arabic) {
      final parts = <String>[];
      if (bookRef != null) parts.add(bookRef!.label);
      if (chapterNumber != null) parts.add('Leçon $chapterNumber');
      if (pageStart != null && pageEnd != null) {
        parts.add('Pages $pageStart → $pageEnd');
      }
      return parts.join(' · ');
    }
    return title;
  }

  static TaskPillar _pillarFromApi(String v) {
    switch (v) {
      case 'ARABIC':
        return TaskPillar.arabic;
      default:
        return TaskPillar.quran;
    }
  }

  static TaskType _typeFromApi(String v) {
    switch (v) {
      case 'REVISION':
        return TaskType.revision;
      case 'READING':
        return TaskType.reading;
      case 'GRAMMAR':
        return TaskType.grammar;
      case 'VOCABULARY':
        return TaskType.vocabulary;
      default:
        return TaskType.memorization;
    }
  }

  static TaskStatus _statusFromApi(String v) {
    switch (v) {
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'MISSED':
        return TaskStatus.missed;
      case 'SKIPPED':
        return TaskStatus.skipped;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  List<Object?> get props => [id, status];
}

class TaskCompletionModel extends Equatable {
  final String id;
  final String taskId;
  final DateTime completedAt;
  final int? difficulty;
  final String? studentNote;
  final bool teacherRead;
  final bool parentValidated;

  const TaskCompletionModel({
    required this.id,
    required this.taskId,
    required this.completedAt,
    this.difficulty,
    this.studentNote,
    this.teacherRead = false,
    this.parentValidated = false,
  });

  factory TaskCompletionModel.fromJson(Map<String, dynamic> json) {
    return TaskCompletionModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      difficulty: json['difficulty'] as int?,
      studentNote: json['student_note'] as String?,
      teacherRead: json['teacher_read'] as bool? ?? false,
      parentValidated: json['parent_validated'] as bool? ?? false,
    );
  }

  String get difficultyEmoji {
    switch (difficulty) {
      case 1:
        return '😊';
      case 2:
        return '😐';
      case 3:
        return '😓';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [id];
}

class StreakModel extends Equatable {
  final String studentId;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime lastActivityDate;
  final int totalCompletedTasks;
  final int jokersTotal;
  final int jokersUsedThisMonth;
  final DateTime jokersResetAt;

  int get jokersLeft => jokersTotal - jokersUsedThisMonth;
  bool get hasJokersLeft => jokersLeft > 0;

  const StreakModel({
    required this.studentId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastActivityDate,
    required this.totalCompletedTasks,
    required this.jokersTotal,
    required this.jokersUsedThisMonth,
    required this.jokersResetAt,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      studentId: json['student_id'] as String,
      currentStreakDays: json['current_streak_days'] as int? ?? 0,
      longestStreakDays: json['longest_streak_days'] as int? ?? 0,
      lastActivityDate: DateTime.parse(json['last_activity_date'] as String),
      totalCompletedTasks: json['total_completed_tasks'] as int? ?? 0,
      jokersTotal: json['jokers_total'] as int? ?? 3,
      jokersUsedThisMonth: json['jokers_used_this_month'] as int? ?? 0,
      jokersResetAt: DateTime.parse(json['jokers_reset_at'] as String),
    );
  }

  @override
  List<Object?> get props => [studentId, currentStreakDays, jokersUsedThisMonth];
}

class JokerUsageModel extends Equatable {
  final String id;
  final String studentId;
  final DateTime usedForDate;
  final JokerReason reason;
  final String? note;
  final DateTime createdAt;

  const JokerUsageModel({
    required this.id,
    required this.studentId,
    required this.usedForDate,
    required this.reason,
    this.note,
    required this.createdAt,
  });

  factory JokerUsageModel.fromJson(Map<String, dynamic> json) {
    return JokerUsageModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      usedForDate: DateTime.parse(json['used_for_date'] as String),
      reason: _reasonFromApi(json['reason'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static JokerReason _reasonFromApi(String v) {
    switch (v) {
      case 'ILLNESS':
        return JokerReason.illness;
      case 'TRAVEL':
        return JokerReason.travel;
      case 'FAMILY':
        return JokerReason.family;
      default:
        return JokerReason.other;
    }
  }

  String get reasonLabel {
    switch (reason) {
      case JokerReason.illness:
        return '🤒 Maladie';
      case JokerReason.travel:
        return '✈️ Voyage';
      case JokerReason.family:
        return '👨‍👩‍👧 Obligations familiales';
      case JokerReason.other:
        return '💬 Autre';
    }
  }

  @override
  List<Object?> get props => [id];
}

class HeatmapDay extends Equatable {
  final DateTime date;
  final int completedCount;
  final bool jokerUsed;
  final bool hasMissed;
  final bool hasSkipped;

  const HeatmapDay({
    required this.date,
    required this.completedCount,
    required this.jokerUsed,
    required this.hasMissed,
    required this.hasSkipped,
  });

  factory HeatmapDay.fromJson(Map<String, dynamic> json) {
    return HeatmapDay(
      date: DateTime.parse(json['date'] as String),
      completedCount: json['completed_count'] as int? ?? 0,
      jokerUsed: json['joker_used'] as bool? ?? false,
      hasMissed: json['has_missed'] as bool? ?? false,
      hasSkipped: json['has_skipped'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [date];
}

class NotificationModel extends Equatable {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final String? relatedTaskId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedTaskId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedTaskId: json['related_task_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, isRead];
}

class ProgressModel extends Equatable {
  final int surahsWorked;
  final int versesMemorized;
  final int versesRevised;
  final String? lastQuranTask;
  final String? currentBook;
  final int? lessonsCompleted;
  final int? totalLessons;
  final String? lastArabicTask;
  final int tasksThisMonth;
  final int totalTasksThisMonth;

  const ProgressModel({
    required this.surahsWorked,
    required this.versesMemorized,
    required this.versesRevised,
    this.lastQuranTask,
    this.currentBook,
    this.lessonsCompleted,
    this.totalLessons,
    this.lastArabicTask,
    required this.tasksThisMonth,
    required this.totalTasksThisMonth,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      surahsWorked: json['surahs_worked'] as int? ?? 0,
      versesMemorized: json['verses_memorized'] as int? ?? 0,
      versesRevised: json['verses_revised'] as int? ?? 0,
      lastQuranTask: json['last_quran_task'] as String?,
      currentBook: json['current_book'] as String?,
      lessonsCompleted: json['lessons_completed'] as int?,
      totalLessons: json['total_lessons'] as int?,
      lastArabicTask: json['last_arabic_task'] as String?,
      tasksThisMonth: json['tasks_this_month'] as int? ?? 0,
      totalTasksThisMonth: json['total_tasks_this_month'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [surahsWorked, versesMemorized, tasksThisMonth];
}

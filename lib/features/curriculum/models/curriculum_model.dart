import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ProgramCategory {
  apprendreALire,
  comprendreArabe,
  coran;

  static ProgramCategory fromApi(String v) {
    switch (v) {
      case 'APPRENDRE_A_LIRE': return apprendreALire;
      case 'COMPRENDRE_ARABE': return comprendreArabe;
      case 'CORAN': return coran;
      default: return apprendreALire;
    }
  }

  String get titleFr {
    switch (this) {
      case ProgramCategory.apprendreALire: return 'Apprendre à lire';
      case ProgramCategory.comprendreArabe: return "Comprendre l'arabe";
      case ProgramCategory.coran: return 'Lire et Apprendre le Coran';
    }
  }

  IconData get icon {
    switch (this) {
      case ProgramCategory.apprendreALire: return Icons.menu_book;
      case ProgramCategory.comprendreArabe: return Icons.school;
      case ProgramCategory.coran: return Icons.auto_stories;
    }
  }

  Color get color {
    switch (this) {
      case ProgramCategory.apprendreALire: return const Color(0xFF2196F3);
      case ProgramCategory.comprendreArabe: return const Color(0xFF4CAF50);
      case ProgramCategory.coran: return const Color(0xFF9C27B0);
    }
  }
}

enum CurriculumType {
  alphabetArabe,
  voyellesSyllabes,
  qaidaNourania,
  medineT1,
  tajwid,
  hifzRevision;

  String get apiValue {
    switch (this) {
      case CurriculumType.alphabetArabe: return 'ALPHABET_ARABE';
      case CurriculumType.voyellesSyllabes: return 'VOYELLES_SYLLABES';
      case CurriculumType.qaidaNourania: return 'QAIDA_NOURANIA';
      case CurriculumType.medineT1: return 'MEDINE_T1';
      case CurriculumType.tajwid: return 'TAJWID';
      case CurriculumType.hifzRevision: return 'HIFZ_REVISION';
    }
  }

  static CurriculumType fromApi(String v) => CurriculumType.values.firstWhere(
    (e) => e.apiValue == v,
    orElse: () => CurriculumType.alphabetArabe,
  );

  String get icon {
    switch (this) {
      case CurriculumType.alphabetArabe: return '🔤';
      case CurriculumType.voyellesSyllabes: return '🗣️';
      case CurriculumType.qaidaNourania: return '📖';
      case CurriculumType.medineT1: return '🎓';
      case CurriculumType.tajwid: return '🎵';
      case CurriculumType.hifzRevision: return '📿';
    }
  }
}

enum ItemType {
  letterForm, combination, rule, vocabulary, grammarPoint, surahSegment, example;

  static ItemType fromApi(String v) {
    switch (v) {
      case 'LETTER_FORM': return ItemType.letterForm;
      case 'COMBINATION': return ItemType.combination;
      case 'RULE': return ItemType.rule;
      case 'VOCABULARY': return ItemType.vocabulary;
      case 'GRAMMAR_POINT': return ItemType.grammarPoint;
      case 'SURAH_SEGMENT': return ItemType.surahSegment;
      case 'EXAMPLE': return ItemType.example;
      default: return ItemType.rule;
    }
  }
}

enum EnrollmentMode { teacherAssigned, studentAutonomous;
  static EnrollmentMode fromApi(String v) =>
      v == 'TEACHER_ASSIGNED' ? teacherAssigned : studentAutonomous;
}

enum SubmissionStatus { pendingReview, approved, needsImprovement, rejected;
  static SubmissionStatus fromApi(String v) {
    switch (v) {
      case 'APPROVED': return approved;
      case 'NEEDS_IMPROVEMENT': return needsImprovement;
      case 'REJECTED': return rejected;
      default: return pendingReview;
    }
  }

  String get label {
    switch (this) {
      case SubmissionStatus.pendingReview: return 'En attente';
      case SubmissionStatus.approved: return 'Approuvé ✅';
      case SubmissionStatus.needsImprovement: return 'À améliorer 🔄';
      case SubmissionStatus.rejected: return 'Rejeté ❌';
    }
  }
}

// ── Content models ─────────────────────────────────────────────────────────

class CurriculumProgram {
  final String id;
  final CurriculumType curriculumType;
  final ProgramCategory category;
  final String titleAr;
  final String titleFr;
  final String? descriptionFr;
  final int totalUnits;
  final String? coverImageUrl;
  final bool isActive;
  final int sortOrder;

  const CurriculumProgram({
    required this.id,
    required this.curriculumType,
    required this.category,
    required this.titleAr,
    required this.titleFr,
    this.descriptionFr,
    required this.totalUnits,
    this.coverImageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory CurriculumProgram.fromJson(Map<String, dynamic> j) => CurriculumProgram(
    id: j['id'],
    curriculumType: CurriculumType.fromApi(j['curriculum_type']),
    category: ProgramCategory.fromApi(j['category'] ?? 'APPRENDRE_A_LIRE'),
    titleAr: j['title_ar'],
    titleFr: j['title_fr'],
    descriptionFr: j['description_fr'],
    totalUnits: j['total_units'] ?? 0,
    coverImageUrl: j['cover_image_url'],
    isActive: j['is_active'] ?? true,
    sortOrder: j['sort_order'] ?? 0,
  );
}

class CurriculumUnit {
  final String id;
  final String curriculumProgramId;
  final String unitType;
  final int number;
  final String titleAr;
  final String? titleFr;
  final String? descriptionFr;
  final String? audioUrl;
  final int totalItems;
  final int sortOrder;
  final List<CurriculumItem> items;

  const CurriculumUnit({
    required this.id,
    required this.curriculumProgramId,
    required this.unitType,
    required this.number,
    required this.titleAr,
    this.titleFr,
    this.descriptionFr,
    this.audioUrl,
    required this.totalItems,
    required this.sortOrder,
    this.items = const [],
  });

  factory CurriculumUnit.fromJson(Map<String, dynamic> j) => CurriculumUnit(
    id: j['id'],
    curriculumProgramId: j['curriculum_program_id'],
    unitType: j['unit_type'],
    number: j['number'],
    titleAr: j['title_ar'],
    titleFr: j['title_fr'],
    descriptionFr: j['description_fr'],
    audioUrl: j['audio_url'],
    totalItems: j['total_items'] ?? 0,
    sortOrder: j['sort_order'] ?? 0,
    items: (j['items'] as List<dynamic>? ?? [])
        .map((i) => CurriculumItem.fromJson(i))
        .toList(),
  );
}

class CurriculumItem {
  final String id;
  final String curriculumUnitId;
  final ItemType itemType;
  final int number;
  final String titleAr;
  final String? titleFr;
  final String? contentAr;
  final String? contentFr;
  final String? transliteration;
  final String? audioUrl;
  final String? imageUrl;
  final int? surahNumber;
  final int? verseStart;
  final int? verseEnd;
  final String? letterPosition;
  final Map<String, dynamic>? metadata;
  final int sortOrder;

  const CurriculumItem({
    required this.id,
    required this.curriculumUnitId,
    required this.itemType,
    required this.number,
    required this.titleAr,
    this.titleFr,
    this.contentAr,
    this.contentFr,
    this.transliteration,
    this.audioUrl,
    this.imageUrl,
    this.surahNumber,
    this.verseStart,
    this.verseEnd,
    this.letterPosition,
    this.metadata,
    required this.sortOrder,
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> j) => CurriculumItem(
    id: j['id'],
    curriculumUnitId: j['curriculum_unit_id'],
    itemType: ItemType.fromApi(j['item_type']),
    number: j['number'],
    titleAr: j['title_ar'],
    titleFr: j['title_fr'],
    contentAr: j['content_ar'],
    contentFr: j['content_fr'],
    transliteration: j['transliteration'],
    audioUrl: j['audio_url'],
    imageUrl: j['image_url'],
    surahNumber: j['surah_number'],
    verseStart: j['verse_start'],
    verseEnd: j['verse_end'],
    letterPosition: j['letter_position'],
    metadata: j['metadata'] != null ? Map<String, dynamic>.from(j['metadata']) : null,
    sortOrder: j['sort_order'] ?? 0,
  );
}

// ── Enrollment & Progress models ──────────────────────────────────────────

class StudentEnrollment {
  final String id;
  final String studentId;
  final String curriculumProgramId;
  final String? teacherId;
  final EnrollmentMode mode;
  final DateTime startedAt;
  final DateTime? targetEndAt;
  final String? currentUnitId;
  final String? currentItemId;
  final bool isActive;
  final CurriculumProgram program;

  const StudentEnrollment({
    required this.id,
    required this.studentId,
    required this.curriculumProgramId,
    this.teacherId,
    required this.mode,
    required this.startedAt,
    this.targetEndAt,
    this.currentUnitId,
    this.currentItemId,
    required this.isActive,
    required this.program,
  });

  factory StudentEnrollment.fromJson(Map<String, dynamic> j) => StudentEnrollment(
    id: j['id'],
    studentId: j['student_id'],
    curriculumProgramId: j['curriculum_program_id'],
    teacherId: j['teacher_id'],
    mode: EnrollmentMode.fromApi(j['mode']),
    startedAt: DateTime.parse(j['started_at']),
    targetEndAt: j['target_end_at'] != null ? DateTime.parse(j['target_end_at']) : null,
    currentUnitId: j['current_unit_id'],
    currentItemId: j['current_item_id'],
    isActive: j['is_active'] ?? true,
    program: CurriculumProgram.fromJson(j['program']),
  );
}

class ItemProgress {
  final String id;
  final String curriculumItemId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? masteryLevel;
  final int attemptCount;
  final bool teacherValidated;
  final DateTime? teacherValidatedAt;

  const ItemProgress({
    required this.id,
    required this.curriculumItemId,
    required this.isCompleted,
    this.completedAt,
    this.masteryLevel,
    required this.attemptCount,
    required this.teacherValidated,
    this.teacherValidatedAt,
  });

  factory ItemProgress.fromJson(Map<String, dynamic> j) => ItemProgress(
    id: j['id'],
    curriculumItemId: j['curriculum_item_id'],
    isCompleted: j['is_completed'] ?? false,
    completedAt: j['completed_at'] != null ? DateTime.parse(j['completed_at']) : null,
    masteryLevel: j['mastery_level'],
    attemptCount: j['attempt_count'] ?? 0,
    teacherValidated: j['teacher_validated'] ?? false,
    teacherValidatedAt: j['teacher_validated_at'] != null
        ? DateTime.parse(j['teacher_validated_at']) : null,
  );
}

class UnitProgress {
  final CurriculumUnit unit;
  final int totalItems;
  final int completedItems;
  final double completionPct;
  final List<ItemProgress> itemsProgress;

  const UnitProgress({
    required this.unit,
    required this.totalItems,
    required this.completedItems,
    required this.completionPct,
    required this.itemsProgress,
  });

  factory UnitProgress.fromJson(Map<String, dynamic> j) => UnitProgress(
    unit: CurriculumUnit.fromJson(j['unit']),
    totalItems: j['total_items'],
    completedItems: j['completed_items'],
    completionPct: (j['completion_pct'] as num).toDouble(),
    itemsProgress: (j['items_progress'] as List)
        .map((i) => ItemProgress.fromJson(i)).toList(),
  );
}

class EnrollmentProgress {
  final StudentEnrollment enrollment;
  final int totalItems;
  final int completedItems;
  final double completionPct;
  final List<UnitProgress> units;

  const EnrollmentProgress({
    required this.enrollment,
    required this.totalItems,
    required this.completedItems,
    required this.completionPct,
    required this.units,
  });

  factory EnrollmentProgress.fromJson(Map<String, dynamic> j) => EnrollmentProgress(
    enrollment: StudentEnrollment.fromJson(j['enrollment']),
    totalItems: j['total_items'],
    completedItems: j['completed_items'],
    completionPct: (j['completion_pct'] as num).toDouble(),
    units: (j['units'] as List).map((u) => UnitProgress.fromJson(u)).toList(),
  );
}

class StudentSubmission {
  final String id;
  final String studentId;
  final String? teacherId;
  final String enrollmentId;
  final String? curriculumItemId;
  final String? audioUrl;
  final String? textContent;
  final SubmissionStatus status;
  final String? teacherFeedback;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const StudentSubmission({
    required this.id,
    required this.studentId,
    this.teacherId,
    required this.enrollmentId,
    this.curriculumItemId,
    this.audioUrl,
    this.textContent,
    required this.status,
    this.teacherFeedback,
    this.reviewedAt,
    required this.createdAt,
  });

  factory StudentSubmission.fromJson(Map<String, dynamic> j) => StudentSubmission(
    id: j['id'],
    studentId: j['student_id'],
    teacherId: j['teacher_id'],
    enrollmentId: j['enrollment_id'],
    curriculumItemId: j['curriculum_item_id'],
    audioUrl: j['audio_url'],
    textContent: j['text_content'],
    status: SubmissionStatus.fromApi(j['status']),
    teacherFeedback: j['teacher_feedback'],
    reviewedAt: j['reviewed_at'] != null ? DateTime.parse(j['reviewed_at']) : null,
    createdAt: DateTime.parse(j['created_at']),
  );
}

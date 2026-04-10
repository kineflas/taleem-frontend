import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

part 'app_database.g.dart';

// ─── Tables ────────────────────────────────────────────────────────────────

class LocalTasks extends Table {
  TextColumn get id => text()();
  TextColumn get programId => text()();
  TextColumn get studentId => text()();
  TextColumn get pillar => text()();
  TextColumn get taskType => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get surahName => text().nullable()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get verseStart => integer().nullable()();
  IntColumn get verseEnd => integer().nullable()();
  TextColumn get bookRef => text().nullable()();
  IntColumn get chapterNumber => integer().nullable()();
  IntColumn get pageStart => integer().nullable()();
  IntColumn get pageEnd => integer().nullable()();
  TextColumn get dueDate => text()();
  TextColumn get status => text()();
  TextColumn get completionJson => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSyncs extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  IntColumn get difficulty => integer().nullable()();
  TextColumn get studentNote => text().nullable()();
  BoolColumn get parentValidated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalStreak extends Table {
  TextColumn get studentId => text()();
  IntColumn get currentStreakDays => integer()();
  IntColumn get longestStreakDays => integer()();
  IntColumn get jokersTotal => integer()();
  IntColumn get jokersUsedThisMonth => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {studentId};
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [LocalTasks, PendingSyncs, LocalStreak])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Tasks
  Future<List<LocalTask>> getTasksForToday(String today) {
    return (select(localTasks)..where((t) => t.dueDate.equals(today))).get();
  }

  Future<List<LocalTask>> getUpcomingTasks(String fromDate) {
    return (select(localTasks)
          ..where((t) => t.dueDate.isBiggerOrEqualValue(fromDate))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  Future<void> upsertTasks(List<LocalTasksCompanion> tasks) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localTasks, tasks);
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) {
    return (update(localTasks)..where((t) => t.id.equals(taskId)))
        .write(LocalTasksCompanion(status: Value(status)));
  }

  // Pending sync
  Future<void> addPendingSync(PendingSyncsCompanion sync) =>
      into(pendingSyncs).insert(sync);

  Future<List<PendingSync>> getPendingSyncs() =>
      (select(pendingSyncs)..where((s) => s.synced.equals(false))).get();

  Future<void> markSyncDone(String syncId) {
    return (update(pendingSyncs)..where((s) => s.id.equals(syncId)))
        .write(const PendingSyncsCompanion(synced: Value(true)));
  }

  // Streak
  Future<LocalStreak?> getStreak(String studentId) =>
      (select(localStreak)..where((s) => s.studentId.equals(studentId)))
          .getSingleOrNull();

  Future<void> upsertStreak(LocalStreakCompanion streak) =>
      into(localStreak).insertOnConflictUpdate(streak);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web: in-memory (not used for offline, but needed for compilation)
      return NativeDatabase.memory();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'taliem.db'));
    return NativeDatabase(file);
  });
}

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());

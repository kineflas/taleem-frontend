// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalTasksTable extends LocalTasks
    with TableInfo<$LocalTasksTable, LocalTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _programIdMeta =
      const VerificationMeta('programId');
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
      'program_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pillarMeta = const VerificationMeta('pillar');
  @override
  late final GeneratedColumn<String> pillar = GeneratedColumn<String>(
      'pillar', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
      'task_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _surahNameMeta =
      const VerificationMeta('surahName');
  @override
  late final GeneratedColumn<String> surahName = GeneratedColumn<String>(
      'surah_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _surahNumberMeta =
      const VerificationMeta('surahNumber');
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
      'surah_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _verseStartMeta =
      const VerificationMeta('verseStart');
  @override
  late final GeneratedColumn<int> verseStart = GeneratedColumn<int>(
      'verse_start', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _verseEndMeta =
      const VerificationMeta('verseEnd');
  @override
  late final GeneratedColumn<int> verseEnd = GeneratedColumn<int>(
      'verse_end', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bookRefMeta =
      const VerificationMeta('bookRef');
  @override
  late final GeneratedColumn<String> bookRef = GeneratedColumn<String>(
      'book_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chapterNumberMeta =
      const VerificationMeta('chapterNumber');
  @override
  late final GeneratedColumn<int> chapterNumber = GeneratedColumn<int>(
      'chapter_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageStartMeta =
      const VerificationMeta('pageStart');
  @override
  late final GeneratedColumn<int> pageStart = GeneratedColumn<int>(
      'page_start', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageEndMeta =
      const VerificationMeta('pageEnd');
  @override
  late final GeneratedColumn<int> pageEnd = GeneratedColumn<int>(
      'page_end', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
      'due_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completionJsonMeta =
      const VerificationMeta('completionJson');
  @override
  late final GeneratedColumn<String> completionJson = GeneratedColumn<String>(
      'completion_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        programId,
        studentId,
        pillar,
        taskType,
        title,
        description,
        surahName,
        surahNumber,
        verseStart,
        verseEnd,
        bookRef,
        chapterNumber,
        pageStart,
        pageEnd,
        dueDate,
        status,
        completionJson,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(_programIdMeta,
          programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta));
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('pillar')) {
      context.handle(_pillarMeta,
          pillar.isAcceptableOrUnknown(data['pillar']!, _pillarMeta));
    } else if (isInserting) {
      context.missing(_pillarMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('surah_name')) {
      context.handle(_surahNameMeta,
          surahName.isAcceptableOrUnknown(data['surah_name']!, _surahNameMeta));
    }
    if (data.containsKey('surah_number')) {
      context.handle(
          _surahNumberMeta,
          surahNumber.isAcceptableOrUnknown(
              data['surah_number']!, _surahNumberMeta));
    }
    if (data.containsKey('verse_start')) {
      context.handle(
          _verseStartMeta,
          verseStart.isAcceptableOrUnknown(
              data['verse_start']!, _verseStartMeta));
    }
    if (data.containsKey('verse_end')) {
      context.handle(_verseEndMeta,
          verseEnd.isAcceptableOrUnknown(data['verse_end']!, _verseEndMeta));
    }
    if (data.containsKey('book_ref')) {
      context.handle(_bookRefMeta,
          bookRef.isAcceptableOrUnknown(data['book_ref']!, _bookRefMeta));
    }
    if (data.containsKey('chapter_number')) {
      context.handle(
          _chapterNumberMeta,
          chapterNumber.isAcceptableOrUnknown(
              data['chapter_number']!, _chapterNumberMeta));
    }
    if (data.containsKey('page_start')) {
      context.handle(_pageStartMeta,
          pageStart.isAcceptableOrUnknown(data['page_start']!, _pageStartMeta));
    }
    if (data.containsKey('page_end')) {
      context.handle(_pageEndMeta,
          pageEnd.isAcceptableOrUnknown(data['page_end']!, _pageEndMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('completion_json')) {
      context.handle(
          _completionJsonMeta,
          completionJson.isAcceptableOrUnknown(
              data['completion_json']!, _completionJsonMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      programId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      pillar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pillar'])!,
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      surahName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surah_name']),
      surahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_number']),
      verseStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_start']),
      verseEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_end']),
      bookRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_ref']),
      chapterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_number']),
      pageStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_start']),
      pageEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_end']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}due_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      completionJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completion_json']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LocalTasksTable createAlias(String alias) {
    return $LocalTasksTable(attachedDatabase, alias);
  }
}

class LocalTask extends DataClass implements Insertable<LocalTask> {
  final String id;
  final String programId;
  final String studentId;
  final String pillar;
  final String taskType;
  final String title;
  final String? description;
  final String? surahName;
  final int? surahNumber;
  final int? verseStart;
  final int? verseEnd;
  final String? bookRef;
  final int? chapterNumber;
  final int? pageStart;
  final int? pageEnd;
  final String dueDate;
  final String status;
  final String? completionJson;
  final DateTime? syncedAt;
  const LocalTask(
      {required this.id,
      required this.programId,
      required this.studentId,
      required this.pillar,
      required this.taskType,
      required this.title,
      this.description,
      this.surahName,
      this.surahNumber,
      this.verseStart,
      this.verseEnd,
      this.bookRef,
      this.chapterNumber,
      this.pageStart,
      this.pageEnd,
      required this.dueDate,
      required this.status,
      this.completionJson,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['program_id'] = Variable<String>(programId);
    map['student_id'] = Variable<String>(studentId);
    map['pillar'] = Variable<String>(pillar);
    map['task_type'] = Variable<String>(taskType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || surahName != null) {
      map['surah_name'] = Variable<String>(surahName);
    }
    if (!nullToAbsent || surahNumber != null) {
      map['surah_number'] = Variable<int>(surahNumber);
    }
    if (!nullToAbsent || verseStart != null) {
      map['verse_start'] = Variable<int>(verseStart);
    }
    if (!nullToAbsent || verseEnd != null) {
      map['verse_end'] = Variable<int>(verseEnd);
    }
    if (!nullToAbsent || bookRef != null) {
      map['book_ref'] = Variable<String>(bookRef);
    }
    if (!nullToAbsent || chapterNumber != null) {
      map['chapter_number'] = Variable<int>(chapterNumber);
    }
    if (!nullToAbsent || pageStart != null) {
      map['page_start'] = Variable<int>(pageStart);
    }
    if (!nullToAbsent || pageEnd != null) {
      map['page_end'] = Variable<int>(pageEnd);
    }
    map['due_date'] = Variable<String>(dueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completionJson != null) {
      map['completion_json'] = Variable<String>(completionJson);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalTasksCompanion toCompanion(bool nullToAbsent) {
    return LocalTasksCompanion(
      id: Value(id),
      programId: Value(programId),
      studentId: Value(studentId),
      pillar: Value(pillar),
      taskType: Value(taskType),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      surahName: surahName == null && nullToAbsent
          ? const Value.absent()
          : Value(surahName),
      surahNumber: surahNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(surahNumber),
      verseStart: verseStart == null && nullToAbsent
          ? const Value.absent()
          : Value(verseStart),
      verseEnd: verseEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(verseEnd),
      bookRef: bookRef == null && nullToAbsent
          ? const Value.absent()
          : Value(bookRef),
      chapterNumber: chapterNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterNumber),
      pageStart: pageStart == null && nullToAbsent
          ? const Value.absent()
          : Value(pageStart),
      pageEnd: pageEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(pageEnd),
      dueDate: Value(dueDate),
      status: Value(status),
      completionJson: completionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(completionJson),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTask(
      id: serializer.fromJson<String>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      pillar: serializer.fromJson<String>(json['pillar']),
      taskType: serializer.fromJson<String>(json['taskType']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      surahName: serializer.fromJson<String?>(json['surahName']),
      surahNumber: serializer.fromJson<int?>(json['surahNumber']),
      verseStart: serializer.fromJson<int?>(json['verseStart']),
      verseEnd: serializer.fromJson<int?>(json['verseEnd']),
      bookRef: serializer.fromJson<String?>(json['bookRef']),
      chapterNumber: serializer.fromJson<int?>(json['chapterNumber']),
      pageStart: serializer.fromJson<int?>(json['pageStart']),
      pageEnd: serializer.fromJson<int?>(json['pageEnd']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      completionJson: serializer.fromJson<String?>(json['completionJson']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'programId': serializer.toJson<String>(programId),
      'studentId': serializer.toJson<String>(studentId),
      'pillar': serializer.toJson<String>(pillar),
      'taskType': serializer.toJson<String>(taskType),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'surahName': serializer.toJson<String?>(surahName),
      'surahNumber': serializer.toJson<int?>(surahNumber),
      'verseStart': serializer.toJson<int?>(verseStart),
      'verseEnd': serializer.toJson<int?>(verseEnd),
      'bookRef': serializer.toJson<String?>(bookRef),
      'chapterNumber': serializer.toJson<int?>(chapterNumber),
      'pageStart': serializer.toJson<int?>(pageStart),
      'pageEnd': serializer.toJson<int?>(pageEnd),
      'dueDate': serializer.toJson<String>(dueDate),
      'status': serializer.toJson<String>(status),
      'completionJson': serializer.toJson<String?>(completionJson),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalTask copyWith(
          {String? id,
          String? programId,
          String? studentId,
          String? pillar,
          String? taskType,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> surahName = const Value.absent(),
          Value<int?> surahNumber = const Value.absent(),
          Value<int?> verseStart = const Value.absent(),
          Value<int?> verseEnd = const Value.absent(),
          Value<String?> bookRef = const Value.absent(),
          Value<int?> chapterNumber = const Value.absent(),
          Value<int?> pageStart = const Value.absent(),
          Value<int?> pageEnd = const Value.absent(),
          String? dueDate,
          String? status,
          Value<String?> completionJson = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      LocalTask(
        id: id ?? this.id,
        programId: programId ?? this.programId,
        studentId: studentId ?? this.studentId,
        pillar: pillar ?? this.pillar,
        taskType: taskType ?? this.taskType,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        surahName: surahName.present ? surahName.value : this.surahName,
        surahNumber: surahNumber.present ? surahNumber.value : this.surahNumber,
        verseStart: verseStart.present ? verseStart.value : this.verseStart,
        verseEnd: verseEnd.present ? verseEnd.value : this.verseEnd,
        bookRef: bookRef.present ? bookRef.value : this.bookRef,
        chapterNumber:
            chapterNumber.present ? chapterNumber.value : this.chapterNumber,
        pageStart: pageStart.present ? pageStart.value : this.pageStart,
        pageEnd: pageEnd.present ? pageEnd.value : this.pageEnd,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        completionJson:
            completionJson.present ? completionJson.value : this.completionJson,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  LocalTask copyWithCompanion(LocalTasksCompanion data) {
    return LocalTask(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      pillar: data.pillar.present ? data.pillar.value : this.pillar,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      surahName: data.surahName.present ? data.surahName.value : this.surahName,
      surahNumber:
          data.surahNumber.present ? data.surahNumber.value : this.surahNumber,
      verseStart:
          data.verseStart.present ? data.verseStart.value : this.verseStart,
      verseEnd: data.verseEnd.present ? data.verseEnd.value : this.verseEnd,
      bookRef: data.bookRef.present ? data.bookRef.value : this.bookRef,
      chapterNumber: data.chapterNumber.present
          ? data.chapterNumber.value
          : this.chapterNumber,
      pageStart: data.pageStart.present ? data.pageStart.value : this.pageStart,
      pageEnd: data.pageEnd.present ? data.pageEnd.value : this.pageEnd,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      completionJson: data.completionJson.present
          ? data.completionJson.value
          : this.completionJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTask(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('studentId: $studentId, ')
          ..write('pillar: $pillar, ')
          ..write('taskType: $taskType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surahName: $surahName, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('verseStart: $verseStart, ')
          ..write('verseEnd: $verseEnd, ')
          ..write('bookRef: $bookRef, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('pageStart: $pageStart, ')
          ..write('pageEnd: $pageEnd, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('completionJson: $completionJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      programId,
      studentId,
      pillar,
      taskType,
      title,
      description,
      surahName,
      surahNumber,
      verseStart,
      verseEnd,
      bookRef,
      chapterNumber,
      pageStart,
      pageEnd,
      dueDate,
      status,
      completionJson,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTask &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.studentId == this.studentId &&
          other.pillar == this.pillar &&
          other.taskType == this.taskType &&
          other.title == this.title &&
          other.description == this.description &&
          other.surahName == this.surahName &&
          other.surahNumber == this.surahNumber &&
          other.verseStart == this.verseStart &&
          other.verseEnd == this.verseEnd &&
          other.bookRef == this.bookRef &&
          other.chapterNumber == this.chapterNumber &&
          other.pageStart == this.pageStart &&
          other.pageEnd == this.pageEnd &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.completionJson == this.completionJson &&
          other.syncedAt == this.syncedAt);
}

class LocalTasksCompanion extends UpdateCompanion<LocalTask> {
  final Value<String> id;
  final Value<String> programId;
  final Value<String> studentId;
  final Value<String> pillar;
  final Value<String> taskType;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> surahName;
  final Value<int?> surahNumber;
  final Value<int?> verseStart;
  final Value<int?> verseEnd;
  final Value<String?> bookRef;
  final Value<int?> chapterNumber;
  final Value<int?> pageStart;
  final Value<int?> pageEnd;
  final Value<String> dueDate;
  final Value<String> status;
  final Value<String?> completionJson;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalTasksCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.pillar = const Value.absent(),
    this.taskType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.surahName = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.verseStart = const Value.absent(),
    this.verseEnd = const Value.absent(),
    this.bookRef = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.pageStart = const Value.absent(),
    this.pageEnd = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.completionJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTasksCompanion.insert({
    required String id,
    required String programId,
    required String studentId,
    required String pillar,
    required String taskType,
    required String title,
    this.description = const Value.absent(),
    this.surahName = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.verseStart = const Value.absent(),
    this.verseEnd = const Value.absent(),
    this.bookRef = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.pageStart = const Value.absent(),
    this.pageEnd = const Value.absent(),
    required String dueDate,
    required String status,
    this.completionJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        programId = Value(programId),
        studentId = Value(studentId),
        pillar = Value(pillar),
        taskType = Value(taskType),
        title = Value(title),
        dueDate = Value(dueDate),
        status = Value(status);
  static Insertable<LocalTask> custom({
    Expression<String>? id,
    Expression<String>? programId,
    Expression<String>? studentId,
    Expression<String>? pillar,
    Expression<String>? taskType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? surahName,
    Expression<int>? surahNumber,
    Expression<int>? verseStart,
    Expression<int>? verseEnd,
    Expression<String>? bookRef,
    Expression<int>? chapterNumber,
    Expression<int>? pageStart,
    Expression<int>? pageEnd,
    Expression<String>? dueDate,
    Expression<String>? status,
    Expression<String>? completionJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (studentId != null) 'student_id': studentId,
      if (pillar != null) 'pillar': pillar,
      if (taskType != null) 'task_type': taskType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (surahName != null) 'surah_name': surahName,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (verseStart != null) 'verse_start': verseStart,
      if (verseEnd != null) 'verse_end': verseEnd,
      if (bookRef != null) 'book_ref': bookRef,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      if (pageStart != null) 'page_start': pageStart,
      if (pageEnd != null) 'page_end': pageEnd,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (completionJson != null) 'completion_json': completionJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? programId,
      Value<String>? studentId,
      Value<String>? pillar,
      Value<String>? taskType,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? surahName,
      Value<int?>? surahNumber,
      Value<int?>? verseStart,
      Value<int?>? verseEnd,
      Value<String?>? bookRef,
      Value<int?>? chapterNumber,
      Value<int?>? pageStart,
      Value<int?>? pageEnd,
      Value<String>? dueDate,
      Value<String>? status,
      Value<String?>? completionJson,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return LocalTasksCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      studentId: studentId ?? this.studentId,
      pillar: pillar ?? this.pillar,
      taskType: taskType ?? this.taskType,
      title: title ?? this.title,
      description: description ?? this.description,
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      verseStart: verseStart ?? this.verseStart,
      verseEnd: verseEnd ?? this.verseEnd,
      bookRef: bookRef ?? this.bookRef,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      pageStart: pageStart ?? this.pageStart,
      pageEnd: pageEnd ?? this.pageEnd,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completionJson: completionJson ?? this.completionJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (pillar.present) {
      map['pillar'] = Variable<String>(pillar.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (surahName.present) {
      map['surah_name'] = Variable<String>(surahName.value);
    }
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (verseStart.present) {
      map['verse_start'] = Variable<int>(verseStart.value);
    }
    if (verseEnd.present) {
      map['verse_end'] = Variable<int>(verseEnd.value);
    }
    if (bookRef.present) {
      map['book_ref'] = Variable<String>(bookRef.value);
    }
    if (chapterNumber.present) {
      map['chapter_number'] = Variable<int>(chapterNumber.value);
    }
    if (pageStart.present) {
      map['page_start'] = Variable<int>(pageStart.value);
    }
    if (pageEnd.present) {
      map['page_end'] = Variable<int>(pageEnd.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completionJson.present) {
      map['completion_json'] = Variable<String>(completionJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTasksCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('studentId: $studentId, ')
          ..write('pillar: $pillar, ')
          ..write('taskType: $taskType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surahName: $surahName, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('verseStart: $verseStart, ')
          ..write('verseEnd: $verseEnd, ')
          ..write('bookRef: $bookRef, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('pageStart: $pageStart, ')
          ..write('pageEnd: $pageEnd, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('completionJson: $completionJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncsTable extends PendingSyncs
    with TableInfo<$PendingSyncsTable, PendingSync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _studentNoteMeta =
      const VerificationMeta('studentNote');
  @override
  late final GeneratedColumn<String> studentNote = GeneratedColumn<String>(
      'student_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentValidatedMeta =
      const VerificationMeta('parentValidated');
  @override
  late final GeneratedColumn<bool> parentValidated = GeneratedColumn<bool>(
      'parent_validated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("parent_validated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, taskId, difficulty, studentNote, parentValidated, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_syncs';
  @override
  VerificationContext validateIntegrity(Insertable<PendingSync> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('student_note')) {
      context.handle(
          _studentNoteMeta,
          studentNote.isAcceptableOrUnknown(
              data['student_note']!, _studentNoteMeta));
    }
    if (data.containsKey('parent_validated')) {
      context.handle(
          _parentValidatedMeta,
          parentValidated.isAcceptableOrUnknown(
              data['parent_validated']!, _parentValidatedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSync(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty']),
      studentNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_note']),
      parentValidated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}parent_validated'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $PendingSyncsTable createAlias(String alias) {
    return $PendingSyncsTable(attachedDatabase, alias);
  }
}

class PendingSync extends DataClass implements Insertable<PendingSync> {
  final String id;
  final String taskId;
  final int? difficulty;
  final String? studentNote;
  final bool parentValidated;
  final DateTime createdAt;
  final bool synced;
  const PendingSync(
      {required this.id,
      required this.taskId,
      this.difficulty,
      this.studentNote,
      required this.parentValidated,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<int>(difficulty);
    }
    if (!nullToAbsent || studentNote != null) {
      map['student_note'] = Variable<String>(studentNote);
    }
    map['parent_validated'] = Variable<bool>(parentValidated);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PendingSyncsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      studentNote: studentNote == null && nullToAbsent
          ? const Value.absent()
          : Value(studentNote),
      parentValidated: Value(parentValidated),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory PendingSync.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSync(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      difficulty: serializer.fromJson<int?>(json['difficulty']),
      studentNote: serializer.fromJson<String?>(json['studentNote']),
      parentValidated: serializer.fromJson<bool>(json['parentValidated']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'difficulty': serializer.toJson<int?>(difficulty),
      'studentNote': serializer.toJson<String?>(studentNote),
      'parentValidated': serializer.toJson<bool>(parentValidated),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  PendingSync copyWith(
          {String? id,
          String? taskId,
          Value<int?> difficulty = const Value.absent(),
          Value<String?> studentNote = const Value.absent(),
          bool? parentValidated,
          DateTime? createdAt,
          bool? synced}) =>
      PendingSync(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        difficulty: difficulty.present ? difficulty.value : this.difficulty,
        studentNote: studentNote.present ? studentNote.value : this.studentNote,
        parentValidated: parentValidated ?? this.parentValidated,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  PendingSync copyWithCompanion(PendingSyncsCompanion data) {
    return PendingSync(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      studentNote:
          data.studentNote.present ? data.studentNote.value : this.studentNote,
      parentValidated: data.parentValidated.present
          ? data.parentValidated.value
          : this.parentValidated,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSync(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('difficulty: $difficulty, ')
          ..write('studentNote: $studentNote, ')
          ..write('parentValidated: $parentValidated, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, taskId, difficulty, studentNote, parentValidated, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSync &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.difficulty == this.difficulty &&
          other.studentNote == this.studentNote &&
          other.parentValidated == this.parentValidated &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class PendingSyncsCompanion extends UpdateCompanion<PendingSync> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<int?> difficulty;
  final Value<String?> studentNote;
  final Value<bool> parentValidated;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const PendingSyncsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.studentNote = const Value.absent(),
    this.parentValidated = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSyncsCompanion.insert({
    required String id,
    required String taskId,
    this.difficulty = const Value.absent(),
    this.studentNote = const Value.absent(),
    this.parentValidated = const Value.absent(),
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        taskId = Value(taskId),
        createdAt = Value(createdAt);
  static Insertable<PendingSync> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<int>? difficulty,
    Expression<String>? studentNote,
    Expression<bool>? parentValidated,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (difficulty != null) 'difficulty': difficulty,
      if (studentNote != null) 'student_note': studentNote,
      if (parentValidated != null) 'parent_validated': parentValidated,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSyncsCompanion copyWith(
      {Value<String>? id,
      Value<String>? taskId,
      Value<int?>? difficulty,
      Value<String?>? studentNote,
      Value<bool>? parentValidated,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return PendingSyncsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      difficulty: difficulty ?? this.difficulty,
      studentNote: studentNote ?? this.studentNote,
      parentValidated: parentValidated ?? this.parentValidated,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (studentNote.present) {
      map['student_note'] = Variable<String>(studentNote.value);
    }
    if (parentValidated.present) {
      map['parent_validated'] = Variable<bool>(parentValidated.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('difficulty: $difficulty, ')
          ..write('studentNote: $studentNote, ')
          ..write('parentValidated: $parentValidated, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStreakTable extends LocalStreak
    with TableInfo<$LocalStreakTable, LocalStreakData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStreakTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentStreakDaysMeta =
      const VerificationMeta('currentStreakDays');
  @override
  late final GeneratedColumn<int> currentStreakDays = GeneratedColumn<int>(
      'current_streak_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _longestStreakDaysMeta =
      const VerificationMeta('longestStreakDays');
  @override
  late final GeneratedColumn<int> longestStreakDays = GeneratedColumn<int>(
      'longest_streak_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _jokersTotalMeta =
      const VerificationMeta('jokersTotal');
  @override
  late final GeneratedColumn<int> jokersTotal = GeneratedColumn<int>(
      'jokers_total', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _jokersUsedThisMonthMeta =
      const VerificationMeta('jokersUsedThisMonth');
  @override
  late final GeneratedColumn<int> jokersUsedThisMonth = GeneratedColumn<int>(
      'jokers_used_this_month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        studentId,
        currentStreakDays,
        longestStreakDays,
        jokersTotal,
        jokersUsedThisMonth,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_streak';
  @override
  VerificationContext validateIntegrity(Insertable<LocalStreakData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('current_streak_days')) {
      context.handle(
          _currentStreakDaysMeta,
          currentStreakDays.isAcceptableOrUnknown(
              data['current_streak_days']!, _currentStreakDaysMeta));
    } else if (isInserting) {
      context.missing(_currentStreakDaysMeta);
    }
    if (data.containsKey('longest_streak_days')) {
      context.handle(
          _longestStreakDaysMeta,
          longestStreakDays.isAcceptableOrUnknown(
              data['longest_streak_days']!, _longestStreakDaysMeta));
    } else if (isInserting) {
      context.missing(_longestStreakDaysMeta);
    }
    if (data.containsKey('jokers_total')) {
      context.handle(
          _jokersTotalMeta,
          jokersTotal.isAcceptableOrUnknown(
              data['jokers_total']!, _jokersTotalMeta));
    } else if (isInserting) {
      context.missing(_jokersTotalMeta);
    }
    if (data.containsKey('jokers_used_this_month')) {
      context.handle(
          _jokersUsedThisMonthMeta,
          jokersUsedThisMonth.isAcceptableOrUnknown(
              data['jokers_used_this_month']!, _jokersUsedThisMonthMeta));
    } else if (isInserting) {
      context.missing(_jokersUsedThisMonthMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {studentId};
  @override
  LocalStreakData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStreakData(
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      currentStreakDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_streak_days'])!,
      longestStreakDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}longest_streak_days'])!,
      jokersTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jokers_total'])!,
      jokersUsedThisMonth: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}jokers_used_this_month'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalStreakTable createAlias(String alias) {
    return $LocalStreakTable(attachedDatabase, alias);
  }
}

class LocalStreakData extends DataClass implements Insertable<LocalStreakData> {
  final String studentId;
  final int currentStreakDays;
  final int longestStreakDays;
  final int jokersTotal;
  final int jokersUsedThisMonth;
  final DateTime updatedAt;
  const LocalStreakData(
      {required this.studentId,
      required this.currentStreakDays,
      required this.longestStreakDays,
      required this.jokersTotal,
      required this.jokersUsedThisMonth,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['student_id'] = Variable<String>(studentId);
    map['current_streak_days'] = Variable<int>(currentStreakDays);
    map['longest_streak_days'] = Variable<int>(longestStreakDays);
    map['jokers_total'] = Variable<int>(jokersTotal);
    map['jokers_used_this_month'] = Variable<int>(jokersUsedThisMonth);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalStreakCompanion toCompanion(bool nullToAbsent) {
    return LocalStreakCompanion(
      studentId: Value(studentId),
      currentStreakDays: Value(currentStreakDays),
      longestStreakDays: Value(longestStreakDays),
      jokersTotal: Value(jokersTotal),
      jokersUsedThisMonth: Value(jokersUsedThisMonth),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalStreakData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStreakData(
      studentId: serializer.fromJson<String>(json['studentId']),
      currentStreakDays: serializer.fromJson<int>(json['currentStreakDays']),
      longestStreakDays: serializer.fromJson<int>(json['longestStreakDays']),
      jokersTotal: serializer.fromJson<int>(json['jokersTotal']),
      jokersUsedThisMonth:
          serializer.fromJson<int>(json['jokersUsedThisMonth']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'studentId': serializer.toJson<String>(studentId),
      'currentStreakDays': serializer.toJson<int>(currentStreakDays),
      'longestStreakDays': serializer.toJson<int>(longestStreakDays),
      'jokersTotal': serializer.toJson<int>(jokersTotal),
      'jokersUsedThisMonth': serializer.toJson<int>(jokersUsedThisMonth),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalStreakData copyWith(
          {String? studentId,
          int? currentStreakDays,
          int? longestStreakDays,
          int? jokersTotal,
          int? jokersUsedThisMonth,
          DateTime? updatedAt}) =>
      LocalStreakData(
        studentId: studentId ?? this.studentId,
        currentStreakDays: currentStreakDays ?? this.currentStreakDays,
        longestStreakDays: longestStreakDays ?? this.longestStreakDays,
        jokersTotal: jokersTotal ?? this.jokersTotal,
        jokersUsedThisMonth: jokersUsedThisMonth ?? this.jokersUsedThisMonth,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalStreakData copyWithCompanion(LocalStreakCompanion data) {
    return LocalStreakData(
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      currentStreakDays: data.currentStreakDays.present
          ? data.currentStreakDays.value
          : this.currentStreakDays,
      longestStreakDays: data.longestStreakDays.present
          ? data.longestStreakDays.value
          : this.longestStreakDays,
      jokersTotal:
          data.jokersTotal.present ? data.jokersTotal.value : this.jokersTotal,
      jokersUsedThisMonth: data.jokersUsedThisMonth.present
          ? data.jokersUsedThisMonth.value
          : this.jokersUsedThisMonth,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStreakData(')
          ..write('studentId: $studentId, ')
          ..write('currentStreakDays: $currentStreakDays, ')
          ..write('longestStreakDays: $longestStreakDays, ')
          ..write('jokersTotal: $jokersTotal, ')
          ..write('jokersUsedThisMonth: $jokersUsedThisMonth, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(studentId, currentStreakDays,
      longestStreakDays, jokersTotal, jokersUsedThisMonth, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStreakData &&
          other.studentId == this.studentId &&
          other.currentStreakDays == this.currentStreakDays &&
          other.longestStreakDays == this.longestStreakDays &&
          other.jokersTotal == this.jokersTotal &&
          other.jokersUsedThisMonth == this.jokersUsedThisMonth &&
          other.updatedAt == this.updatedAt);
}

class LocalStreakCompanion extends UpdateCompanion<LocalStreakData> {
  final Value<String> studentId;
  final Value<int> currentStreakDays;
  final Value<int> longestStreakDays;
  final Value<int> jokersTotal;
  final Value<int> jokersUsedThisMonth;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalStreakCompanion({
    this.studentId = const Value.absent(),
    this.currentStreakDays = const Value.absent(),
    this.longestStreakDays = const Value.absent(),
    this.jokersTotal = const Value.absent(),
    this.jokersUsedThisMonth = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStreakCompanion.insert({
    required String studentId,
    required int currentStreakDays,
    required int longestStreakDays,
    required int jokersTotal,
    required int jokersUsedThisMonth,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : studentId = Value(studentId),
        currentStreakDays = Value(currentStreakDays),
        longestStreakDays = Value(longestStreakDays),
        jokersTotal = Value(jokersTotal),
        jokersUsedThisMonth = Value(jokersUsedThisMonth),
        updatedAt = Value(updatedAt);
  static Insertable<LocalStreakData> custom({
    Expression<String>? studentId,
    Expression<int>? currentStreakDays,
    Expression<int>? longestStreakDays,
    Expression<int>? jokersTotal,
    Expression<int>? jokersUsedThisMonth,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (studentId != null) 'student_id': studentId,
      if (currentStreakDays != null) 'current_streak_days': currentStreakDays,
      if (longestStreakDays != null) 'longest_streak_days': longestStreakDays,
      if (jokersTotal != null) 'jokers_total': jokersTotal,
      if (jokersUsedThisMonth != null)
        'jokers_used_this_month': jokersUsedThisMonth,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStreakCompanion copyWith(
      {Value<String>? studentId,
      Value<int>? currentStreakDays,
      Value<int>? longestStreakDays,
      Value<int>? jokersTotal,
      Value<int>? jokersUsedThisMonth,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalStreakCompanion(
      studentId: studentId ?? this.studentId,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      jokersTotal: jokersTotal ?? this.jokersTotal,
      jokersUsedThisMonth: jokersUsedThisMonth ?? this.jokersUsedThisMonth,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (currentStreakDays.present) {
      map['current_streak_days'] = Variable<int>(currentStreakDays.value);
    }
    if (longestStreakDays.present) {
      map['longest_streak_days'] = Variable<int>(longestStreakDays.value);
    }
    if (jokersTotal.present) {
      map['jokers_total'] = Variable<int>(jokersTotal.value);
    }
    if (jokersUsedThisMonth.present) {
      map['jokers_used_this_month'] = Variable<int>(jokersUsedThisMonth.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStreakCompanion(')
          ..write('studentId: $studentId, ')
          ..write('currentStreakDays: $currentStreakDays, ')
          ..write('longestStreakDays: $longestStreakDays, ')
          ..write('jokersTotal: $jokersTotal, ')
          ..write('jokersUsedThisMonth: $jokersUsedThisMonth, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTasksTable localTasks = $LocalTasksTable(this);
  late final $PendingSyncsTable pendingSyncs = $PendingSyncsTable(this);
  late final $LocalStreakTable localStreak = $LocalStreakTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localTasks, pendingSyncs, localStreak];
}

typedef $$LocalTasksTableCreateCompanionBuilder = LocalTasksCompanion Function({
  required String id,
  required String programId,
  required String studentId,
  required String pillar,
  required String taskType,
  required String title,
  Value<String?> description,
  Value<String?> surahName,
  Value<int?> surahNumber,
  Value<int?> verseStart,
  Value<int?> verseEnd,
  Value<String?> bookRef,
  Value<int?> chapterNumber,
  Value<int?> pageStart,
  Value<int?> pageEnd,
  required String dueDate,
  required String status,
  Value<String?> completionJson,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$LocalTasksTableUpdateCompanionBuilder = LocalTasksCompanion Function({
  Value<String> id,
  Value<String> programId,
  Value<String> studentId,
  Value<String> pillar,
  Value<String> taskType,
  Value<String> title,
  Value<String?> description,
  Value<String?> surahName,
  Value<int?> surahNumber,
  Value<int?> verseStart,
  Value<int?> verseEnd,
  Value<String?> bookRef,
  Value<int?> chapterNumber,
  Value<int?> pageStart,
  Value<int?> pageEnd,
  Value<String> dueDate,
  Value<String> status,
  Value<String?> completionJson,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$LocalTasksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programId => $composableBuilder(
      column: $table.programId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pillar => $composableBuilder(
      column: $table.pillar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surahName => $composableBuilder(
      column: $table.surahName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseStart => $composableBuilder(
      column: $table.verseStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseEnd => $composableBuilder(
      column: $table.verseEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookRef => $composableBuilder(
      column: $table.bookRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageStart => $composableBuilder(
      column: $table.pageStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageEnd => $composableBuilder(
      column: $table.pageEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completionJson => $composableBuilder(
      column: $table.completionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programId => $composableBuilder(
      column: $table.programId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pillar => $composableBuilder(
      column: $table.pillar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surahName => $composableBuilder(
      column: $table.surahName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseStart => $composableBuilder(
      column: $table.verseStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseEnd => $composableBuilder(
      column: $table.verseEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookRef => $composableBuilder(
      column: $table.bookRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageStart => $composableBuilder(
      column: $table.pageStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageEnd => $composableBuilder(
      column: $table.pageEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completionJson => $composableBuilder(
      column: $table.completionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get pillar =>
      $composableBuilder(column: $table.pillar, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get surahName =>
      $composableBuilder(column: $table.surahName, builder: (column) => column);

  GeneratedColumn<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => column);

  GeneratedColumn<int> get verseStart => $composableBuilder(
      column: $table.verseStart, builder: (column) => column);

  GeneratedColumn<int> get verseEnd =>
      $composableBuilder(column: $table.verseEnd, builder: (column) => column);

  GeneratedColumn<String> get bookRef =>
      $composableBuilder(column: $table.bookRef, builder: (column) => column);

  GeneratedColumn<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber, builder: (column) => column);

  GeneratedColumn<int> get pageStart =>
      $composableBuilder(column: $table.pageStart, builder: (column) => column);

  GeneratedColumn<int> get pageEnd =>
      $composableBuilder(column: $table.pageEnd, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get completionJson => $composableBuilder(
      column: $table.completionJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()> {
  $$LocalTasksTableTableManager(_$AppDatabase db, $LocalTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> programId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> pillar = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> surahName = const Value.absent(),
            Value<int?> surahNumber = const Value.absent(),
            Value<int?> verseStart = const Value.absent(),
            Value<int?> verseEnd = const Value.absent(),
            Value<String?> bookRef = const Value.absent(),
            Value<int?> chapterNumber = const Value.absent(),
            Value<int?> pageStart = const Value.absent(),
            Value<int?> pageEnd = const Value.absent(),
            Value<String> dueDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> completionJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion(
            id: id,
            programId: programId,
            studentId: studentId,
            pillar: pillar,
            taskType: taskType,
            title: title,
            description: description,
            surahName: surahName,
            surahNumber: surahNumber,
            verseStart: verseStart,
            verseEnd: verseEnd,
            bookRef: bookRef,
            chapterNumber: chapterNumber,
            pageStart: pageStart,
            pageEnd: pageEnd,
            dueDate: dueDate,
            status: status,
            completionJson: completionJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String programId,
            required String studentId,
            required String pillar,
            required String taskType,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> surahName = const Value.absent(),
            Value<int?> surahNumber = const Value.absent(),
            Value<int?> verseStart = const Value.absent(),
            Value<int?> verseEnd = const Value.absent(),
            Value<String?> bookRef = const Value.absent(),
            Value<int?> chapterNumber = const Value.absent(),
            Value<int?> pageStart = const Value.absent(),
            Value<int?> pageEnd = const Value.absent(),
            required String dueDate,
            required String status,
            Value<String?> completionJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion.insert(
            id: id,
            programId: programId,
            studentId: studentId,
            pillar: pillar,
            taskType: taskType,
            title: title,
            description: description,
            surahName: surahName,
            surahNumber: surahNumber,
            verseStart: verseStart,
            verseEnd: verseEnd,
            bookRef: bookRef,
            chapterNumber: chapterNumber,
            pageStart: pageStart,
            pageEnd: pageEnd,
            dueDate: dueDate,
            status: status,
            completionJson: completionJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()>;
typedef $$PendingSyncsTableCreateCompanionBuilder = PendingSyncsCompanion
    Function({
  required String id,
  required String taskId,
  Value<int?> difficulty,
  Value<String?> studentNote,
  Value<bool> parentValidated,
  required DateTime createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$PendingSyncsTableUpdateCompanionBuilder = PendingSyncsCompanion
    Function({
  Value<String> id,
  Value<String> taskId,
  Value<int?> difficulty,
  Value<String?> studentNote,
  Value<bool> parentValidated,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$PendingSyncsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncsTable> {
  $$PendingSyncsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentNote => $composableBuilder(
      column: $table.studentNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get parentValidated => $composableBuilder(
      column: $table.parentValidated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$PendingSyncsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncsTable> {
  $$PendingSyncsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentNote => $composableBuilder(
      column: $table.studentNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get parentValidated => $composableBuilder(
      column: $table.parentValidated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$PendingSyncsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncsTable> {
  $$PendingSyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get studentNote => $composableBuilder(
      column: $table.studentNote, builder: (column) => column);

  GeneratedColumn<bool> get parentValidated => $composableBuilder(
      column: $table.parentValidated, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PendingSyncsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingSyncsTable,
    PendingSync,
    $$PendingSyncsTableFilterComposer,
    $$PendingSyncsTableOrderingComposer,
    $$PendingSyncsTableAnnotationComposer,
    $$PendingSyncsTableCreateCompanionBuilder,
    $$PendingSyncsTableUpdateCompanionBuilder,
    (
      PendingSync,
      BaseReferences<_$AppDatabase, $PendingSyncsTable, PendingSync>
    ),
    PendingSync,
    PrefetchHooks Function()> {
  $$PendingSyncsTableTableManager(_$AppDatabase db, $PendingSyncsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<int?> difficulty = const Value.absent(),
            Value<String?> studentNote = const Value.absent(),
            Value<bool> parentValidated = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingSyncsCompanion(
            id: id,
            taskId: taskId,
            difficulty: difficulty,
            studentNote: studentNote,
            parentValidated: parentValidated,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String taskId,
            Value<int?> difficulty = const Value.absent(),
            Value<String?> studentNote = const Value.absent(),
            Value<bool> parentValidated = const Value.absent(),
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingSyncsCompanion.insert(
            id: id,
            taskId: taskId,
            difficulty: difficulty,
            studentNote: studentNote,
            parentValidated: parentValidated,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingSyncsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingSyncsTable,
    PendingSync,
    $$PendingSyncsTableFilterComposer,
    $$PendingSyncsTableOrderingComposer,
    $$PendingSyncsTableAnnotationComposer,
    $$PendingSyncsTableCreateCompanionBuilder,
    $$PendingSyncsTableUpdateCompanionBuilder,
    (
      PendingSync,
      BaseReferences<_$AppDatabase, $PendingSyncsTable, PendingSync>
    ),
    PendingSync,
    PrefetchHooks Function()>;
typedef $$LocalStreakTableCreateCompanionBuilder = LocalStreakCompanion
    Function({
  required String studentId,
  required int currentStreakDays,
  required int longestStreakDays,
  required int jokersTotal,
  required int jokersUsedThisMonth,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalStreakTableUpdateCompanionBuilder = LocalStreakCompanion
    Function({
  Value<String> studentId,
  Value<int> currentStreakDays,
  Value<int> longestStreakDays,
  Value<int> jokersTotal,
  Value<int> jokersUsedThisMonth,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalStreakTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStreakTable> {
  $$LocalStreakTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreakDays => $composableBuilder(
      column: $table.currentStreakDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestStreakDays => $composableBuilder(
      column: $table.longestStreakDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jokersTotal => $composableBuilder(
      column: $table.jokersTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jokersUsedThisMonth => $composableBuilder(
      column: $table.jokersUsedThisMonth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalStreakTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStreakTable> {
  $$LocalStreakTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreakDays => $composableBuilder(
      column: $table.currentStreakDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestStreakDays => $composableBuilder(
      column: $table.longestStreakDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jokersTotal => $composableBuilder(
      column: $table.jokersTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jokersUsedThisMonth => $composableBuilder(
      column: $table.jokersUsedThisMonth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalStreakTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStreakTable> {
  $$LocalStreakTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<int> get currentStreakDays => $composableBuilder(
      column: $table.currentStreakDays, builder: (column) => column);

  GeneratedColumn<int> get longestStreakDays => $composableBuilder(
      column: $table.longestStreakDays, builder: (column) => column);

  GeneratedColumn<int> get jokersTotal => $composableBuilder(
      column: $table.jokersTotal, builder: (column) => column);

  GeneratedColumn<int> get jokersUsedThisMonth => $composableBuilder(
      column: $table.jokersUsedThisMonth, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalStreakTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalStreakTable,
    LocalStreakData,
    $$LocalStreakTableFilterComposer,
    $$LocalStreakTableOrderingComposer,
    $$LocalStreakTableAnnotationComposer,
    $$LocalStreakTableCreateCompanionBuilder,
    $$LocalStreakTableUpdateCompanionBuilder,
    (
      LocalStreakData,
      BaseReferences<_$AppDatabase, $LocalStreakTable, LocalStreakData>
    ),
    LocalStreakData,
    PrefetchHooks Function()> {
  $$LocalStreakTableTableManager(_$AppDatabase db, $LocalStreakTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStreakTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStreakTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStreakTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> studentId = const Value.absent(),
            Value<int> currentStreakDays = const Value.absent(),
            Value<int> longestStreakDays = const Value.absent(),
            Value<int> jokersTotal = const Value.absent(),
            Value<int> jokersUsedThisMonth = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStreakCompanion(
            studentId: studentId,
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            jokersTotal: jokersTotal,
            jokersUsedThisMonth: jokersUsedThisMonth,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String studentId,
            required int currentStreakDays,
            required int longestStreakDays,
            required int jokersTotal,
            required int jokersUsedThisMonth,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStreakCompanion.insert(
            studentId: studentId,
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            jokersTotal: jokersTotal,
            jokersUsedThisMonth: jokersUsedThisMonth,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalStreakTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalStreakTable,
    LocalStreakData,
    $$LocalStreakTableFilterComposer,
    $$LocalStreakTableOrderingComposer,
    $$LocalStreakTableAnnotationComposer,
    $$LocalStreakTableCreateCompanionBuilder,
    $$LocalStreakTableUpdateCompanionBuilder,
    (
      LocalStreakData,
      BaseReferences<_$AppDatabase, $LocalStreakTable, LocalStreakData>
    ),
    LocalStreakData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTasksTableTableManager get localTasks =>
      $$LocalTasksTableTableManager(_db, _db.localTasks);
  $$PendingSyncsTableTableManager get pendingSyncs =>
      $$PendingSyncsTableTableManager(_db, _db.pendingSyncs);
  $$LocalStreakTableTableManager get localStreak =>
      $$LocalStreakTableTableManager(_db, _db.localStreak);
}

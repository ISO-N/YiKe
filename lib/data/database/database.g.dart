// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LearningItemsTable extends LearningItems
    with TableInfo<$LearningItemsTable, LearningItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _learningDateMeta = const VerificationMeta(
    'learningDate',
  );
  @override
  late final GeneratedColumn<DateTime> learningDate = GeneratedColumn<DateTime>(
    'learning_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    tags,
    learningDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('learning_date')) {
      context.handle(
        _learningDateMeta,
        learningDate.isAcceptableOrUnknown(
          data['learning_date']!,
          _learningDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      learningDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}learning_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LearningItemsTable createAlias(String alias) {
    return $LearningItemsTable(attachedDatabase, alias);
  }
}

class LearningItem extends DataClass implements Insertable<LearningItem> {
  /// 主键 ID。
  final int id;

  /// 学习内容标题（必填，≤50字）。
  final String title;

  /// 备注内容（可选，v1.0 MVP 仅纯文本）。
  final String? note;

  /// 标签列表（JSON 字符串，如 ["Java","英语"]）。
  final String tags;

  /// 学习日期（首次录入日期，用于生成复习计划）。
  final DateTime learningDate;

  /// 创建时间。
  final DateTime createdAt;

  /// 更新时间（可空）。
  final DateTime? updatedAt;
  const LearningItem({
    required this.id,
    required this.title,
    this.note,
    required this.tags,
    required this.learningDate,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['tags'] = Variable<String>(tags);
    map['learning_date'] = Variable<DateTime>(learningDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LearningItemsCompanion toCompanion(bool nullToAbsent) {
    return LearningItemsCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tags: Value(tags),
      learningDate: Value(learningDate),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LearningItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      tags: serializer.fromJson<String>(json['tags']),
      learningDate: serializer.fromJson<DateTime>(json['learningDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'tags': serializer.toJson<String>(tags),
      'learningDate': serializer.toJson<DateTime>(learningDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LearningItem copyWith({
    int? id,
    String? title,
    Value<String?> note = const Value.absent(),
    String? tags,
    DateTime? learningDate,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LearningItem(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    tags: tags ?? this.tags,
    learningDate: learningDate ?? this.learningDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LearningItem copyWithCompanion(LearningItemsCompanion data) {
    return LearningItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      tags: data.tags.present ? data.tags.value : this.tags,
      learningDate: data.learningDate.present
          ? data.learningDate.value
          : this.learningDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('learningDate: $learningDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, note, tags, learningDate, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.tags == this.tags &&
          other.learningDate == this.learningDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningItemsCompanion extends UpdateCompanion<LearningItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<String> tags;
  final Value<DateTime> learningDate;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const LearningItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.learningDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LearningItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    required DateTime learningDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       learningDate = Value(learningDate);
  static Insertable<LearningItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? tags,
    Expression<DateTime>? learningDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags,
      if (learningDate != null) 'learning_date': learningDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LearningItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? note,
    Value<String>? tags,
    Value<DateTime>? learningDate,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return LearningItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      learningDate: learningDate ?? this.learningDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (learningDate.present) {
      map['learning_date'] = Variable<DateTime>(learningDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('learningDate: $learningDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewTasksTable extends ReviewTasks
    with TableInfo<$ReviewTasksTable, ReviewTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _learningItemIdMeta = const VerificationMeta(
    'learningItemId',
  );
  @override
  late final GeneratedColumn<int> learningItemId = GeneratedColumn<int>(
    'learning_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reviewRoundMeta = const VerificationMeta(
    'reviewRound',
  );
  @override
  late final GeneratedColumn<int> reviewRound = GeneratedColumn<int>(
    'review_round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedAtMeta = const VerificationMeta(
    'skippedAt',
  );
  @override
  late final GeneratedColumn<DateTime> skippedAt = GeneratedColumn<DateTime>(
    'skipped_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    learningItemId,
    reviewRound,
    scheduledDate,
    status,
    completedAt,
    skippedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('learning_item_id')) {
      context.handle(
        _learningItemIdMeta,
        learningItemId.isAcceptableOrUnknown(
          data['learning_item_id']!,
          _learningItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningItemIdMeta);
    }
    if (data.containsKey('review_round')) {
      context.handle(
        _reviewRoundMeta,
        reviewRound.isAcceptableOrUnknown(
          data['review_round']!,
          _reviewRoundMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewRoundMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('skipped_at')) {
      context.handle(
        _skippedAtMeta,
        skippedAt.isAcceptableOrUnknown(data['skipped_at']!, _skippedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      learningItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learning_item_id'],
      )!,
      reviewRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_round'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      skippedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}skipped_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReviewTasksTable createAlias(String alias) {
    return $ReviewTasksTable(attachedDatabase, alias);
  }
}

class ReviewTask extends DataClass implements Insertable<ReviewTask> {
  /// 主键 ID。
  final int id;

  /// 外键：关联的学习内容 ID（删除学习内容时级联删除）。
  final int learningItemId;

  /// 复习轮次（1-5）。
  final int reviewRound;

  /// 计划复习日期。
  final DateTime scheduledDate;

  /// 任务状态：pending(待复习)/done(已完成)/skipped(已跳过)。
  final String status;

  /// 完成时间（完成后记录）。
  final DateTime? completedAt;

  /// 跳过时间（跳过后记录）。
  final DateTime? skippedAt;

  /// 创建时间。
  final DateTime createdAt;
  const ReviewTask({
    required this.id,
    required this.learningItemId,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.skippedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['learning_item_id'] = Variable<int>(learningItemId);
    map['review_round'] = Variable<int>(reviewRound);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || skippedAt != null) {
      map['skipped_at'] = Variable<DateTime>(skippedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReviewTasksCompanion toCompanion(bool nullToAbsent) {
    return ReviewTasksCompanion(
      id: Value(id),
      learningItemId: Value(learningItemId),
      reviewRound: Value(reviewRound),
      scheduledDate: Value(scheduledDate),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      skippedAt: skippedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(skippedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ReviewTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewTask(
      id: serializer.fromJson<int>(json['id']),
      learningItemId: serializer.fromJson<int>(json['learningItemId']),
      reviewRound: serializer.fromJson<int>(json['reviewRound']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      skippedAt: serializer.fromJson<DateTime?>(json['skippedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'learningItemId': serializer.toJson<int>(learningItemId),
      'reviewRound': serializer.toJson<int>(reviewRound),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'skippedAt': serializer.toJson<DateTime?>(skippedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReviewTask copyWith({
    int? id,
    int? learningItemId,
    int? reviewRound,
    DateTime? scheduledDate,
    String? status,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> skippedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ReviewTask(
    id: id ?? this.id,
    learningItemId: learningItemId ?? this.learningItemId,
    reviewRound: reviewRound ?? this.reviewRound,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    skippedAt: skippedAt.present ? skippedAt.value : this.skippedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ReviewTask copyWithCompanion(ReviewTasksCompanion data) {
    return ReviewTask(
      id: data.id.present ? data.id.value : this.id,
      learningItemId: data.learningItemId.present
          ? data.learningItemId.value
          : this.learningItemId,
      reviewRound: data.reviewRound.present
          ? data.reviewRound.value
          : this.reviewRound,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      skippedAt: data.skippedAt.present ? data.skippedAt.value : this.skippedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewTask(')
          ..write('id: $id, ')
          ..write('learningItemId: $learningItemId, ')
          ..write('reviewRound: $reviewRound, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('skippedAt: $skippedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    learningItemId,
    reviewRound,
    scheduledDate,
    status,
    completedAt,
    skippedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewTask &&
          other.id == this.id &&
          other.learningItemId == this.learningItemId &&
          other.reviewRound == this.reviewRound &&
          other.scheduledDate == this.scheduledDate &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.skippedAt == this.skippedAt &&
          other.createdAt == this.createdAt);
}

class ReviewTasksCompanion extends UpdateCompanion<ReviewTask> {
  final Value<int> id;
  final Value<int> learningItemId;
  final Value<int> reviewRound;
  final Value<DateTime> scheduledDate;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> skippedAt;
  final Value<DateTime> createdAt;
  const ReviewTasksCompanion({
    this.id = const Value.absent(),
    this.learningItemId = const Value.absent(),
    this.reviewRound = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.skippedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReviewTasksCompanion.insert({
    this.id = const Value.absent(),
    required int learningItemId,
    required int reviewRound,
    required DateTime scheduledDate,
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.skippedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : learningItemId = Value(learningItemId),
       reviewRound = Value(reviewRound),
       scheduledDate = Value(scheduledDate);
  static Insertable<ReviewTask> custom({
    Expression<int>? id,
    Expression<int>? learningItemId,
    Expression<int>? reviewRound,
    Expression<DateTime>? scheduledDate,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? skippedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (learningItemId != null) 'learning_item_id': learningItemId,
      if (reviewRound != null) 'review_round': reviewRound,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (skippedAt != null) 'skipped_at': skippedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReviewTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? learningItemId,
    Value<int>? reviewRound,
    Value<DateTime>? scheduledDate,
    Value<String>? status,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? skippedAt,
    Value<DateTime>? createdAt,
  }) {
    return ReviewTasksCompanion(
      id: id ?? this.id,
      learningItemId: learningItemId ?? this.learningItemId,
      reviewRound: reviewRound ?? this.reviewRound,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (learningItemId.present) {
      map['learning_item_id'] = Variable<int>(learningItemId.value);
    }
    if (reviewRound.present) {
      map['review_round'] = Variable<int>(reviewRound.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (skippedAt.present) {
      map['skipped_at'] = Variable<DateTime>(skippedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewTasksCompanion(')
          ..write('id: $id, ')
          ..write('learningItemId: $learningItemId, ')
          ..write('reviewRound: $reviewRound, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('skippedAt: $skippedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingsTableData extends DataClass
    implements Insertable<AppSettingsTableData> {
  /// 主键 ID。
  final int id;

  /// 设置键名（唯一）。
  final String key;

  /// 设置值（JSON 字符串）。
  final String value;

  /// 更新时间。
  final DateTime updatedAt;
  const AppSettingsTableData({
    required this.id,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsTableData copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => AppSettingsTableData(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsTableData copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableData(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsTableData &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsTableData> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LearningTemplatesTable extends LearningTemplates
    with TableInfo<$LearningTemplatesTable, LearningTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titlePatternMeta = const VerificationMeta(
    'titlePattern',
  );
  @override
  late final GeneratedColumn<String> titlePattern = GeneratedColumn<String>(
    'title_pattern',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notePatternMeta = const VerificationMeta(
    'notePattern',
  );
  @override
  late final GeneratedColumn<String> notePattern = GeneratedColumn<String>(
    'note_pattern',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    titlePattern,
    notePattern,
    tags,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('title_pattern')) {
      context.handle(
        _titlePatternMeta,
        titlePattern.isAcceptableOrUnknown(
          data['title_pattern']!,
          _titlePatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titlePatternMeta);
    }
    if (data.containsKey('note_pattern')) {
      context.handle(
        _notePatternMeta,
        notePattern.isAcceptableOrUnknown(
          data['note_pattern']!,
          _notePatternMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      titlePattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_pattern'],
      )!,
      notePattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_pattern'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LearningTemplatesTable createAlias(String alias) {
    return $LearningTemplatesTable(attachedDatabase, alias);
  }
}

class LearningTemplate extends DataClass
    implements Insertable<LearningTemplate> {
  /// 主键 ID。
  final int id;

  /// 模板名称（用户可读，≤30）。
  final String name;

  /// 标题模板（必填，≤50）。
  final String titlePattern;

  /// 备注模板（可选）。
  final String? notePattern;

  /// 默认标签（JSON 字符串，如 ["英语","单词"]）。
  final String tags;

  /// 排序字段（越小越靠前）。
  final int sortOrder;

  /// 创建时间。
  final DateTime createdAt;

  /// 更新时间（可空）。
  final DateTime? updatedAt;
  const LearningTemplate({
    required this.id,
    required this.name,
    required this.titlePattern,
    this.notePattern,
    required this.tags,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['title_pattern'] = Variable<String>(titlePattern);
    if (!nullToAbsent || notePattern != null) {
      map['note_pattern'] = Variable<String>(notePattern);
    }
    map['tags'] = Variable<String>(tags);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LearningTemplatesCompanion toCompanion(bool nullToAbsent) {
    return LearningTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      titlePattern: Value(titlePattern),
      notePattern: notePattern == null && nullToAbsent
          ? const Value.absent()
          : Value(notePattern),
      tags: Value(tags),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LearningTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      titlePattern: serializer.fromJson<String>(json['titlePattern']),
      notePattern: serializer.fromJson<String?>(json['notePattern']),
      tags: serializer.fromJson<String>(json['tags']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'titlePattern': serializer.toJson<String>(titlePattern),
      'notePattern': serializer.toJson<String?>(notePattern),
      'tags': serializer.toJson<String>(tags),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LearningTemplate copyWith({
    int? id,
    String? name,
    String? titlePattern,
    Value<String?> notePattern = const Value.absent(),
    String? tags,
    int? sortOrder,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LearningTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    titlePattern: titlePattern ?? this.titlePattern,
    notePattern: notePattern.present ? notePattern.value : this.notePattern,
    tags: tags ?? this.tags,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LearningTemplate copyWithCompanion(LearningTemplatesCompanion data) {
    return LearningTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      titlePattern: data.titlePattern.present
          ? data.titlePattern.value
          : this.titlePattern,
      notePattern: data.notePattern.present
          ? data.notePattern.value
          : this.notePattern,
      tags: data.tags.present ? data.tags.value : this.tags,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('titlePattern: $titlePattern, ')
          ..write('notePattern: $notePattern, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    titlePattern,
    notePattern,
    tags,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.titlePattern == this.titlePattern &&
          other.notePattern == this.notePattern &&
          other.tags == this.tags &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningTemplatesCompanion extends UpdateCompanion<LearningTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> titlePattern;
  final Value<String?> notePattern;
  final Value<String> tags;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const LearningTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.titlePattern = const Value.absent(),
    this.notePattern = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LearningTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String titlePattern,
    this.notePattern = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       titlePattern = Value(titlePattern);
  static Insertable<LearningTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? titlePattern,
    Expression<String>? notePattern,
    Expression<String>? tags,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (titlePattern != null) 'title_pattern': titlePattern,
      if (notePattern != null) 'note_pattern': notePattern,
      if (tags != null) 'tags': tags,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LearningTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? titlePattern,
    Value<String?>? notePattern,
    Value<String>? tags,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return LearningTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      titlePattern: titlePattern ?? this.titlePattern,
      notePattern: notePattern ?? this.notePattern,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (titlePattern.present) {
      map['title_pattern'] = Variable<String>(titlePattern.value);
    }
    if (notePattern.present) {
      map['note_pattern'] = Variable<String>(notePattern.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('titlePattern: $titlePattern, ')
          ..write('notePattern: $notePattern, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LearningTopicsTable extends LearningTopics
    with TableInfo<$LearningTopicsTable, LearningTopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningTopic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningTopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningTopic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LearningTopicsTable createAlias(String alias) {
    return $LearningTopicsTable(attachedDatabase, alias);
  }
}

class LearningTopic extends DataClass implements Insertable<LearningTopic> {
  /// 主键 ID。
  final int id;

  /// 主题名称（必填，≤50）。
  final String name;

  /// 主题描述（可选）。
  final String? description;

  /// 创建时间。
  final DateTime createdAt;

  /// 更新时间（可空）。
  final DateTime? updatedAt;
  const LearningTopic({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LearningTopicsCompanion toCompanion(bool nullToAbsent) {
    return LearningTopicsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LearningTopic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningTopic(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LearningTopic copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LearningTopic(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LearningTopic copyWithCompanion(LearningTopicsCompanion data) {
    return LearningTopic(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningTopic(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningTopic &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningTopicsCompanion extends UpdateCompanion<LearningTopic> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const LearningTopicsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LearningTopicsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LearningTopic> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LearningTopicsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return LearningTopicsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningTopicsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TopicItemRelationsTable extends TopicItemRelations
    with TableInfo<$TopicItemRelationsTable, TopicItemRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicItemRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_topics (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _learningItemIdMeta = const VerificationMeta(
    'learningItemId',
  );
  @override
  late final GeneratedColumn<int> learningItemId = GeneratedColumn<int>(
    'learning_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    learningItemId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_item_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicItemRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('learning_item_id')) {
      context.handle(
        _learningItemIdMeta,
        learningItemId.isAcceptableOrUnknown(
          data['learning_item_id']!,
          _learningItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningItemIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {topicId, learningItemId},
  ];
  @override
  TopicItemRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicItemRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      learningItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learning_item_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TopicItemRelationsTable createAlias(String alias) {
    return $TopicItemRelationsTable(attachedDatabase, alias);
  }
}

class TopicItemRelation extends DataClass
    implements Insertable<TopicItemRelation> {
  /// 主键 ID。
  final int id;

  /// 外键：主题 ID（删除主题时级联删除）。
  final int topicId;

  /// 外键：学习内容 ID（删除学习内容时级联删除）。
  final int learningItemId;

  /// 创建时间。
  final DateTime createdAt;
  const TopicItemRelation({
    required this.id,
    required this.topicId,
    required this.learningItemId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<int>(topicId);
    map['learning_item_id'] = Variable<int>(learningItemId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TopicItemRelationsCompanion toCompanion(bool nullToAbsent) {
    return TopicItemRelationsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      learningItemId: Value(learningItemId),
      createdAt: Value(createdAt),
    );
  }

  factory TopicItemRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicItemRelation(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<int>(json['topicId']),
      learningItemId: serializer.fromJson<int>(json['learningItemId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<int>(topicId),
      'learningItemId': serializer.toJson<int>(learningItemId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TopicItemRelation copyWith({
    int? id,
    int? topicId,
    int? learningItemId,
    DateTime? createdAt,
  }) => TopicItemRelation(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    learningItemId: learningItemId ?? this.learningItemId,
    createdAt: createdAt ?? this.createdAt,
  );
  TopicItemRelation copyWithCompanion(TopicItemRelationsCompanion data) {
    return TopicItemRelation(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      learningItemId: data.learningItemId.present
          ? data.learningItemId.value
          : this.learningItemId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicItemRelation(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('learningItemId: $learningItemId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, topicId, learningItemId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicItemRelation &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.learningItemId == this.learningItemId &&
          other.createdAt == this.createdAt);
}

class TopicItemRelationsCompanion extends UpdateCompanion<TopicItemRelation> {
  final Value<int> id;
  final Value<int> topicId;
  final Value<int> learningItemId;
  final Value<DateTime> createdAt;
  const TopicItemRelationsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.learningItemId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TopicItemRelationsCompanion.insert({
    this.id = const Value.absent(),
    required int topicId,
    required int learningItemId,
    this.createdAt = const Value.absent(),
  }) : topicId = Value(topicId),
       learningItemId = Value(learningItemId);
  static Insertable<TopicItemRelation> custom({
    Expression<int>? id,
    Expression<int>? topicId,
    Expression<int>? learningItemId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (learningItemId != null) 'learning_item_id': learningItemId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TopicItemRelationsCompanion copyWith({
    Value<int>? id,
    Value<int>? topicId,
    Value<int>? learningItemId,
    Value<DateTime>? createdAt,
  }) {
    return TopicItemRelationsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      learningItemId: learningItemId ?? this.learningItemId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (learningItemId.present) {
      map['learning_item_id'] = Variable<int>(learningItemId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicItemRelationsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('learningItemId: $learningItemId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LearningItemsTable learningItems = $LearningItemsTable(this);
  late final $ReviewTasksTable reviewTasks = $ReviewTasksTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  late final $LearningTemplatesTable learningTemplates =
      $LearningTemplatesTable(this);
  late final $LearningTopicsTable learningTopics = $LearningTopicsTable(this);
  late final $TopicItemRelationsTable topicItemRelations =
      $TopicItemRelationsTable(this);
  late final Index idxLearningDate = Index(
    'idx_learning_date',
    'CREATE INDEX idx_learning_date ON learning_items (learning_date)',
  );
  late final Index idxScheduledDate = Index(
    'idx_scheduled_date',
    'CREATE INDEX idx_scheduled_date ON review_tasks (scheduled_date)',
  );
  late final Index idxStatus = Index(
    'idx_status',
    'CREATE INDEX idx_status ON review_tasks (status)',
  );
  late final Index idxLearningItemId = Index(
    'idx_learning_item_id',
    'CREATE INDEX idx_learning_item_id ON review_tasks (learning_item_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    learningItems,
    reviewTasks,
    appSettingsTable,
    learningTemplates,
    learningTopics,
    topicItemRelations,
    idxLearningDate,
    idxScheduledDate,
    idxStatus,
    idxLearningItemId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_topics',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('topic_item_relations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('topic_item_relations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LearningItemsTableCreateCompanionBuilder =
    LearningItemsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> note,
      Value<String> tags,
      required DateTime learningDate,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$LearningItemsTableUpdateCompanionBuilder =
    LearningItemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> note,
      Value<String> tags,
      Value<DateTime> learningDate,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

final class $$LearningItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LearningItemsTable, LearningItem> {
  $$LearningItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ReviewTasksTable, List<ReviewTask>>
  _reviewTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewTasks,
    aliasName: $_aliasNameGenerator(
      db.learningItems.id,
      db.reviewTasks.learningItemId,
    ),
  );

  $$ReviewTasksTableProcessedTableManager get reviewTasksRefs {
    final manager = $$ReviewTasksTableTableManager(
      $_db,
      $_db.reviewTasks,
    ).filter((f) => f.learningItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TopicItemRelationsTable, List<TopicItemRelation>>
  _topicItemRelationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.topicItemRelations,
        aliasName: $_aliasNameGenerator(
          db.learningItems.id,
          db.topicItemRelations.learningItemId,
        ),
      );

  $$TopicItemRelationsTableProcessedTableManager get topicItemRelationsRefs {
    final manager = $$TopicItemRelationsTableTableManager(
      $_db,
      $_db.topicItemRelations,
    ).filter((f) => f.learningItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _topicItemRelationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearningItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get learningDate => $composableBuilder(
    column: $table.learningDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reviewTasksRefs(
    Expression<bool> Function($$ReviewTasksTableFilterComposer f) f,
  ) {
    final $$ReviewTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewTasks,
      getReferencedColumn: (t) => t.learningItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewTasksTableFilterComposer(
            $db: $db,
            $table: $db.reviewTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> topicItemRelationsRefs(
    Expression<bool> Function($$TopicItemRelationsTableFilterComposer f) f,
  ) {
    final $$TopicItemRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.topicItemRelations,
      getReferencedColumn: (t) => t.learningItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicItemRelationsTableFilterComposer(
            $db: $db,
            $table: $db.topicItemRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearningItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get learningDate => $composableBuilder(
    column: $table.learningDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get learningDate => $composableBuilder(
    column: $table.learningDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> reviewTasksRefs<T extends Object>(
    Expression<T> Function($$ReviewTasksTableAnnotationComposer a) f,
  ) {
    final $$ReviewTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewTasks,
      getReferencedColumn: (t) => t.learningItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> topicItemRelationsRefs<T extends Object>(
    Expression<T> Function($$TopicItemRelationsTableAnnotationComposer a) f,
  ) {
    final $$TopicItemRelationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.topicItemRelations,
          getReferencedColumn: (t) => t.learningItemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TopicItemRelationsTableAnnotationComposer(
                $db: $db,
                $table: $db.topicItemRelations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LearningItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningItemsTable,
          LearningItem,
          $$LearningItemsTableFilterComposer,
          $$LearningItemsTableOrderingComposer,
          $$LearningItemsTableAnnotationComposer,
          $$LearningItemsTableCreateCompanionBuilder,
          $$LearningItemsTableUpdateCompanionBuilder,
          (LearningItem, $$LearningItemsTableReferences),
          LearningItem,
          PrefetchHooks Function({
            bool reviewTasksRefs,
            bool topicItemRelationsRefs,
          })
        > {
  $$LearningItemsTableTableManager(_$AppDatabase db, $LearningItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<DateTime> learningDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningItemsCompanion(
                id: id,
                title: title,
                note: note,
                tags: tags,
                learningDate: learningDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<String> tags = const Value.absent(),
                required DateTime learningDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningItemsCompanion.insert(
                id: id,
                title: title,
                note: note,
                tags: tags,
                learningDate: learningDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearningItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({reviewTasksRefs = false, topicItemRelationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewTasksRefs) db.reviewTasks,
                    if (topicItemRelationsRefs) db.topicItemRelations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewTasksRefs)
                        await $_getPrefetchedData<
                          LearningItem,
                          $LearningItemsTable,
                          ReviewTask
                        >(
                          currentTable: table,
                          referencedTable: $$LearningItemsTableReferences
                              ._reviewTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learningItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (topicItemRelationsRefs)
                        await $_getPrefetchedData<
                          LearningItem,
                          $LearningItemsTable,
                          TopicItemRelation
                        >(
                          currentTable: table,
                          referencedTable: $$LearningItemsTableReferences
                              ._topicItemRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).topicItemRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learningItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LearningItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningItemsTable,
      LearningItem,
      $$LearningItemsTableFilterComposer,
      $$LearningItemsTableOrderingComposer,
      $$LearningItemsTableAnnotationComposer,
      $$LearningItemsTableCreateCompanionBuilder,
      $$LearningItemsTableUpdateCompanionBuilder,
      (LearningItem, $$LearningItemsTableReferences),
      LearningItem,
      PrefetchHooks Function({
        bool reviewTasksRefs,
        bool topicItemRelationsRefs,
      })
    >;
typedef $$ReviewTasksTableCreateCompanionBuilder =
    ReviewTasksCompanion Function({
      Value<int> id,
      required int learningItemId,
      required int reviewRound,
      required DateTime scheduledDate,
      Value<String> status,
      Value<DateTime?> completedAt,
      Value<DateTime?> skippedAt,
      Value<DateTime> createdAt,
    });
typedef $$ReviewTasksTableUpdateCompanionBuilder =
    ReviewTasksCompanion Function({
      Value<int> id,
      Value<int> learningItemId,
      Value<int> reviewRound,
      Value<DateTime> scheduledDate,
      Value<String> status,
      Value<DateTime?> completedAt,
      Value<DateTime?> skippedAt,
      Value<DateTime> createdAt,
    });

final class $$ReviewTasksTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewTasksTable, ReviewTask> {
  $$ReviewTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearningItemsTable _learningItemIdTable(_$AppDatabase db) =>
      db.learningItems.createAlias(
        $_aliasNameGenerator(
          db.reviewTasks.learningItemId,
          db.learningItems.id,
        ),
      );

  $$LearningItemsTableProcessedTableManager get learningItemId {
    final $_column = $_itemColumn<int>('learning_item_id')!;

    final manager = $$LearningItemsTableTableManager(
      $_db,
      $_db.learningItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learningItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewTasksTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewTasksTable> {
  $$ReviewTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewRound => $composableBuilder(
    column: $table.reviewRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get skippedAt => $composableBuilder(
    column: $table.skippedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningItemsTableFilterComposer get learningItemId {
    final $$LearningItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableFilterComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewTasksTable> {
  $$ReviewTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewRound => $composableBuilder(
    column: $table.reviewRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get skippedAt => $composableBuilder(
    column: $table.skippedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningItemsTableOrderingComposer get learningItemId {
    final $$LearningItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableOrderingComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewTasksTable> {
  $$ReviewTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reviewRound => $composableBuilder(
    column: $table.reviewRound,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get skippedAt =>
      $composableBuilder(column: $table.skippedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LearningItemsTableAnnotationComposer get learningItemId {
    final $$LearningItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewTasksTable,
          ReviewTask,
          $$ReviewTasksTableFilterComposer,
          $$ReviewTasksTableOrderingComposer,
          $$ReviewTasksTableAnnotationComposer,
          $$ReviewTasksTableCreateCompanionBuilder,
          $$ReviewTasksTableUpdateCompanionBuilder,
          (ReviewTask, $$ReviewTasksTableReferences),
          ReviewTask,
          PrefetchHooks Function({bool learningItemId})
        > {
  $$ReviewTasksTableTableManager(_$AppDatabase db, $ReviewTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> learningItemId = const Value.absent(),
                Value<int> reviewRound = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> skippedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReviewTasksCompanion(
                id: id,
                learningItemId: learningItemId,
                reviewRound: reviewRound,
                scheduledDate: scheduledDate,
                status: status,
                completedAt: completedAt,
                skippedAt: skippedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int learningItemId,
                required int reviewRound,
                required DateTime scheduledDate,
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> skippedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReviewTasksCompanion.insert(
                id: id,
                learningItemId: learningItemId,
                reviewRound: reviewRound,
                scheduledDate: scheduledDate,
                status: status,
                completedAt: completedAt,
                skippedAt: skippedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learningItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learningItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.learningItemId,
                                referencedTable: $$ReviewTasksTableReferences
                                    ._learningItemIdTable(db),
                                referencedColumn: $$ReviewTasksTableReferences
                                    ._learningItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewTasksTable,
      ReviewTask,
      $$ReviewTasksTableFilterComposer,
      $$ReviewTasksTableOrderingComposer,
      $$ReviewTasksTableAnnotationComposer,
      $$ReviewTasksTableCreateCompanionBuilder,
      $$ReviewTasksTableUpdateCompanionBuilder,
      (ReviewTask, $$ReviewTasksTableReferences),
      ReviewTask,
      PrefetchHooks Function({bool learningItemId})
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            AppSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsTableTable,
              AppSettingsTableData
            >,
          ),
          AppSettingsTableData,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$AppDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsTableCompanion(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsTableCompanion.insert(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTableTable,
      AppSettingsTableData,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        AppSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData
        >,
      ),
      AppSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$LearningTemplatesTableCreateCompanionBuilder =
    LearningTemplatesCompanion Function({
      Value<int> id,
      required String name,
      required String titlePattern,
      Value<String?> notePattern,
      Value<String> tags,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$LearningTemplatesTableUpdateCompanionBuilder =
    LearningTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> titlePattern,
      Value<String?> notePattern,
      Value<String> tags,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$LearningTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $LearningTemplatesTable> {
  $$LearningTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titlePattern => $composableBuilder(
    column: $table.titlePattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notePattern => $composableBuilder(
    column: $table.notePattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningTemplatesTable> {
  $$LearningTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titlePattern => $composableBuilder(
    column: $table.titlePattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notePattern => $composableBuilder(
    column: $table.notePattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningTemplatesTable> {
  $$LearningTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get titlePattern => $composableBuilder(
    column: $table.titlePattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notePattern => $composableBuilder(
    column: $table.notePattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LearningTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningTemplatesTable,
          LearningTemplate,
          $$LearningTemplatesTableFilterComposer,
          $$LearningTemplatesTableOrderingComposer,
          $$LearningTemplatesTableAnnotationComposer,
          $$LearningTemplatesTableCreateCompanionBuilder,
          $$LearningTemplatesTableUpdateCompanionBuilder,
          (
            LearningTemplate,
            BaseReferences<
              _$AppDatabase,
              $LearningTemplatesTable,
              LearningTemplate
            >,
          ),
          LearningTemplate,
          PrefetchHooks Function()
        > {
  $$LearningTemplatesTableTableManager(
    _$AppDatabase db,
    $LearningTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> titlePattern = const Value.absent(),
                Value<String?> notePattern = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningTemplatesCompanion(
                id: id,
                name: name,
                titlePattern: titlePattern,
                notePattern: notePattern,
                tags: tags,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String titlePattern,
                Value<String?> notePattern = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningTemplatesCompanion.insert(
                id: id,
                name: name,
                titlePattern: titlePattern,
                notePattern: notePattern,
                tags: tags,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningTemplatesTable,
      LearningTemplate,
      $$LearningTemplatesTableFilterComposer,
      $$LearningTemplatesTableOrderingComposer,
      $$LearningTemplatesTableAnnotationComposer,
      $$LearningTemplatesTableCreateCompanionBuilder,
      $$LearningTemplatesTableUpdateCompanionBuilder,
      (
        LearningTemplate,
        BaseReferences<
          _$AppDatabase,
          $LearningTemplatesTable,
          LearningTemplate
        >,
      ),
      LearningTemplate,
      PrefetchHooks Function()
    >;
typedef $$LearningTopicsTableCreateCompanionBuilder =
    LearningTopicsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$LearningTopicsTableUpdateCompanionBuilder =
    LearningTopicsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

final class $$LearningTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $LearningTopicsTable, LearningTopic> {
  $$LearningTopicsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TopicItemRelationsTable, List<TopicItemRelation>>
  _topicItemRelationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.topicItemRelations,
        aliasName: $_aliasNameGenerator(
          db.learningTopics.id,
          db.topicItemRelations.topicId,
        ),
      );

  $$TopicItemRelationsTableProcessedTableManager get topicItemRelationsRefs {
    final manager = $$TopicItemRelationsTableTableManager(
      $_db,
      $_db.topicItemRelations,
    ).filter((f) => f.topicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _topicItemRelationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearningTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningTopicsTable> {
  $$LearningTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> topicItemRelationsRefs(
    Expression<bool> Function($$TopicItemRelationsTableFilterComposer f) f,
  ) {
    final $$TopicItemRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.topicItemRelations,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicItemRelationsTableFilterComposer(
            $db: $db,
            $table: $db.topicItemRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearningTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningTopicsTable> {
  $$LearningTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningTopicsTable> {
  $$LearningTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> topicItemRelationsRefs<T extends Object>(
    Expression<T> Function($$TopicItemRelationsTableAnnotationComposer a) f,
  ) {
    final $$TopicItemRelationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.topicItemRelations,
          getReferencedColumn: (t) => t.topicId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TopicItemRelationsTableAnnotationComposer(
                $db: $db,
                $table: $db.topicItemRelations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LearningTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningTopicsTable,
          LearningTopic,
          $$LearningTopicsTableFilterComposer,
          $$LearningTopicsTableOrderingComposer,
          $$LearningTopicsTableAnnotationComposer,
          $$LearningTopicsTableCreateCompanionBuilder,
          $$LearningTopicsTableUpdateCompanionBuilder,
          (LearningTopic, $$LearningTopicsTableReferences),
          LearningTopic,
          PrefetchHooks Function({bool topicItemRelationsRefs})
        > {
  $$LearningTopicsTableTableManager(
    _$AppDatabase db,
    $LearningTopicsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningTopicsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => LearningTopicsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearningTopicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicItemRelationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (topicItemRelationsRefs) db.topicItemRelations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (topicItemRelationsRefs)
                    await $_getPrefetchedData<
                      LearningTopic,
                      $LearningTopicsTable,
                      TopicItemRelation
                    >(
                      currentTable: table,
                      referencedTable: $$LearningTopicsTableReferences
                          ._topicItemRelationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LearningTopicsTableReferences(
                            db,
                            table,
                            p0,
                          ).topicItemRelationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.topicId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LearningTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningTopicsTable,
      LearningTopic,
      $$LearningTopicsTableFilterComposer,
      $$LearningTopicsTableOrderingComposer,
      $$LearningTopicsTableAnnotationComposer,
      $$LearningTopicsTableCreateCompanionBuilder,
      $$LearningTopicsTableUpdateCompanionBuilder,
      (LearningTopic, $$LearningTopicsTableReferences),
      LearningTopic,
      PrefetchHooks Function({bool topicItemRelationsRefs})
    >;
typedef $$TopicItemRelationsTableCreateCompanionBuilder =
    TopicItemRelationsCompanion Function({
      Value<int> id,
      required int topicId,
      required int learningItemId,
      Value<DateTime> createdAt,
    });
typedef $$TopicItemRelationsTableUpdateCompanionBuilder =
    TopicItemRelationsCompanion Function({
      Value<int> id,
      Value<int> topicId,
      Value<int> learningItemId,
      Value<DateTime> createdAt,
    });

final class $$TopicItemRelationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TopicItemRelationsTable,
          TopicItemRelation
        > {
  $$TopicItemRelationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearningTopicsTable _topicIdTable(_$AppDatabase db) =>
      db.learningTopics.createAlias(
        $_aliasNameGenerator(
          db.topicItemRelations.topicId,
          db.learningTopics.id,
        ),
      );

  $$LearningTopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<int>('topic_id')!;

    final manager = $$LearningTopicsTableTableManager(
      $_db,
      $_db.learningTopics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LearningItemsTable _learningItemIdTable(_$AppDatabase db) =>
      db.learningItems.createAlias(
        $_aliasNameGenerator(
          db.topicItemRelations.learningItemId,
          db.learningItems.id,
        ),
      );

  $$LearningItemsTableProcessedTableManager get learningItemId {
    final $_column = $_itemColumn<int>('learning_item_id')!;

    final manager = $$LearningItemsTableTableManager(
      $_db,
      $_db.learningItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learningItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TopicItemRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicItemRelationsTable> {
  $$TopicItemRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningTopicsTableFilterComposer get topicId {
    final $$LearningTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.learningTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningTopicsTableFilterComposer(
            $db: $db,
            $table: $db.learningTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LearningItemsTableFilterComposer get learningItemId {
    final $$LearningItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableFilterComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicItemRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicItemRelationsTable> {
  $$TopicItemRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningTopicsTableOrderingComposer get topicId {
    final $$LearningTopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.learningTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningTopicsTableOrderingComposer(
            $db: $db,
            $table: $db.learningTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LearningItemsTableOrderingComposer get learningItemId {
    final $$LearningItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableOrderingComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicItemRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicItemRelationsTable> {
  $$TopicItemRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LearningTopicsTableAnnotationComposer get topicId {
    final $$LearningTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.learningTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LearningItemsTableAnnotationComposer get learningItemId {
    final $$LearningItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learningItemId,
      referencedTable: $db.learningItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicItemRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicItemRelationsTable,
          TopicItemRelation,
          $$TopicItemRelationsTableFilterComposer,
          $$TopicItemRelationsTableOrderingComposer,
          $$TopicItemRelationsTableAnnotationComposer,
          $$TopicItemRelationsTableCreateCompanionBuilder,
          $$TopicItemRelationsTableUpdateCompanionBuilder,
          (TopicItemRelation, $$TopicItemRelationsTableReferences),
          TopicItemRelation,
          PrefetchHooks Function({bool topicId, bool learningItemId})
        > {
  $$TopicItemRelationsTableTableManager(
    _$AppDatabase db,
    $TopicItemRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicItemRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicItemRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicItemRelationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<int> learningItemId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TopicItemRelationsCompanion(
                id: id,
                topicId: topicId,
                learningItemId: learningItemId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int topicId,
                required int learningItemId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => TopicItemRelationsCompanion.insert(
                id: id,
                topicId: topicId,
                learningItemId: learningItemId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TopicItemRelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicId = false, learningItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (topicId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.topicId,
                                referencedTable:
                                    $$TopicItemRelationsTableReferences
                                        ._topicIdTable(db),
                                referencedColumn:
                                    $$TopicItemRelationsTableReferences
                                        ._topicIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (learningItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.learningItemId,
                                referencedTable:
                                    $$TopicItemRelationsTableReferences
                                        ._learningItemIdTable(db),
                                referencedColumn:
                                    $$TopicItemRelationsTableReferences
                                        ._learningItemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TopicItemRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicItemRelationsTable,
      TopicItemRelation,
      $$TopicItemRelationsTableFilterComposer,
      $$TopicItemRelationsTableOrderingComposer,
      $$TopicItemRelationsTableAnnotationComposer,
      $$TopicItemRelationsTableCreateCompanionBuilder,
      $$TopicItemRelationsTableUpdateCompanionBuilder,
      (TopicItemRelation, $$TopicItemRelationsTableReferences),
      TopicItemRelation,
      PrefetchHooks Function({bool topicId, bool learningItemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LearningItemsTableTableManager get learningItems =>
      $$LearningItemsTableTableManager(_db, _db.learningItems);
  $$ReviewTasksTableTableManager get reviewTasks =>
      $$ReviewTasksTableTableManager(_db, _db.reviewTasks);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
  $$LearningTemplatesTableTableManager get learningTemplates =>
      $$LearningTemplatesTableTableManager(_db, _db.learningTemplates);
  $$LearningTopicsTableTableManager get learningTopics =>
      $$LearningTopicsTableTableManager(_db, _db.learningTopics);
  $$TopicItemRelationsTableTableManager get topicItemRelations =>
      $$TopicItemRelationsTableTableManager(_db, _db.topicItemRelations);
}

/// 文件用途：领域实体 - 备份文件模型（用于导出/导入、预览与校验）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

/// 备份数据统计信息（用于预览）。
class BackupStatsEntity {
  /// 构造函数。
  const BackupStatsEntity({
    required this.learningItems,
    required this.reviewTasks,
    required this.reviewRecords,
    required this.payloadSize,
  });

  /// 学习内容条数。
  final int learningItems;

  /// 复习任务条数。
  final int reviewTasks;

  /// 复习记录条数。
  final int reviewRecords;

  /// `data` 字段规范化后的 UTF-8 字节长度。
  final int payloadSize;

  Map<String, dynamic> toJson() => {
    'learningItems': learningItems,
    'reviewTasks': reviewTasks,
    'reviewRecords': reviewRecords,
    'payloadSize': payloadSize,
  };

  /// 从 JSON 解析（缺字段按 0 兜底，满足 spec 的默认值策略）。
  factory BackupStatsEntity.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return BackupStatsEntity(
      learningItems: asInt(json['learningItems']),
      reviewTasks: asInt(json['reviewTasks']),
      reviewRecords: asInt(json['reviewRecords']),
      payloadSize: asInt(json['payloadSize']),
    );
  }
}

/// 备份文件 `data.learningItems` 的条目。
class BackupLearningItemEntity {
  /// 构造函数。
  const BackupLearningItemEntity({
    required this.uuid,
    required this.title,
    this.description,
    this.note,
    required this.tags,
    required this.learningDate,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    this.deletedAt,
  });

  final String uuid;
  final String title;
  final String? description;
  final String? note;
  final List<String> tags;
  final String learningDate;
  final String createdAt;
  final String? updatedAt;
  final bool isDeleted;
  final String? deletedAt;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'title': title,
    'description': description,
    'note': note,
    'tags': tags,
    'learningDate': learningDate,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt,
  };

  /// 从 JSON 解析（缺字段按默认值兜底；未知字段忽略）。
  factory BackupLearningItemEntity.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : const <String>[];

    return BackupLearningItemEntity(
      uuid: (json['uuid'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String?)?.trim(),
      note: json['note'] as String?,
      tags: tags,
      learningDate: (json['learningDate'] as String? ?? '').trim(),
      createdAt: (json['createdAt'] as String? ?? '').trim(),
      updatedAt: (json['updatedAt'] as String?)?.trim(),
      isDeleted: json['isDeleted'] is bool ? json['isDeleted'] as bool : false,
      deletedAt: (json['deletedAt'] as String?)?.trim(),
    );
  }
}

/// 备份文件 `data.learningSubtasks` 的条目。
class BackupLearningSubtaskEntity {
  /// 构造函数。
  const BackupLearningSubtaskEntity({
    required this.uuid,
    required this.learningItemUuid,
    required this.content,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });

  /// 子任务 UUID。
  final String uuid;

  /// 关联的学习内容 UUID（用于导入外键修复）。
  final String learningItemUuid;

  /// 子任务内容。
  final String content;

  /// 排序字段（同 learningItemUuid 内从 0 开始）。
  final int sortOrder;

  /// 创建时间（ISO 字符串）。
  final String createdAt;

  /// 更新时间（ISO 字符串，可空）。
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'learningItemUuid': learningItemUuid,
    'content': content,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BackupLearningSubtaskEntity.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return BackupLearningSubtaskEntity(
      uuid: (json['uuid'] as String? ?? '').trim(),
      learningItemUuid: (json['learningItemUuid'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      sortOrder: asInt(json['sortOrder']),
      createdAt: (json['createdAt'] as String? ?? '').trim(),
      updatedAt: (json['updatedAt'] as String?)?.trim(),
    );
  }
}

/// 备份文件 `data.reviewTasks` 的条目。
class BackupReviewTaskEntity {
  /// 构造函数。
  const BackupReviewTaskEntity({
    required this.uuid,
    required this.learningItemUuid,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.skippedAt,
    required this.createdAt,
    this.updatedAt,
  });

  final String uuid;
  final String learningItemUuid;
  final int reviewRound;
  final String scheduledDate;
  final String status;
  final String? completedAt;
  final String? skippedAt;
  final String createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'learningItemUuid': learningItemUuid,
    'reviewRound': reviewRound,
    'scheduledDate': scheduledDate,
    'status': status,
    'completedAt': completedAt,
    'skippedAt': skippedAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BackupReviewTaskEntity.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return BackupReviewTaskEntity(
      uuid: (json['uuid'] as String? ?? '').trim(),
      learningItemUuid: (json['learningItemUuid'] as String? ?? '').trim(),
      reviewRound: asInt(json['reviewRound']),
      scheduledDate: (json['scheduledDate'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      completedAt: (json['completedAt'] as String?)?.trim(),
      skippedAt: (json['skippedAt'] as String?)?.trim(),
      createdAt: (json['createdAt'] as String? ?? '').trim(),
      updatedAt: (json['updatedAt'] as String?)?.trim(),
    );
  }
}

/// 备份文件 `data.reviewRecords` 的条目。
class BackupReviewRecordEntity {
  /// 构造函数。
  const BackupReviewRecordEntity({
    required this.uuid,
    required this.reviewTaskUuid,
    required this.action,
    required this.occurredAt,
    required this.createdAt,
  });

  final String uuid;
  final String reviewTaskUuid;
  final String action;
  final String occurredAt;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'reviewTaskUuid': reviewTaskUuid,
    'action': action,
    'occurredAt': occurredAt,
    'createdAt': createdAt,
  };

  factory BackupReviewRecordEntity.fromJson(Map<String, dynamic> json) {
    return BackupReviewRecordEntity(
      uuid: (json['uuid'] as String? ?? '').trim(),
      reviewTaskUuid: (json['reviewTaskUuid'] as String? ?? '').trim(),
      action: (json['action'] as String? ?? '').trim(),
      occurredAt: (json['occurredAt'] as String? ?? '').trim(),
      createdAt: (json['createdAt'] as String? ?? '').trim(),
    );
  }
}

/// 备份文件 `data` 段。
class BackupDataEntity {
  /// 构造函数。
  const BackupDataEntity({
    required this.learningItems,
    required this.learningSubtasks,
    required this.reviewTasks,
    required this.reviewRecords,
    required this.settings,
  });

  final List<BackupLearningItemEntity> learningItems;
  final List<BackupLearningSubtaskEntity> learningSubtasks;
  final List<BackupReviewTaskEntity> reviewTasks;
  final List<BackupReviewRecordEntity> reviewRecords;

  /// 设置对象（key-value；值为 JSON 可表达的原始类型）。
  final Map<String, dynamic> settings;

  Map<String, dynamic> toJson() => {
    'learningItems': learningItems.map((e) => e.toJson()).toList(),
    'learningSubtasks': learningSubtasks.map((e) => e.toJson()).toList(),
    'reviewTasks': reviewTasks.map((e) => e.toJson()).toList(),
    'reviewRecords': reviewRecords.map((e) => e.toJson()).toList(),
    'settings': settings,
  };

  factory BackupDataEntity.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(Object? raw, T Function(Map<String, dynamic>) from) {
      if (raw is! List) return <T>[];
      final result = <T>[];
      for (final item in raw) {
        if (item is Map) {
          result.add(from(item.cast<String, dynamic>()));
        }
      }
      return result;
    }

    final settingsRaw = json['settings'];
    final settings = settingsRaw is Map
        ? settingsRaw.cast<String, dynamic>()
        : const <String, dynamic>{};

    return BackupDataEntity(
      learningItems: readList(
        json['learningItems'],
        BackupLearningItemEntity.fromJson,
      ),
      learningSubtasks: readList(
        json['learningSubtasks'],
        BackupLearningSubtaskEntity.fromJson,
      ),
      reviewTasks: readList(
        json['reviewTasks'],
        BackupReviewTaskEntity.fromJson,
      ),
      reviewRecords: readList(
        json['reviewRecords'],
        BackupReviewRecordEntity.fromJson,
      ),
      settings: Map<String, dynamic>.from(settings),
    );
  }
}

/// 备份文件实体（顶层 JSON）。
class BackupFileEntity {
  /// 构造函数。
  const BackupFileEntity({
    required this.schemaVersion,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.backupId,
    required this.createdAt,
    required this.createdAtUtc,
    required this.checksum,
    required this.stats,
    required this.data,
    this.platform,
    this.deviceModel,
  });

  final String schemaVersion;
  final String appVersion;
  final int dbSchemaVersion;
  final String backupId;
  final String createdAt;
  final String createdAtUtc;
  final String checksum;
  final BackupStatsEntity stats;
  final BackupDataEntity data;
  final String? platform;
  final String? deviceModel;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'dbSchemaVersion': dbSchemaVersion,
    'backupId': backupId,
    'createdAt': createdAt,
    'createdAtUtc': createdAtUtc,
    'checksum': checksum,
    'stats': stats.toJson(),
    'data': data.toJson(),
    if (platform != null) 'platform': platform,
    if (deviceModel != null) 'deviceModel': deviceModel,
  };

  /// 从 JSON 解析（缺字段按默认值策略兜底）。
  ///
  /// 注意：backupId 缺失时会回退为空字符串，上层可按 spec 生成新 UUID 后再继续。
  factory BackupFileEntity.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    final statsRaw = json['stats'];
    final stats = statsRaw is Map
        ? BackupStatsEntity.fromJson(statsRaw.cast<String, dynamic>())
        : const BackupStatsEntity(
            learningItems: 0,
            reviewTasks: 0,
            reviewRecords: 0,
            payloadSize: 0,
          );

    final dataRaw = json['data'];
    final data = dataRaw is Map
        ? BackupDataEntity.fromJson(dataRaw.cast<String, dynamic>())
        : const BackupDataEntity(
            learningItems: <BackupLearningItemEntity>[],
            learningSubtasks: <BackupLearningSubtaskEntity>[],
            reviewTasks: <BackupReviewTaskEntity>[],
            reviewRecords: <BackupReviewRecordEntity>[],
            settings: <String, dynamic>{},
          );

    return BackupFileEntity(
      schemaVersion: (json['schemaVersion'] as String? ?? '1.0').trim(),
      appVersion: (json['appVersion'] as String? ?? '').trim(),
      dbSchemaVersion: asInt(json['dbSchemaVersion']),
      backupId: (json['backupId'] as String? ?? '').trim(),
      createdAt: (json['createdAt'] as String? ?? '').trim(),
      createdAtUtc: (json['createdAtUtc'] as String? ?? '').trim(),
      checksum: (json['checksum'] as String? ?? '').trim(),
      stats: stats,
      data: data,
      platform: (json['platform'] as String?)?.trim(),
      deviceModel: (json['deviceModel'] as String?)?.trim(),
    );
  }
}

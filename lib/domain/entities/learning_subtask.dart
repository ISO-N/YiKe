/// 文件用途：领域实体 - 学习子任务（LearningSubtask）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

/// 学习子任务实体（领域层）。
///
/// 说明：
/// - 子任务用于表达学习内容的清单项（只做增删改排序）
/// - 不包含完成态（避免与复习轮次口径冲突）
class LearningSubtaskEntity {
  /// 构造函数。
  ///
  /// 参数：
  /// - [uuid] 业务唯一标识（用于备份合并去重，稳定且跨设备）
  /// - [id] 数据库 ID（新建时可为 null）
  /// - [learningItemId] 关联学习内容 ID
  /// - [content] 子任务内容
  /// - [sortOrder] 排序顺序（同一 learningItemId 内从 0 开始）
  /// - [createdAt] 创建时间
  /// - [updatedAt] 更新时间（可空）
  /// - [isMockData] 是否为模拟数据（用于同步/导出隔离）
  const LearningSubtaskEntity({
    required this.uuid,
    this.id,
    required this.learningItemId,
    required this.content,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
    this.isMockData = false,
  });

  final String uuid;
  final int? id;
  final int learningItemId;
  final String content;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isMockData;

  LearningSubtaskEntity copyWith({
    String? uuid,
    int? id,
    int? learningItemId,
    String? content,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMockData,
  }) {
    return LearningSubtaskEntity(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      learningItemId: learningItemId ?? this.learningItemId,
      content: content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMockData: isMockData ?? this.isMockData,
    );
  }
}


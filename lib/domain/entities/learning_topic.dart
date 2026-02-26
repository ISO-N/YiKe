/// 文件用途：领域实体 - 学习主题（LearningTopicEntity），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 学习主题实体。
class LearningTopicEntity {
  /// 构造函数。
  ///
  /// 参数：
  /// - [id] 主键（新建时为空）
  /// - [name] 主题名称
  /// - [description] 主题描述（可选）
  /// - [createdAt] 创建时间
  /// - [updatedAt] 更新时间（可选）
  /// - [itemIds] 关联学习内容 ID（用于详情页展示）
  const LearningTopicEntity({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.itemIds = const [],
  });

  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<int> itemIds;

  /// 复制并替换字段。
  LearningTopicEntity copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? itemIds,
  }) {
    return LearningTopicEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemIds: itemIds ?? this.itemIds,
    );
  }
}


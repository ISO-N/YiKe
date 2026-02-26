/// 文件用途：领域实体 - 学习模板（LearningTemplateEntity），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 学习模板实体。
class LearningTemplateEntity {
  /// 构造函数。
  ///
  /// 参数：
  /// - [id] 主键（新建时为空）
  /// - [name] 模板名称
  /// - [titlePattern] 标题模板
  /// - [notePattern] 备注模板（可选）
  /// - [tags] 默认标签
  /// - [sortOrder] 排序字段
  /// - [createdAt] 创建时间
  /// - [updatedAt] 更新时间（可选）
  const LearningTemplateEntity({
    this.id,
    required this.name,
    required this.titlePattern,
    this.notePattern,
    required this.tags,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String titlePattern;
  final String? notePattern;
  final List<String> tags;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// 复制并替换字段。
  LearningTemplateEntity copyWith({
    int? id,
    String? name,
    String? titlePattern,
    String? notePattern,
    List<String>? tags,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningTemplateEntity(
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
}


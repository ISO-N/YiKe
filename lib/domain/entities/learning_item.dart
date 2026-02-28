/// 文件用途：领域实体 - 学习内容（LearningItem）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

/// 学习内容实体（领域层）。
///
/// 说明：用于表达“用户今天学了什么”，并作为生成复习计划的输入。
class LearningItemEntity {
  /// 构造函数。
  ///
  /// 参数：
  /// - [id] 数据库 ID（新建时可为 null）
  /// - [title] 标题（必填，≤50字）
  /// - [note] 备注（可选，v1.0 仅纯文本）
  /// - [tags] 标签列表（可为空）
  /// - [learningDate] 学习日期（用于生成复习节点）
  /// - [createdAt] 创建时间
  /// - [updatedAt] 更新时间
  /// - [isDeleted] 是否已停用（软删除）
  /// - [deletedAt] 停用时间（可空）
  /// 异常：无（校验由上层负责）。
  const LearningItemEntity({
    this.id,
    required this.title,
    this.note,
    required this.tags,
    required this.learningDate,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.isMockData = false,
  });

  final int? id;
  final String title;
  final String? note;
  final List<String> tags;
  final DateTime learningDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// 是否已停用（软删除标记）。
  final bool isDeleted;

  /// 停用时间（可空）。
  final DateTime? deletedAt;

  /// 是否为模拟数据（v3.1：用于 Debug 模拟数据隔离）。
  final bool isMockData;

  LearningItemEntity copyWith({
    int? id,
    String? title,
    String? note,
    List<String>? tags,
    DateTime? learningDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isMockData,
  }) {
    return LearningItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      learningDate: learningDate ?? this.learningDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isMockData: isMockData ?? this.isMockData,
    );
  }
}

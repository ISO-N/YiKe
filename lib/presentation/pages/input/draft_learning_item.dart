/// 文件用途：录入草稿模型（DraftLearningItem），用于在导入/OCR/模板等流程间传递录入数据（v2.1）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 录入草稿条目。
///
/// 说明：该模型只用于展示层的录入流程，不直接映射数据库结构。
class DraftLearningItem {
  /// 构造函数。
  const DraftLearningItem({
    required this.title,
    this.note,
    this.tags = const [],
    this.topicId,
  });

  final String title;
  final String? note;
  final List<String> tags;

  /// 关联主题（可选，F1.6）。
  final int? topicId;

  DraftLearningItem copyWith({
    String? title,
    String? note,
    List<String>? tags,
    int? topicId,
  }) {
    return DraftLearningItem(
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      topicId: topicId ?? this.topicId,
    );
  }
}


/// 文件用途：用例 - 更新学习内容基础字段（标题/标签）（LearningItem.title & LearningItem.tags）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import '../repositories/learning_item_repository.dart';

/// 更新学习内容基础字段用例。
///
/// 说明：
/// - 用于“任务详情 → 编辑基本信息”场景（不涉及描述/子任务/复习计划）
/// - 仅负责标题与标签的校验与归一化，并委托仓储持久化
class UpdateLearningItemMetaUseCase {
  /// 构造函数。
  const UpdateLearningItemMetaUseCase({
    required LearningItemRepository learningItemRepository,
  }) : _learningItemRepository = learningItemRepository;

  final LearningItemRepository _learningItemRepository;

  /// 执行更新。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// - [title] 新标题（必填，≤50字）
  /// - [tags] 新标签列表（可空；会做 trim/去重/去空）
  ///
  /// 返回值：无。
  /// 异常：
  /// - 当学习内容不存在时抛出 [StateError]
  /// - 当标题为空或过长时抛出 [ArgumentError]
  /// - 当学习内容已停用时由仓储抛出 [StateError]
  Future<void> execute({
    required int learningItemId,
    required String title,
    required List<String> tags,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('标题不能为空');
    }
    if (normalizedTitle.length > 50) {
      throw ArgumentError('标题最多 50 字');
    }

    final existing = await _learningItemRepository.getById(learningItemId);
    if (existing == null) {
      throw StateError('学习内容不存在（id=$learningItemId）');
    }

    // 关键逻辑：标签归一化（trim/过滤空值/去重），避免 UI 输入差异导致无意义的重复更新。
    final normalizedTags = _normalizeTags(tags);

    final next = existing.copyWith(
      title: normalizedTitle,
      tags: normalizedTags,
    );
    await _learningItemRepository.update(next);
  }

  /// 归一化标签列表。
  ///
  /// 规则：
  /// - 去除首尾空格
  /// - 过滤空字符串
  /// - 按首次出现顺序去重（大小写敏感，与录入页保持一致）
  List<String> _normalizeTags(List<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in tags) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out;
  }
}

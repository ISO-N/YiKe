/// 文件用途：仓储接口 - 学习子任务（LearningSubtaskRepository）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../entities/learning_subtask.dart';

/// 学习子任务仓储接口。
abstract class LearningSubtaskRepository {
  /// 按 learningItemId 获取子任务列表（按 sortOrder 升序）。
  Future<List<LearningSubtaskEntity>> getByLearningItemId(int learningItemId);

  /// 批量按 learningItemId 列表获取子任务（用于导出/备份等全量场景）。
  Future<List<LearningSubtaskEntity>> getByLearningItemIds(
    List<int> learningItemIds,
  );

  /// 创建子任务。
  ///
  /// 返回值：保存后的实体（包含 id）。
  Future<LearningSubtaskEntity> create(LearningSubtaskEntity subtask);

  /// 更新子任务。
  Future<LearningSubtaskEntity> update(LearningSubtaskEntity subtask);

  /// 删除子任务。
  Future<void> delete(int id);

  /// 调整排序。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// - [subtaskIds] 目标顺序（从 0 开始）
  Future<void> reorder(int learningItemId, List<int> subtaskIds);
}

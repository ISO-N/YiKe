/// 文件用途：用例 - 减少复习轮次（删除最大轮次，最小保留 1 轮）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../repositories/review_task_repository.dart';

/// 减少复习轮次用例。
class RemoveReviewRoundUseCase {
  /// 构造函数。
  const RemoveReviewRoundUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行减少一轮（删除最大轮次对应任务）。
  ///
  /// 规则：
  /// - 已停用学习内容禁止操作
  /// - 最小轮次为 1（不允许删除最后一轮）
  Future<void> execute(int learningItemId) async {
    final plan = await _reviewTaskRepository.getReviewPlan(learningItemId);
    if (plan.isEmpty) {
      throw StateError('复习计划不存在（learningItemId=$learningItemId）');
    }
    if (plan.first.isDeleted) {
      throw StateError('学习内容已停用，无法减少轮次');
    }

    final maxRound =
        plan.map((e) => e.reviewRound).fold<int>(0, (a, b) => a > b ? a : b);
    if (maxRound <= 1) {
      throw StateError('已达到最小轮次（1）');
    }

    await _reviewTaskRepository.removeLatestReviewRound(learningItemId);
  }
}


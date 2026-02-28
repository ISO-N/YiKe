/// 文件用途：用例 - 增加复习轮次（最大 10 轮）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../../core/utils/ebbinghaus_utils.dart';
import '../repositories/review_task_repository.dart';

/// 增加复习轮次用例。
class AddReviewRoundUseCase {
  /// 构造函数。
  const AddReviewRoundUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行增加一轮。
  ///
  /// 规则：
  /// - 已停用学习内容禁止操作
  /// - 最大轮次上限为 10
  Future<void> execute(int learningItemId) async {
    final plan = await _reviewTaskRepository.getReviewPlan(learningItemId);
    if (plan.isEmpty) {
      throw StateError('复习计划不存在（learningItemId=$learningItemId）');
    }
    if (plan.first.isDeleted) {
      throw StateError('学习内容已停用，无法增加轮次');
    }

    final maxRound =
        plan.map((e) => e.reviewRound).fold<int>(0, (a, b) => a > b ? a : b);
    if (maxRound >= EbbinghausUtils.maxReviewRound) {
      throw StateError('已达到最大轮次（${EbbinghausUtils.maxReviewRound}）');
    }

    await _reviewTaskRepository.addReviewRound(learningItemId);
  }
}


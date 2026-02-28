/// 文件用途：用例 - 获取学习内容的完整复习计划（按轮次正序）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../entities/review_task.dart';
import '../repositories/review_task_repository.dart';

/// 获取复习计划用例。
class GetReviewPlanUseCase {
  /// 构造函数。
  const GetReviewPlanUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 获取复习计划。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// 返回值：按轮次正序排列的任务列表（包含学习内容信息与停用标记）。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<ReviewTaskViewEntity>> execute(int learningItemId) {
    return _reviewTaskRepository.getReviewPlan(learningItemId);
  }
}


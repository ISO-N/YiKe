/// 文件用途：用例 - 获取学习统计数据（连续打卡、完成率、标签分布）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../../core/utils/date_utils.dart';
import '../repositories/learning_item_repository.dart';
import '../repositories/review_task_repository.dart';

/// 学习统计结果（F7）。
class StatisticsResult {
  /// 构造函数。
  const StatisticsResult({
    required this.consecutiveCompletedDays,
    required this.weekCompleted,
    required this.weekTotal,
    required this.monthCompleted,
    required this.monthTotal,
    required this.tagDistribution,
  });

  /// 连续打卡天数。
  final int consecutiveCompletedDays;

  /// 本周完成数量（done）。
  final int weekCompleted;

  /// 本周总数量（done + pending，skipped 不计入）。
  final int weekTotal;

  /// 本月完成数量（done）。
  final int monthCompleted;

  /// 本月总数量（done + pending，skipped 不计入）。
  final int monthTotal;

  /// 标签分布：Map（key=tag，value=count）。
  final Map<String, int> tagDistribution;

  /// 本周完成率（0~1）。
  double get weekCompletionRate => weekTotal == 0 ? 0 : weekCompleted / weekTotal;

  /// 本月完成率（0~1）。
  double get monthCompletionRate => monthTotal == 0 ? 0 : monthCompleted / monthTotal;
}

/// 获取统计数据用例（F7）。
class GetStatisticsUseCase {
  /// 构造函数。
  const GetStatisticsUseCase({
    required ReviewTaskRepository reviewTaskRepository,
    required LearningItemRepository learningItemRepository,
  })  : _reviewTaskRepository = reviewTaskRepository,
        _learningItemRepository = learningItemRepository;

  final ReviewTaskRepository _reviewTaskRepository;
  final LearningItemRepository _learningItemRepository;

  /// 执行用例。
  ///
  /// 参数：
  /// - [today] 用于测试/注入的“今天”（默认取当前时间）
  /// 返回值：[StatisticsResult]。
  Future<StatisticsResult> execute({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final todayStart = YikeDateUtils.atStartOfDay(now);

    // 本周：按周一为一周起点（ISO 习惯）。
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // 本月：从 1 号 00:00 到下月 1 号 00:00。
    final monthStart = DateTime(todayStart.year, todayStart.month, 1);
    final monthEnd = DateTime(todayStart.year, todayStart.month + 1, 1);

    final consecutive = await _reviewTaskRepository.getConsecutiveCompletedDays(today: now);
    final (weekCompleted, weekTotal) = await _reviewTaskRepository.getTaskStatsInRange(weekStart, weekEnd);
    final (monthCompleted, monthTotal) = await _reviewTaskRepository.getTaskStatsInRange(monthStart, monthEnd);
    final tags = await _learningItemRepository.getTagDistribution();

    return StatisticsResult(
      consecutiveCompletedDays: consecutive,
      weekCompleted: weekCompleted,
      weekTotal: weekTotal,
      monthCompleted: monthCompleted,
      monthTotal: monthTotal,
      tagDistribution: tags,
    );
  }
}

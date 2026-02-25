/// 文件用途：领域实体 - 单日任务统计（用于日历标记/统计计算）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

/// 单日任务统计。
///
/// 说明：
/// - 以“日期（年月日）”为粒度聚合 review_tasks 的状态数量。
/// - 用于 F6 日历圆点标记与部分统计口径计算。
class TaskDayStats {
  /// 构造函数。
  ///
  /// 参数：
  /// - [pendingCount] 待复习数量
  /// - [doneCount] 已完成数量
  /// - [skippedCount] 已跳过数量
  const TaskDayStats({
    required this.pendingCount,
    required this.doneCount,
    required this.skippedCount,
  });

  final int pendingCount;
  final int doneCount;
  final int skippedCount;

  /// 总数（包含 pending/done/skipped）。
  int get totalCount => pendingCount + doneCount + skippedCount;

  /// 是否存在待复习任务。
  bool get hasPending => pendingCount > 0;

  /// 是否存在已完成任务。
  bool get hasDone => doneCount > 0;

  /// 是否存在已跳过任务。
  bool get hasSkipped => skippedCount > 0;
}

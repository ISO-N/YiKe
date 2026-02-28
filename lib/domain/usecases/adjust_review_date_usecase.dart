/// 文件用途：用例 - 调整复习计划日期（定位键：learningItemId + reviewRound）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../../core/utils/date_utils.dart';
import '../entities/review_task.dart';
import '../repositories/review_task_repository.dart';

/// 调整复习日期用例。
class AdjustReviewDateUseCase {
  /// 构造函数。
  const AdjustReviewDateUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行调整。
  ///
  /// 约束（规格 v1.4）：
  /// - 最小日期：明天（不能选今天或过去）
  /// - 轮次约束：第 N 轮需落在 [第 N-1 轮 +1天, 第 N+1 轮 -1天]（若存在）
  /// - 状态约束：仅 pending 状态可调整
  /// - 已停用学习内容禁止操作
  Future<void> execute({
    required int learningItemId,
    required int reviewRound,
    required DateTime newDate,
  }) async {
    final plan = await _reviewTaskRepository.getReviewPlan(learningItemId);
    if (plan.isEmpty) {
      throw StateError('复习计划不存在（learningItemId=$learningItemId）');
    }

    final any = plan.first;
    if (any.isDeleted) {
      throw StateError('学习内容已停用，无法调整计划');
    }

    ReviewTaskViewEntity? target;
    for (final t in plan) {
      if (t.reviewRound == reviewRound) {
        target = t;
        break;
      }
    }
    if (target == null) {
      throw StateError(
        '复习任务不存在（learningItemId=$learningItemId, reviewRound=$reviewRound）',
      );
    }
    if (target.status != ReviewTaskStatus.pending) {
      throw StateError('仅待复习任务允许调整日期');
    }

    final normalized = DateTime(newDate.year, newDate.month, newDate.day);
    final tomorrow = YikeDateUtils
        .atStartOfDay(DateTime.now())
        .add(const Duration(days: 1));
    if (normalized.isBefore(tomorrow)) {
      throw StateError('新日期不能早于明天');
    }

    final sorted = [...plan]..sort((a, b) => a.reviewRound.compareTo(b.reviewRound));
    ReviewTaskViewEntity? prev;
    ReviewTaskViewEntity? next;
    for (final t in sorted) {
      if (t.reviewRound < reviewRound) {
        prev = t;
      } else if (t.reviewRound > reviewRound) {
        next ??= t;
      }
    }

    DateTime minAllowed = tomorrow;
    if (prev != null) {
      final prevDay = DateTime(
        prev.scheduledDate.year,
        prev.scheduledDate.month,
        prev.scheduledDate.day,
      );
      final candidate = prevDay.add(const Duration(days: 1));
      if (candidate.isAfter(minAllowed)) minAllowed = candidate;
    }

    DateTime? maxAllowed;
    if (next != null) {
      final nextDay = DateTime(
        next.scheduledDate.year,
        next.scheduledDate.month,
        next.scheduledDate.day,
      );
      maxAllowed = nextDay.subtract(const Duration(days: 1));
    }

    if (normalized.isBefore(minAllowed)) {
      throw StateError('新日期不能早于允许范围（最早：${_fmt(minAllowed)}）');
    }
    if (maxAllowed != null && normalized.isAfter(maxAllowed)) {
      throw StateError('新日期不能晚于允许范围（最晚：${_fmt(maxAllowed)}）');
    }

    await _reviewTaskRepository.adjustReviewDate(
      learningItemId: learningItemId,
      reviewRound: reviewRound,
      scheduledDate: normalized,
    );
  }

  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

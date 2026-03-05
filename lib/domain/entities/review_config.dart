/// 文件用途：领域实体 - 复习配置（默认间隔与日期计算）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../../core/utils/ebbinghaus_utils.dart';

/// 复习配置。
///
/// 说明：默认支持 1-10 轮复习间隔（具体由 [EbbinghausUtils.defaultIntervalsDays] 决定）。
class ReviewConfig {
  /// 默认复习间隔（单位：天）。
  static const List<int> defaultIntervals =
      EbbinghausUtils.defaultIntervalsDays;

  /// 计算第 N 次复习的日期。
  ///
  /// 参数：
  /// - [learningDate] 学习日期
  /// - [round] 复习轮次（从 1 开始）
  /// 返回值：复习日期
  /// 异常：当 [round] 越界时抛出 [RangeError]。
  static DateTime calculateReviewDate(DateTime learningDate, int round) {
    return EbbinghausUtils.calculateReviewDate(learningDate, round);
  }
}

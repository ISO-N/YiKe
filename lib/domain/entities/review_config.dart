/// 文件用途：领域实体 - 复习配置（默认间隔与日期计算）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../../core/utils/ebbinghaus_utils.dart';

/// 复习配置。
///
/// 说明：v1.0 MVP 固定使用默认间隔 [1,2,4,7,15] 天。
class ReviewConfig {
  /// 默认复习间隔（单位：天）。
  static const List<int> defaultIntervals = EbbinghausUtils.defaultIntervalsDays;

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


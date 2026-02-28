/// 文件用途：艾宾浩斯复习间隔相关工具（v1.0 固定间隔）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

class EbbinghausUtils {
  EbbinghausUtils._();

  /// 默认复习间隔（单位：天）。
  ///
  /// 说明：
  /// - v1.0 基线：前 5 轮 [1, 2, 4, 7, 15]
  /// - v1.4（规格增强）：扩展第 6-10 轮 [30, 60, 90, 120, 180]
  /// - 完整列表（1-10 轮）：[1, 2, 4, 7, 15, 30, 60, 90, 120, 180]
  static const List<int> defaultIntervalsDays = [
    1,
    2,
    4,
    7,
    15,
    30,
    60,
    90,
    120,
    180,
  ];

  /// 最大复习轮次（应用层约束）。
  static const int maxReviewRound = 10;

  /// 根据学习日期与复习轮次计算复习日期。
  ///
  /// 参数：
  /// - [learningDate] 学习日期（通常为录入当天）。
  /// - [round] 复习轮次，从 1 开始。
  /// 返回值：复习日期（DateTime）。
  /// 异常：
  /// - 当 [round] 不在 1..10 范围内时抛出 [RangeError]。
  static DateTime calculateReviewDate(DateTime learningDate, int round) {
    final interval = defaultIntervalsDays[round - 1];
    return learningDate.add(Duration(days: interval));
  }
}

/// 文件用途：领域实体 - 复习间隔配置（ReviewIntervalConfigEntity），用于复习预览与生成（F1.5）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 复习间隔配置实体。
///
/// 说明：
/// - round：复习轮次（1-5）
/// - intervalDays：与学习日的间隔天数（最小 1）
/// - enabled：是否启用该轮次
class ReviewIntervalConfigEntity {
  /// 构造函数。
  ///
  /// 异常：
  /// - 当 [round] 不在 1-5 或 [intervalDays] < 1 时抛出 [ArgumentError]。
  ReviewIntervalConfigEntity({
    required this.round,
    required this.intervalDays,
    required this.enabled,
  }) {
    if (round < 1 || round > 5) {
      throw ArgumentError('round 必须在 1-5 范围内');
    }
    if (intervalDays < 1) {
      throw ArgumentError('intervalDays 最小为 1');
    }
  }

  final int round;
  final int intervalDays;
  final bool enabled;

  /// 复制并替换字段。
  ReviewIntervalConfigEntity copyWith({
    int? round,
    int? intervalDays,
    bool? enabled,
  }) {
    return ReviewIntervalConfigEntity(
      round: round ?? this.round,
      intervalDays: intervalDays ?? this.intervalDays,
      enabled: enabled ?? this.enabled,
    );
  }
}


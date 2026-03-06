/// 文件用途：领域实体 - 番茄钟记录（PomodoroRecordEntity）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

/// 番茄钟记录实体。
class PomodoroRecordEntity {
  /// 构造函数。
  const PomodoroRecordEntity({
    this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.phaseType,
    required this.completed,
  });

  /// 数据库自增主键。
  final int? id;

  /// 阶段开始时间。
  final DateTime startTime;

  /// 阶段时长（分钟）。
  final int durationMinutes;

  /// 阶段类型：work / shortBreak / longBreak。
  final String phaseType;

  /// 是否完整完成。
  final bool completed;

  /// 生成一个带变更字段的新实体。
  PomodoroRecordEntity copyWith({
    int? id,
    DateTime? startTime,
    int? durationMinutes,
    String? phaseType,
    bool? completed,
  }) {
    return PomodoroRecordEntity(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      phaseType: phaseType ?? this.phaseType,
      completed: completed ?? this.completed,
    );
  }
}

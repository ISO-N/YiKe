/// 文件用途：Drift 表定义 - 番茄钟记录表（pomodoro_records），用于保存专注/休息阶段历史。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import 'package:drift/drift.dart';

/// 番茄钟记录表。
///
/// 说明：
/// - 主要用于统计“今日完成数 / 本周完成数 / 累计专注时长”
/// - phaseType 允许记录 work / shortBreak / longBreak，便于未来扩展
/// - 统计完成番茄时，仅以 `phase_type=work && completed=1` 为准
class PomodoroRecords extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 阶段开始时间。
  DateTimeColumn get startTime => dateTime()();

  /// 阶段时长（分钟）。
  IntColumn get durationMinutes => integer()();

  /// 阶段类型：work / shortBreak / longBreak。
  TextColumn get phaseType => text().withLength(min: 1, max: 20)();

  /// 是否完整完成该阶段。
  BoolColumn get completed => boolean()();
}

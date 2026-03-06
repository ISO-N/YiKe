/// 文件用途：仓储接口 - 番茄钟记录与统计（PomodoroRepository）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import '../entities/pomodoro_record.dart';
import '../entities/pomodoro_stats.dart';

/// 番茄钟仓储接口。
abstract class PomodoroRepository {
  /// 新增一条记录。
  Future<int> createRecord(PomodoroRecordEntity entity);

  /// 更新一条记录。
  Future<bool> updateRecord(PomodoroRecordEntity entity);

  /// 删除一条记录。
  Future<int> deleteRecord(int id);

  /// 查询全部记录。
  Future<List<PomodoroRecordEntity>> getAllRecords();

  /// 查询统计摘要。
  Future<PomodoroStatsEntity> getStats({DateTime? now});
}

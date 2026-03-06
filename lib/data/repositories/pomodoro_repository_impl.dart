/// 文件用途：番茄钟仓储实现（PomodoroRepositoryImpl）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import '../../domain/entities/pomodoro_record.dart';
import '../../domain/entities/pomodoro_stats.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../database/daos/pomodoro_record_dao.dart';
import '../database/database.dart';

/// 番茄钟仓储实现。
class PomodoroRepositoryImpl implements PomodoroRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 番茄钟记录 DAO。
  PomodoroRepositoryImpl({required PomodoroRecordDao dao}) : _dao = dao;

  final PomodoroRecordDao _dao;

  @override
  Future<int> createRecord(PomodoroRecordEntity entity) {
    return _dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: entity.startTime,
        durationMinutes: entity.durationMinutes,
        phaseType: entity.phaseType,
        completed: entity.completed,
      ),
    );
  }

  @override
  Future<int> deleteRecord(int id) => _dao.deleteRecord(id);

  @override
  Future<List<PomodoroRecordEntity>> getAllRecords() async {
    final rows = await _dao.getAllRecords();
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<PomodoroStatsEntity> getStats({DateTime? now}) async {
    final todayCompletedCount = await _dao.getTodayCompletedWorkCount(now: now);
    final weekCompletedCount = await _dao.getWeekCompletedWorkCount(now: now);
    final totalFocusMinutes = await _dao.getTotalCompletedWorkMinutes();
    return PomodoroStatsEntity(
      todayCompletedCount: todayCompletedCount,
      weekCompletedCount: weekCompletedCount,
      totalFocusMinutes: totalFocusMinutes,
    );
  }

  @override
  Future<bool> updateRecord(PomodoroRecordEntity entity) {
    final id = entity.id;
    if (id == null) {
      throw ArgumentError('更新番茄钟记录时必须提供 id');
    }
    return _dao.updateRecord(
      PomodoroRecord(
        id: id,
        startTime: entity.startTime,
        durationMinutes: entity.durationMinutes,
        phaseType: entity.phaseType,
        completed: entity.completed,
      ),
    );
  }

  /// 将 Drift 记录映射为领域实体。
  PomodoroRecordEntity _mapRecord(PomodoroRecord row) {
    return PomodoroRecordEntity(
      id: row.id,
      startTime: row.startTime,
      durationMinutes: row.durationMinutes,
      phaseType: row.phaseType,
      completed: row.completed,
    );
  }
}

/// 文件用途：PomodoroRecordDao - 番茄钟记录数据库访问封装（Drift）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 番茄钟记录 DAO。
///
/// 说明：封装番茄钟历史记录的增删改查与统计查询。
class PomodoroRecordDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  PomodoroRecordDao(this.db);

  final AppDatabase db;

  /// 插入一条番茄钟记录。
  ///
  /// 参数：
  /// - [companion] 插入数据。
  /// 返回值：新记录 ID。
  Future<int> insertRecord(PomodoroRecordsCompanion companion) {
    return db.into(db.pomodoroRecords).insert(companion);
  }

  /// 更新一条番茄钟记录。
  ///
  /// 参数：
  /// - [record] 目标记录。
  /// 返回值：是否更新成功。
  Future<bool> updateRecord(PomodoroRecord record) {
    return db.update(db.pomodoroRecords).replace(record);
  }

  /// 删除指定 ID 的番茄钟记录。
  ///
  /// 参数：
  /// - [id] 记录 ID。
  /// 返回值：删除行数。
  Future<int> deleteRecord(int id) {
    return (db.delete(db.pomodoroRecords)..where((t) => t.id.equals(id))).go();
  }

  /// 查询全部番茄钟记录。
  ///
  /// 返回值：按开始时间倒序排列的记录列表。
  Future<List<PomodoroRecord>> getAllRecords() {
    return (db.select(db.pomodoroRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();
  }

  /// 查询今日完成的工作阶段数量。
  ///
  /// 参数：
  /// - [now] 统计基准时间。
  /// 返回值：今日完成番茄数。
  Future<int> getTodayCompletedWorkCount({DateTime? now}) async {
    final anchor = now ?? DateTime.now();
    final start = DateTime(anchor.year, anchor.month, anchor.day);
    final end = start.add(const Duration(days: 1));
    return _countCompletedWork(start: start, end: end);
  }

  /// 查询本周完成的工作阶段数量。
  ///
  /// 参数：
  /// - [now] 统计基准时间。
  /// 返回值：本周完成番茄数（周一为一周起点）。
  Future<int> getWeekCompletedWorkCount({DateTime? now}) async {
    final anchor = now ?? DateTime.now();
    final today = DateTime(anchor.year, anchor.month, anchor.day);
    final start = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final end = start.add(const Duration(days: 7));
    return _countCompletedWork(start: start, end: end);
  }

  /// 查询累计完成的专注分钟数。
  ///
  /// 返回值：累计分钟。
  Future<int> getTotalCompletedWorkMinutes() async {
    final durationExpr = db.pomodoroRecords.durationMinutes.sum();
    final row =
        await (db.selectOnly(db.pomodoroRecords)
              ..addColumns([durationExpr])
              ..where(db.pomodoroRecords.phaseType.equals('work'))
              ..where(db.pomodoroRecords.completed.equals(true)))
            .getSingle();
    return row.read(durationExpr) ?? 0;
  }

  /// 在指定时间范围内统计完成的工作阶段数量。
  Future<int> _countCompletedWork({
    required DateTime start,
    required DateTime end,
  }) async {
    final countExpr = db.pomodoroRecords.id.count();
    final row =
        await (db.selectOnly(db.pomodoroRecords)
              ..addColumns([countExpr])
              ..where(db.pomodoroRecords.phaseType.equals('work'))
              ..where(db.pomodoroRecords.completed.equals(true))
              ..where(db.pomodoroRecords.startTime.isBiggerOrEqualValue(start))
              ..where(db.pomodoroRecords.startTime.isSmallerThanValue(end)))
            .getSingle();
    return row.read(countExpr) ?? 0;
  }
}

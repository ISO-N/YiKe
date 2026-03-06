// 文件用途：PomodoroRecordDao 单元测试（CRUD 与统计查询）。
// 作者：Codex
// 创建日期：2026-03-06

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/pomodoro_record_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late PomodoroRecordDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = PomodoroRecordDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert/update/deleteRecord 可完成基础 CRUD', () async {
    final id = await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: DateTime(2026, 3, 6, 9),
        durationMinutes: 25,
        phaseType: 'work',
        completed: true,
      ),
    );

    final all = await dao.getAllRecords();
    expect(all.length, 1);
    expect(all.single.id, id);

    final updated = await dao.updateRecord(
      all.single.copyWith(durationMinutes: 30),
    );
    expect(updated, true);

    final afterUpdate = await dao.getAllRecords();
    expect(afterUpdate.single.durationMinutes, 30);

    final deleted = await dao.deleteRecord(id);
    expect(deleted, 1);
    expect(await dao.getAllRecords(), isEmpty);
  });

  test('统计查询仅计算完整完成的工作阶段', () async {
    final now = DateTime(2026, 3, 6, 12);
    final weekStart = DateTime(2026, 3, 3, 9);

    await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: now.subtract(const Duration(hours: 2)),
        durationMinutes: 25,
        phaseType: 'work',
        completed: true,
      ),
    );
    await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: now.subtract(const Duration(days: 1)),
        durationMinutes: 25,
        phaseType: 'work',
        completed: true,
      ),
    );
    await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: weekStart,
        durationMinutes: 15,
        phaseType: 'shortBreak',
        completed: true,
      ),
    );
    await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: now.subtract(const Duration(days: 10)),
        durationMinutes: 40,
        phaseType: 'work',
        completed: true,
      ),
    );
    await dao.insertRecord(
      PomodoroRecordsCompanion.insert(
        startTime: now.subtract(const Duration(minutes: 30)),
        durationMinutes: 25,
        phaseType: 'work',
        completed: false,
      ),
    );

    final todayCount = await dao.getTodayCompletedWorkCount(now: now);
    final weekCount = await dao.getWeekCompletedWorkCount(now: now);
    final totalMinutes = await dao.getTotalCompletedWorkMinutes();

    expect(todayCount, 1);
    expect(weekCount, 2);
    expect(totalMinutes, 90);
  });
}

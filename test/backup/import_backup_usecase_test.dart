// 文件用途：单元测试 - 备份导入（合并/覆盖、去重与外键修复）。
// 作者：Codex
// 创建日期：2026-02-28

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yike/core/utils/backup_utils.dart';
import 'package:yike/data/database/daos/backup_dao.dart';
import 'package:yike/data/database/daos/settings_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/backup_repository_impl.dart';
import 'package:yike/data/repositories/settings_repository_impl.dart';
import 'package:yike/data/repositories/theme_settings_repository_impl.dart';
import 'package:yike/domain/entities/backup_file.dart';
import 'package:yike/domain/entities/review_task.dart';
import 'package:yike/domain/usecases/import_backup_usecase.dart';
import 'package:yike/infrastructure/storage/backup_storage.dart';
import 'package:yike/infrastructure/storage/secure_storage_service.dart';
import '../helpers/test_database.dart';

void main() {
  test('合并导入：按 uuid Upsert，保留 createdAt，不产生重复数据', () async {
    final db = createInMemoryDatabase();
    final tempDir = await Directory.systemTemp.createTemp('yike_backup_test_');
    addTearDown(() async {
      await db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    final settingsDao = SettingsDao(db);
    final secure = SecureStorageService();
    final settingsRepo = SettingsRepositoryImpl(
      dao: settingsDao,
      secureStorageService: secure,
    );
    final themeRepo = ThemeSettingsRepositoryImpl(
      dao: settingsDao,
      secureStorageService: secure,
    );

    // 初始化本机数据：一个 item + 一个 task。
    final now = DateTime.now();
    final itemId = await db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            uuid: const Value('item-1'),
            title: '旧标题',
            learningDate: now,
            createdAt: Value(now.subtract(const Duration(days: 10))),
          ),
        );
    final taskCreatedAt = now.subtract(const Duration(days: 9));
    final taskId = await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            uuid: const Value('task-1'),
            learningItemId: itemId,
            reviewRound: 1,
            scheduledDate: now,
            status: const Value('pending'),
            createdAt: Value(taskCreatedAt),
            updatedAt: Value(taskCreatedAt),
            isMockData: const Value(false),
          ),
        );

    // 构造备份：同 uuid 的 item/task，但标题与状态不同。
    final data = BackupDataEntity(
      learningItems: [
        BackupLearningItemEntity(
          uuid: 'item-1',
          title: '新标题',
          note: null,
          tags: const ['a'],
          learningDate: now.subtract(const Duration(days: 1)).toIso8601String(),
          createdAt: now.subtract(const Duration(days: 100)).toIso8601String(),
          updatedAt: now.toIso8601String(),
          isDeleted: false,
          deletedAt: null,
        ),
      ],
      reviewTasks: [
        BackupReviewTaskEntity(
          uuid: 'task-1',
          learningItemUuid: 'item-1',
          reviewRound: 1,
          scheduledDate: now.add(const Duration(days: 1)).toIso8601String(),
          status: ReviewTaskStatus.done.toDbValue(),
          completedAt: now.toIso8601String(),
          skippedAt: null,
          createdAt: now.subtract(const Duration(days: 100)).toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ],
      reviewRecords: const [],
      settings: const {
        'theme_mode': 'dark',
        'review_intervals': [],
        // 通知类设置在导入时会被忽略，这里不提供也可。
      },
    );

    final canonical = BackupUtils.canonicalizeDataJson(
      data.toJson().cast<String, dynamic>(),
    );
    final checksum = await BackupUtils.sha256Hex(canonical);
    final payloadSize = BackupUtils.utf8BytesLength(canonical);

    final backup = BackupFileEntity(
      schemaVersion: '1.0',
      appVersion: 'test',
      dbSchemaVersion: 0,
      backupId: 'backup-1',
      createdAt: BackupUtils.formatLocalIsoWithOffset(now),
      createdAtUtc: now.toUtc().toIso8601String(),
      checksum: checksum,
      stats: BackupStatsEntity(
        learningItems: 1,
        reviewTasks: 1,
        reviewRecords: 0,
        payloadSize: payloadSize,
      ),
      data: data,
      platform: 'android',
    );

    final backupFile = File(p.join(tempDir.path, 't.yikebackup'));
    await backupFile.writeAsString(jsonEncode(backup.toJson()), flush: true);

    final repo = BackupRepositoryImpl(
      db: db,
      backupDao: BackupDao(db),
      settingsRepository: settingsRepo,
      themeSettingsRepository: themeRepo,
      storage: BackupStorage(baseDir: tempDir),
    );
    final useCase = ImportBackupUseCase(repository: repo);

    final token = BackupCancelToken();
    final preview = await useCase.preview(file: backupFile, cancelToken: token);
    await useCase.execute(
      preview: preview,
      strategy: BackupImportStrategy.merge,
      cancelToken: token,
    );

    // 断言：item 标题更新，但 createdAt 保留本机原值（不被覆盖）。
    final item = await (db.select(
      db.learningItems,
    )..where((t) => t.uuid.equals('item-1'))).getSingle();
    expect(item.title, '新标题');
    expect(item.id, itemId);
    final expectedItemCreatedAt = now.subtract(const Duration(days: 10));
    expect(item.createdAt.difference(expectedItemCreatedAt).inSeconds.abs(), 0);

    // 断言：task 状态更新，但 createdAt 与 learning_item_id 不被覆盖。
    final task = await (db.select(
      db.reviewTasks,
    )..where((t) => t.uuid.equals('task-1'))).getSingle();
    expect(task.id, taskId);
    expect(task.learningItemId, itemId);
    expect(task.status, ReviewTaskStatus.done.toDbValue());
    expect(task.createdAt.difference(taskCreatedAt).inSeconds.abs(), 0);

    // 断言：主题设置被覆盖导入。
    final theme = await themeRepo.getThemeSettings();
    expect(theme.mode, 'dark');
  });
}

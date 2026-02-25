// 文件用途：SettingsRepositoryImpl 单元测试（默认值、加密存储与读取回放）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/settings_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/settings_repository_impl.dart';
import 'package:yike/domain/entities/app_settings.dart';
import 'package:yike/infrastructure/storage/secure_storage_service.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDatabase();
    repo = SettingsRepositoryImpl(
      dao: SettingsDao(db),
      secureStorageService: SecureStorageService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('getSettings 在无数据时返回 defaults', () async {
    final s = await repo.getSettings();
    expect(s.reminderTime, AppSettingsEntity.defaults.reminderTime);
    expect(
      s.notificationsEnabled,
      AppSettingsEntity.defaults.notificationsEnabled,
    );
  });

  test('saveSettings 后可正常读取（含 lastNotifiedDate）', () async {
    final input = AppSettingsEntity.defaults.copyWith(
      reminderTime: '10:30',
      doNotDisturbStart: '23:00',
      notificationsEnabled: false,
      lastNotifiedDate: '2026-02-25',
    );
    await repo.saveSettings(input);
    final out = await repo.getSettings();
    expect(out.reminderTime, '10:30');
    expect(out.doNotDisturbStart, '23:00');
    expect(out.notificationsEnabled, false);
    expect(out.lastNotifiedDate, '2026-02-25');
  });
}

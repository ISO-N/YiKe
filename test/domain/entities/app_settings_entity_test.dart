// 文件用途：AppSettingsEntity 单元测试（默认值与 copyWith）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/app_settings.dart';

void main() {
  test('defaults 符合 v1.0 约定', () {
    expect(AppSettingsEntity.defaults.reminderTime, '09:00');
    expect(AppSettingsEntity.defaults.doNotDisturbStart, '22:00');
    expect(AppSettingsEntity.defaults.doNotDisturbEnd, '08:00');
    expect(AppSettingsEntity.defaults.notificationsEnabled, true);
    expect(AppSettingsEntity.defaults.notificationPermissionGuideDismissed, false);
    expect(AppSettingsEntity.defaults.lastNotifiedDate, null);
  });

  test('copyWith 仅覆盖指定字段', () {
    final base = AppSettingsEntity.defaults;
    final next = base.copyWith(
      notificationsEnabled: false,
      lastNotifiedDate: '2026-02-25',
    );
    expect(next.notificationsEnabled, false);
    expect(next.lastNotifiedDate, '2026-02-25');
    expect(next.reminderTime, base.reminderTime);
  });
}


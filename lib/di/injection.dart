/// 文件用途：依赖注入入口，集中管理 ProviderContainer 的创建与全局初始化。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../infrastructure/sync/device_identity_service.dart';
import '../infrastructure/storage/secure_storage_service.dart';
import 'providers.dart';

class AppInjection {
  /// 创建并返回全局 `ProviderContainer`。
  ///
  /// 返回值：包含全局依赖的容器实例。
  /// 异常：初始化依赖失败时可能抛出异常（如数据库打开失败）。
  static Future<ProviderContainer> createContainer() async {
    final db = await AppDatabase.open();

    // v3.0：生成并注入稳定的设备 ID（用于局域网发现/配对/同步）。
    final secureStorageService = SecureStorageService();
    final deviceId = await DeviceIdentityService(
      secureStorageService: secureStorageService,
    ).getOrCreateDeviceId();

    // v1.0 MVP：数据库需要在后台任务与 UI 层共享同一套 schema，因此在启动时注入。
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureStorageServiceProvider.overrideWithValue(secureStorageService),
        deviceIdProvider.overrideWithValue(deviceId),
      ],
    );
  }
}

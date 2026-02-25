/// 文件用途：仓储接口 - 应用设置（SettingsRepository）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/app_settings.dart';

/// 应用设置仓储接口。
abstract class SettingsRepository {
  /// 获取设置（若未写入则返回默认设置）。
  Future<AppSettingsEntity> getSettings();

  /// 保存设置（整体覆盖）。
  Future<void> saveSettings(AppSettingsEntity settings);
}


/// 文件用途：仓储接口 - 番茄钟配置（PomodoroSettingsRepository）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import '../entities/pomodoro_settings.dart';

/// 番茄钟配置仓储接口。
abstract class PomodoroSettingsRepository {
  /// 读取配置。
  Future<PomodoroSettingsEntity> getSettings();

  /// 保存配置。
  Future<void> saveSettings(PomodoroSettingsEntity settings);
}

/// 文件用途：主题设置仓储接口。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../entities/theme_settings.dart';

/// 主题设置仓储接口。
abstract class ThemeSettingsRepository {
  /// 获取主题设置（若不存在则返回默认值）。
  ///
  /// 返回值：主题设置实体。
  /// 异常：由实现层决定；建议实现层内部兜底默认值。
  Future<ThemeSettingsEntity> getThemeSettings();

  /// 保存主题设置。
  ///
  /// 参数：
  /// - [settings] 主题设置实体
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<void> saveThemeSettings(ThemeSettingsEntity settings);
}


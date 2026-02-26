/// 文件用途：主题设置实体（用于主题模式持久化）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 主题设置实体。
///
/// 说明：
/// - [mode] 取值：'system' | 'light' | 'dark'
class ThemeSettingsEntity {
  /// 构造函数。
  const ThemeSettingsEntity({required this.mode});

  /// 主题模式字符串值。
  final String mode;

  /// 默认设置（跟随系统）。
  factory ThemeSettingsEntity.defaults() {
    return const ThemeSettingsEntity(mode: 'system');
  }

  /// 从 JSON 反序列化。
  factory ThemeSettingsEntity.fromJson(Map<String, dynamic> json) {
    return ThemeSettingsEntity(mode: json['mode'] as String? ?? 'system');
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => {'mode': mode};
}

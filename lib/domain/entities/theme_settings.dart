/// 文件用途：主题设置实体（用于主题模式持久化）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 主题设置实体。
///
/// 说明：
/// - [mode] 取值：'system' | 'light' | 'dark'
/// - [seedColorHex] 主题种子色（HEX：#RRGGBB）
/// - [amoled] AMOLED 深色模式开关（仅在深色主题下生效）
class ThemeSettingsEntity {
  /// 构造函数。
  const ThemeSettingsEntity({
    required this.mode,
    required this.seedColorHex,
    required this.amoled,
  });

  /// 主题模式字符串值。
  final String mode;

  /// 主题种子色（HEX）。
  final String seedColorHex;

  /// AMOLED 深色模式开关。
  final bool amoled;

  /// 默认设置（跟随系统）。
  factory ThemeSettingsEntity.defaults() {
    return const ThemeSettingsEntity(
      mode: 'system',
      seedColorHex: '#2196F3',
      amoled: false,
    );
  }

  /// 从 JSON 反序列化。
  factory ThemeSettingsEntity.fromJson(Map<String, dynamic> json) {
    return ThemeSettingsEntity(
      mode: json['mode'] as String? ?? 'system',
      seedColorHex: json['seed_color'] as String? ?? '#2196F3',
      amoled: json['amoled'] as bool? ?? false,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => {
    'mode': mode,
    'seed_color': seedColorHex,
    'amoled': amoled,
  };

  /// 拷贝并修改。
  ThemeSettingsEntity copyWith({
    String? mode,
    String? seedColorHex,
    bool? amoled,
  }) {
    return ThemeSettingsEntity(
      mode: mode ?? this.mode,
      seedColorHex: seedColorHex ?? this.seedColorHex,
      amoled: amoled ?? this.amoled,
    );
  }
}

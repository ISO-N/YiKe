/// 文件用途：主题模式状态管理 Provider（深色/浅色/跟随系统）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/theme_settings.dart';
import '../../domain/repositories/theme_settings_repository.dart';

/// 主题模式（产品层语义）。
enum AppThemeMode {
  system('system', '跟随系统'),
  light('light', '浅色'),
  dark('dark', '深色');

  const AppThemeMode(this.value, this.label);

  /// 存储值。
  final String value;

  /// UI 展示文案。
  final String label;

  /// 从字符串值转换为枚举。
  static AppThemeMode fromValue(String value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// 转换为 Flutter ThemeMode。
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// 主题模式 Provider。
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final repository = ref.read(themeSettingsRepositoryProvider);
  return ThemeModeNotifier(repository);
});

/// 主题模式状态管理器。
///
/// 负责：
/// 1. 启动时从 Repository 加载用户偏好
/// 2. 提供切换主题的方法
/// 3. 持久化用户选择到数据库
/// 4. "跟随系统"模式下，Flutter 会自动响应 platformBrightness 变化
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._repository) : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  final ThemeSettingsRepository _repository;

  /// 从 Repository 加载主题模式。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：数据库异常时使用默认主题。
  Future<void> _loadThemeMode() async {
    try {
      final settings = await _repository.getThemeSettings();
      state = AppThemeMode.fromValue(settings.mode);
    } catch (_) {
      state = AppThemeMode.system;
    }
  }

  /// 切换主题模式。
  ///
  /// 参数：
  /// - [mode] 新的主题模式
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时只更新内存状态。
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    try {
      await _repository.saveThemeSettings(
        ThemeSettingsEntity(mode: mode.value),
      );
    } catch (_) {
      // 数据库写入失败时只更新内存状态，下次启动会回退到持久化值或默认值。
    }
  }
}


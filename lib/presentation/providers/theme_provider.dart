/// 文件用途：主题设置状态管理 Provider（主题模式/主题色/AMOLED）。
/// 作者：Codex
/// 创建日期：2026-02-26
/// 最后更新：2026-03-04（支持自定义主题色与 AMOLED 深色模式）
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

/// 主题设置 Provider（mode/seedColor/amoled）。
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsEntity>((ref) {
      final repository = ref.read(themeSettingsRepositoryProvider);
      return ThemeSettingsNotifier(repository);
    });

/// 主题模式 Provider（仅暴露产品层枚举，便于 UI 直接使用 label）。
final themeModeProvider = Provider<AppThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppThemeMode.fromValue(settings.mode);
});

/// 主题设置状态管理器。
///
/// 负责：
/// 1. 启动时从 Repository 加载用户偏好
/// 2. 提供切换主题模式/主题色/AMOLED 的方法
/// 3. 持久化用户选择到数据库（settings 表）
class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsEntity> {
  ThemeSettingsNotifier(this._repository) : super(ThemeSettingsEntity.defaults()) {
    _load();
  }

  final ThemeSettingsRepository _repository;

  /// 从 Repository 加载主题设置。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：数据库异常时使用默认主题。
  Future<void> _load() async {
    try {
      final settings = await _repository.getThemeSettings();
      state = settings;
    } catch (_) {
      state = ThemeSettingsEntity.defaults();
    }
  }

  /// 保存主题设置（整体覆盖）。
  ///
  /// 参数：
  /// - [settings] 新设置
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时只更新内存状态。
  Future<void> save(ThemeSettingsEntity settings) async {
    state = settings;
    try {
      await _repository.saveThemeSettings(settings);
    } catch (_) {
      // 写入失败时只更新内存状态；下次启动会回退到持久化值或默认值。
    }
  }

  /// 切换主题模式。
  Future<void> setThemeMode(AppThemeMode mode) async {
    await save(state.copyWith(mode: mode.value));
  }

  /// 设置主题种子色（HEX：#RRGGBB）。
  Future<void> setSeedColorHex(String hex) async {
    await save(state.copyWith(seedColorHex: hex));
  }

  /// 设置 AMOLED 深色模式开关。
  Future<void> setAmoled(bool enabled) async {
    await save(state.copyWith(amoled: enabled));
  }
}


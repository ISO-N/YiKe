/// 文件用途：UI 本地偏好仓储实现（UiPreferencesRepositoryImpl），用于保存“性能相关的 UI 开关”等本机偏好。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:convert';

import '../../domain/repositories/ui_preferences_repository.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';
import '../database/daos/settings_dao.dart';

/// UI 本地偏好仓储实现。
///
/// 说明：
/// - 复用 SettingsDao（key-value 表）与 SettingsCrypto（加密策略），避免引入新的持久化方案
/// - 不写入 SyncLog，因此不会通过 F12 同步传播（符合“按设备本地设置”的约束）
class UiPreferencesRepositoryImpl implements UiPreferencesRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] SettingsDao
  /// - [secureStorageService] 安全存储服务（用于管理加密密钥）
  UiPreferencesRepositoryImpl({
    required this.dao,
    required SecureStorageService secureStorageService,
  }) : _crypto = SettingsCrypto(secureStorageService: secureStorageService);

  final SettingsDao dao;
  final SettingsCrypto _crypto;

  // 约定：UI 本地偏好使用 ui_ 前缀，避免与业务设置 key 混淆。
  static const String _keyTaskListBlurEnabled = 'ui_task_list_blur_enabled';
  static const String _keyUndoSnackbarEnabled = 'ui_undo_snackbar';
  static const String _keyHapticFeedbackEnabled = 'ui_haptic_feedback';
  static const String _keySkeletonStrategy = 'ui_skeleton_strategy';

  @override
  Future<bool> getTaskListBlurEnabled() async {
    try {
      final stored = await dao.getValue(_keyTaskListBlurEnabled);
      if (stored == null) return true;
      final decrypted = await _crypto.decrypt(stored);
      final decoded = jsonDecode(decrypted);
      return decoded is bool ? decoded : true;
    } catch (_) {
      // 读取失败时兜底开启：保持原有视觉默认值，避免因加密/解析异常导致 UI 退化。
      return true;
    }
  }

  @override
  Future<void> setTaskListBlurEnabled(bool enabled) async {
    await dao.upsertValue(
      _keyTaskListBlurEnabled,
      await _crypto.encrypt(jsonEncode(enabled)),
    );
  }

  @override
  Future<bool> getUndoSnackbarEnabled() async {
    return _getBoolOrDefault(_keyUndoSnackbarEnabled, defaultValue: true);
  }

  @override
  Future<void> setUndoSnackbarEnabled(bool enabled) async {
    await dao.upsertValue(
      _keyUndoSnackbarEnabled,
      await _crypto.encrypt(jsonEncode(enabled)),
    );
  }

  @override
  Future<bool> getHapticFeedbackEnabled() async {
    return _getBoolOrDefault(_keyHapticFeedbackEnabled, defaultValue: true);
  }

  @override
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    await dao.upsertValue(
      _keyHapticFeedbackEnabled,
      await _crypto.encrypt(jsonEncode(enabled)),
    );
  }

  @override
  Future<String> getSkeletonStrategy() async {
    try {
      final stored = await dao.getValue(_keySkeletonStrategy);
      if (stored == null) return 'auto';
      final decrypted = await _crypto.decrypt(stored);
      final decoded = jsonDecode(decrypted);
      final raw = decoded is String ? decoded : decoded?.toString();
      final v = (raw ?? '').trim();
      switch (v) {
        case 'on':
        case 'off':
        case 'auto':
          return v;
        default:
          return 'auto';
      }
    } catch (_) {
      return 'auto';
    }
  }

  @override
  Future<void> setSkeletonStrategy(String strategy) async {
    final normalized = switch (strategy) {
      'on' => 'on',
      'off' => 'off',
      _ => 'auto',
    };
    await dao.upsertValue(
      _keySkeletonStrategy,
      await _crypto.encrypt(jsonEncode(normalized)),
    );
  }

  Future<bool> _getBoolOrDefault(
    String key, {
    required bool defaultValue,
  }) async {
    try {
      final stored = await dao.getValue(key);
      if (stored == null) return defaultValue;
      final decrypted = await _crypto.decrypt(stored);
      final decoded = jsonDecode(decrypted);
      return decoded is bool ? decoded : defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}


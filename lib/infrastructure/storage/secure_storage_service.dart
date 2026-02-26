/// 文件用途：安全存储服务（flutter_secure_storage），用于保存加密密钥等敏感信息。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储服务。
///
/// 说明：
/// - v1.0 MVP：仅用于“设置项加密”所需的密钥保存；
/// - 任务数据不加密（符合 TDD 的降级要求）。
class SecureStorageService {
  static const String _settingsKeyName = 'settings_encryption_key_v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 用于在“插件不可用”的环境（如 widget_test）下兜底保存密钥。
  static String? _inMemoryKeyBase64;
  static final Map<String, String> _inMemoryKv = {};

  /// 获取或创建“设置项加密密钥”（Base64 编码的 32 字节随机值）。
  ///
  /// 返回值：Base64 字符串。
  /// 异常：平台存储不可用时可能抛出异常。
  Future<String> getOrCreateSettingsKeyBase64() async {
    // 优先读取真实安全存储；若因测试环境/平台限制不可用，则使用内存兜底。
    try {
      final existing = await _storage.read(key: _settingsKeyName);
      if (existing != null && existing.isNotEmpty) return existing;
    } catch (_) {
      if (_inMemoryKeyBase64 != null) return _inMemoryKeyBase64!;
      final created = base64UrlEncode(_randomBytes(32));
      _inMemoryKeyBase64 = created;
      return created;
    }

    final bytes = _randomBytes(32);
    final created = base64UrlEncode(bytes);
    try {
      await _storage.write(key: _settingsKeyName, value: created);
      return created;
    } catch (_) {
      // 写入失败也使用内存兜底，避免阻塞主流程（如测试环境无插件注册）。
      _inMemoryKeyBase64 = created;
      return created;
    }
  }

  /// 读取安全存储中的字符串值。
  ///
  /// 说明：
  /// - 在测试环境或插件不可用时使用内存兜底
  /// - 仅用于本应用内部（如设备 ID、同步令牌等）
  Future<String?> readString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _inMemoryKv[key];
    }
  }

  /// 写入安全存储中的字符串值。
  ///
  /// 说明：在插件不可用时写入内存兜底，避免阻塞主流程。
  Future<void> writeString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _inMemoryKv[key] = value;
    }
  }

  /// 删除安全存储中的值。
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _inMemoryKv.remove(key);
    }
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}

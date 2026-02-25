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

  /// 获取或创建“设置项加密密钥”（Base64 编码的 32 字节随机值）。
  ///
  /// 返回值：Base64 字符串。
  /// 异常：平台存储不可用时可能抛出异常。
  Future<String> getOrCreateSettingsKeyBase64() async {
    final existing = await _storage.read(key: _settingsKeyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final bytes = _randomBytes(32);
    final created = base64UrlEncode(bytes);
    await _storage.write(key: _settingsKeyName, value: created);
    return created;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}


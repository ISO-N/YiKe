/// 文件用途：设置项加密/解密工具（AES-GCM），用于对 app_settings.value 做加密存储。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'secure_storage_service.dart';

/// 设置项加密工具。
///
/// 说明：
/// - 仅用于设置表 value 的加密存储；
/// - 为兼容早期/调试数据，解密时若未命中前缀将直接返回原文。
class SettingsCrypto {
  SettingsCrypto({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  final SecureStorageService _secureStorageService;

  static const String _prefix = 'enc:v1:';
  static final AesGcm _cipher = AesGcm.with256bits();

  /// 加密明文字符串。
  ///
  /// 参数：
  /// - [plainText] 明文
  /// 返回值：带前缀的密文字符串（可存入数据库）。
  /// 异常：加密失败时可能抛出异常。
  Future<String> encrypt(String plainText) async {
    final keyBase64 = await _secureStorageService
        .getOrCreateSettingsKeyBase64();
    final keyBytes = base64Url.decode(keyBase64);
    final secretKey = SecretKey(keyBytes);

    final nonce = _cipher.newNonce();
    final secretBox = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload = jsonEncode({
      'n': base64UrlEncode(secretBox.nonce),
      'c': base64UrlEncode(secretBox.cipherText),
      'm': base64UrlEncode(secretBox.mac.bytes),
    });
    return _prefix + base64UrlEncode(utf8.encode(payload));
  }

  /// 解密密文字符串。
  ///
  /// 参数：
  /// - [cipherText] 密文（带前缀）或明文（兼容）。
  /// 返回值：明文。
  /// 异常：解密失败时可能抛出异常。
  Future<String> decrypt(String cipherText) async {
    if (!cipherText.startsWith(_prefix)) return cipherText;

    final encoded = cipherText.substring(_prefix.length);
    final payloadJson = utf8.decode(base64Url.decode(encoded));
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

    final nonce = base64Url.decode(payload['n'] as String);
    final cipher = base64Url.decode(payload['c'] as String);
    final macBytes = base64Url.decode(payload['m'] as String);

    final keyBase64 = await _secureStorageService
        .getOrCreateSettingsKeyBase64();
    final keyBytes = base64Url.decode(keyBase64);
    final secretKey = SecretKey(keyBytes);

    final clearTextBytes = await _cipher.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(macBytes)),
      secretKey: secretKey,
    );
    return utf8.decode(clearTextBytes);
  }
}

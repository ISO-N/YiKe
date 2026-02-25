// 文件用途：SettingsCrypto / SecureStorageService 单元测试（加解密回环与兼容逻辑）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/infrastructure/storage/secure_storage_service.dart';
import 'package:yike/infrastructure/storage/settings_crypto.dart';

void main() {
  test('SecureStorageService 会生成可解码的 32 字节 Base64Url 密钥，并在测试环境保持稳定', () async {
    final service = SecureStorageService();
    final k1 = await service.getOrCreateSettingsKeyBase64();
    final k2 = await service.getOrCreateSettingsKeyBase64();
    expect(k1, isNotEmpty);
    expect(k2, k1);
    expect(base64Url.decode(k1).length, 32);
  });

  test('SettingsCrypto decrypt 对不带前缀的明文直接回传（兼容旧数据）', () async {
    final crypto = SettingsCrypto(secureStorageService: SecureStorageService());
    expect(await crypto.decrypt('plain-text'), 'plain-text');
  });

  test('SettingsCrypto encrypt/decrypt 可回环还原明文', () async {
    final crypto = SettingsCrypto(secureStorageService: SecureStorageService());
    final cipher = await crypto.encrypt('hello');
    expect(cipher.startsWith('enc:v1:'), true);
    expect(await crypto.decrypt(cipher), 'hello');
  });
}

// 文件用途：SecureStorageService 单元测试（通过 Mock MethodChannel 覆盖 read/write 成功与失败分支）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/infrastructure/storage/secure_storage_service.dart';

void main() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    // 清理 handler，避免影响其他测试。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('当安全存储可读且存在 key 时直接返回存储值', () async {
    const stored = 'stored-key';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'read') return stored;
        if (call.method == 'write') return null;
        return null;
      },
    );

    final service = SecureStorageService();
    final got = await service.getOrCreateSettingsKeyBase64();
    expect(got, stored);
  });

  test('当安全存储可用但无值时，会写入新 key 并返回（write 成功）', () async {
    String? written;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'read') return null;
        if (call.method == 'write') {
          final args = call.arguments as Map<dynamic, dynamic>;
          written = args['value'] as String?;
          return null;
        }
        return null;
      },
    );

    final service = SecureStorageService();
    final got = await service.getOrCreateSettingsKeyBase64();
    expect(got, isNotEmpty);
    expect(written, got);
    expect(base64Url.decode(got).length, 32);
  });

  test('当 write 失败时会回退到内存 key（并在后续读取中复用）', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'read') return null;
        if (call.method == 'write') throw PlatformException(code: 'write_failed');
        return null;
      },
    );

    final service = SecureStorageService();
    final k1 = await service.getOrCreateSettingsKeyBase64();

    // 此时将 read 改为抛异常，以验证“异常环境下会优先复用内存 key”。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'read') throw PlatformException(code: 'read_failed');
        if (call.method == 'write') throw PlatformException(code: 'write_failed');
        return null;
      },
    );

    final k2 = await service.getOrCreateSettingsKeyBase64();
    expect(k2, k1);
  });
}


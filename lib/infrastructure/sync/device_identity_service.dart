/// 文件用途：设备身份服务（F12）——提供稳定的 deviceId / 设备名称 / 设备类型，用于发现、配对与同步协议。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:io';

import 'package:uuid/uuid.dart';

import '../storage/secure_storage_service.dart';

/// 设备身份服务。
///
/// 说明：
/// - deviceId：本应用生成的稳定 ID（写入安全存储），用于跨设备识别
/// - deviceName：用于 UI 展示（尽量取系统名称；不可用时兜底）
/// - deviceType：android/ios/windows/macos/linux/unknown
class DeviceIdentityService {
  DeviceIdentityService({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  final SecureStorageService _secureStorageService;

  static const String _deviceIdKey = 'yike_device_id_v1';

  String? _cachedDeviceId;

  /// 获取或创建 deviceId（UUID v4）。
  Future<String> getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final existing = await _secureStorageService.readString(_deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      _cachedDeviceId = existing.trim();
      return _cachedDeviceId!;
    }

    final created = const Uuid().v4();
    await _secureStorageService.writeString(_deviceIdKey, created);
    _cachedDeviceId = created;
    return created;
  }

  /// 获取设备类型标识。
  String getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 获取设备名称（用于展示，非强一致）。
  Future<String> getDeviceName() async {
    // Windows 优先使用计算机名环境变量；其他平台使用 OS 名称兜底。
    if (Platform.isWindows) {
      final name =
          Platform.environment['COMPUTERNAME'] ??
          Platform.environment['HOSTNAME'];
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return 'YiKe-${getDeviceType()}';
  }
}

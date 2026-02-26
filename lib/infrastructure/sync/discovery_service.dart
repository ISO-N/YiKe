/// 文件用途：设备发现服务（F12）——通过 UDP 广播在同一局域网发现附近设备。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 发现的设备信息（内存态）。
class DiscoveredDevice {
  DiscoveredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.isMaster,
    required this.lastSeenAtMs,
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final bool isMaster;
  final int lastSeenAtMs;

  DiscoveredDevice copyWith({
    String? deviceName,
    String? deviceType,
    String? ipAddress,
    bool? isMaster,
    int? lastSeenAtMs,
  }) {
    return DiscoveredDevice(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      isMaster: isMaster ?? this.isMaster,
      lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
    );
  }
}

/// 设备发现服务（UDP 广播）。
///
/// 协议说明：
/// - 广播端口：19876
/// - 消息体：UTF-8 JSON
///   {
///     "type": "yike_discovery",
///     "device_id": "...",
///     "device_name": "...",
///     "device_type": "android|windows|...",
///     "is_master": true/false,
///     "ts": 1700000000000
///   }
class DiscoveryService {
  static const int discoveryPort = 19876;
  static const String broadcastAddress = '255.255.255.255';
  static const Duration discoveryInterval = Duration(seconds: 5);

  DiscoveryService({required String localDeviceId})
    : _localDeviceId = localDeviceId;

  final String _localDeviceId;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  final Map<String, DiscoveredDevice> _devicesById = {};

  String _deviceName = 'YiKe';
  String _deviceType = 'unknown';
  bool _isMaster = false;

  /// 设备列表流（每次变更都会推送全量列表）。
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  /// 当前发现的设备列表（快照）。
  List<DiscoveredDevice> get devices =>
      _devicesById.values.toList()
        ..sort((a, b) => b.lastSeenAtMs.compareTo(a.lastSeenAtMs));

  /// 配置广播字段（用于角色切换/改名等）。
  void configure({
    required String deviceName,
    required String deviceType,
    required bool isMaster,
  }) {
    _deviceName = deviceName;
    _deviceType = deviceType;
    _isMaster = isMaster;
  }

  /// 启动发现服务。
  Future<void> start() async {
    if (_socket != null) return;
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        // Windows 平台不支持 reusePort（会触发底层断言并输出错误日志）。
        reusePort: !Platform.isWindows,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = _socket!.receive();
        if (datagram == null) return;
        _handleDatagram(datagram);
      });

      _broadcastTimer = Timer.periodic(
        discoveryInterval,
        (_) => broadcastOnce(),
      );
      broadcastOnce();
    } catch (e) {
      debugPrint('DiscoveryService start failed: $e');
      _socket?.close();
      _socket = null;
      _broadcastTimer?.cancel();
      _broadcastTimer = null;
    }
  }

  /// 广播一次自身存在。
  void broadcastOnce() {
    final socket = _socket;
    if (socket == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      'type': 'yike_discovery',
      'device_id': _localDeviceId,
      'device_name': _deviceName,
      'device_type': _deviceType,
      'is_master': _isMaster,
      'ts': nowMs,
    };

    final data = utf8.encode(jsonEncode(payload));
    try {
      socket.send(data, InternetAddress(broadcastAddress), discoveryPort);
    } catch (e) {
      debugPrint('DiscoveryService broadcast failed: $e');
    }
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final body = utf8.decode(datagram.data);
      final decoded = jsonDecode(body);
      if (decoded is! Map) return;
      final json = decoded.cast<String, dynamic>();
      if (json['type'] != 'yike_discovery') return;

      final deviceId = json['device_id'];
      if (deviceId is! String || deviceId.trim().isEmpty) return;
      if (deviceId == _localDeviceId) return;

      final name = (json['device_name'] as String?)?.trim();
      final type = (json['device_type'] as String?)?.trim();
      final isMaster = (json['is_master'] as bool?) ?? false;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final ip = datagram.address.address;
      final next = DiscoveredDevice(
        deviceId: deviceId,
        deviceName: (name == null || name.isEmpty) ? '未知设备' : name,
        deviceType: (type == null || type.isEmpty) ? 'unknown' : type,
        ipAddress: ip,
        isMaster: isMaster,
        lastSeenAtMs: nowMs,
      );

      final existing = _devicesById[deviceId];
      _devicesById[deviceId] = existing == null
          ? next
          : existing.copyWith(
              deviceName: next.deviceName,
              deviceType: next.deviceType,
              ipAddress: next.ipAddress,
              isMaster: next.isMaster,
              lastSeenAtMs: next.lastSeenAtMs,
            );

      _devicesController.add(devices);
    } catch (e) {
      debugPrint('DiscoveryService handle datagram failed: $e');
    }
  }

  /// 停止发现服务。
  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;

    _devicesById.clear();
    if (!_devicesController.isClosed) {
      _devicesController.add(const []);
    }
  }

  /// 释放资源（页面销毁/应用退出）。
  Future<void> dispose() async {
    await stop();
    await _devicesController.close();
  }
}

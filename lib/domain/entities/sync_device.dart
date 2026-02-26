/// 文件用途：领域实体 - 同步设备（SyncDevice），用于表达已配对设备的基础信息（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// 同步设备实体（领域层）。
///
/// 说明：
/// - 该实体用于 UI/业务层展示，不直接依赖 Drift 行类型
/// - deviceId 为本应用生成的稳定标识
class SyncDeviceEntity {
  const SyncDeviceEntity({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.isMaster,
    required this.lastSyncMs,
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final bool isMaster;
  final int? lastSyncMs;
}


/// 文件用途：Drift 表定义 - 局域网同步设备表（sync_devices），用于记录已配对/已连接设备信息（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

/// 同步设备表。
///
/// 说明：
/// - 一条记录对应一台已配对设备（或主机）
/// - authToken 为配对后共享的认证令牌（Bearer Token）
class SyncDevices extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 设备唯一标识（由本应用生成并持久化）。
  TextColumn get deviceId => text().unique()();

  /// 设备名称（用于 UI 展示）。
  TextColumn get deviceName => text()();

  /// 设备类型：android/ios/windows/macos/linux/unknown。
  TextColumn get deviceType => text()();

  /// IP 地址（用于局域网通信，可能会变化）。
  TextColumn get ipAddress => text().nullable()();

  /// 认证令牌（配对成功后生成）。
  TextColumn get authToken => text().nullable()();

  /// 是否为主机设备（用于客户端标记“主机”）。
  BoolColumn get isMaster => boolean().withDefault(const Constant(false))();

  /// 最近一次成功同步的时间戳（毫秒）。
  IntColumn get lastSyncMs => integer().nullable()();

  /// 最近一次成功“发送本地增量”的游标（毫秒）。
  IntColumn get lastOutgoingMs => integer().nullable()();

  /// 最近一次成功“拉取远端增量”的游标（毫秒）。
  IntColumn get lastIncomingMs => integer().nullable()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 文件用途：局域网同步协议模型（F12）——定义发现/配对/同步交换的 JSON 结构与解析逻辑。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';

/// 同步操作类型。
enum SyncOperation { create, update, delete }

/// 同步事件：用于在设备间交换的增量变更单元。
class SyncEvent {
  SyncEvent({
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestampMs,
    this.localVersion = 0,
  });

  /// 源设备 ID（也是该实体的 originDeviceId）。
  final String deviceId;

  /// 实体类型：learning_item/review_task/template/topic/topic_item_relation/settings/theme 等。
  final String entityType;

  /// 源设备实体 ID（originEntityId）。
  final int entityId;

  final SyncOperation operation;

  /// 事件数据（create/update 携带字段；delete 通常为空）。
  final Map<String, dynamic> data;

  /// 事件时间戳（毫秒）。
  final int timestampMs;

  final int localVersion;

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      deviceId: json['device_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperation.update,
      ),
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      timestampMs: json['timestamp_ms'] as int,
      localVersion: (json['local_version'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation': operation.name,
    'data': data,
    'timestamp_ms': timestampMs,
    'local_version': localVersion,
  };

  static List<SyncEvent> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => SyncEvent.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

/// 配对请求（客户端 -> 主机）。
class PairRequest {
  PairRequest({
    required this.clientDeviceId,
    required this.clientDeviceName,
    required this.clientDeviceType,
  });

  final String clientDeviceId;
  final String clientDeviceName;
  final String clientDeviceType;

  factory PairRequest.fromJson(Map<String, dynamic> json) {
    return PairRequest(
      clientDeviceId: json['client_device_id'] as String,
      clientDeviceName: json['client_device_name'] as String,
      clientDeviceType: json['client_device_type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_device_id': clientDeviceId,
    'client_device_name': clientDeviceName,
    'client_device_type': clientDeviceType,
  };
}

/// 配对请求响应（主机 -> 客户端）：返回 sessionId，配对码由主机在 UI 中展示。
class PairRequestResponse {
  PairRequestResponse({required this.sessionId, required this.expiresAtMs});

  final String sessionId;
  final int expiresAtMs;

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'expires_at_ms': expiresAtMs,
  };
}

/// 配对确认（客户端 -> 主机）：提交 sessionId + 用户输入的配对码。
class PairConfirmRequest {
  PairConfirmRequest({required this.sessionId, required this.pairingCode});

  final String sessionId;
  final String pairingCode;

  factory PairConfirmRequest.fromJson(Map<String, dynamic> json) {
    return PairConfirmRequest(
      sessionId: json['session_id'] as String,
      pairingCode: json['pairing_code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'pairing_code': pairingCode,
  };
}

/// 配对确认响应（主机 -> 客户端）：返回认证令牌。
class PairConfirmResponse {
  PairConfirmResponse({required this.authToken});

  final String authToken;

  Map<String, dynamic> toJson() => {'auth_token': authToken};
}

/// 同步交换请求（任意一方 -> 对端）。
class SyncExchangeRequest {
  SyncExchangeRequest({
    required this.fromDeviceId,
    required this.sinceMs,
    required this.events,
  });

  final String fromDeviceId;
  final int sinceMs;
  final List<SyncEvent> events;

  factory SyncExchangeRequest.fromJson(Map<String, dynamic> json) {
    return SyncExchangeRequest(
      fromDeviceId: json['from_device_id'] as String,
      sinceMs: json['since_ms'] as int,
      events: SyncEvent.listFromJson(json['events']),
    );
  }

  Map<String, dynamic> toJson() => {
    'from_device_id': fromDeviceId,
    'since_ms': sinceMs,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

/// 同步交换响应：返回对端在 sinceMs 之后的事件集合，并携带对端当前时间戳（用于推进游标）。
class SyncExchangeResponse {
  SyncExchangeResponse({required this.serverNowMs, required this.events});

  final int serverNowMs;
  final List<SyncEvent> events;

  factory SyncExchangeResponse.fromJson(Map<String, dynamic> json) {
    return SyncExchangeResponse(
      serverNowMs: json['server_now_ms'] as int,
      events: SyncEvent.listFromJson(json['events']),
    );
  }

  Map<String, dynamic> toJson() => {
    'server_now_ms': serverNowMs,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

/// JSON 编解码工具：保持协议层尽量轻量。
class SyncJsonCodec {
  SyncJsonCodec._();

  static Map<String, dynamic> decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) throw const FormatException('JSON 不是对象');
    return decoded.cast<String, dynamic>();
  }

  static String encode(Object value) => jsonEncode(value);
}

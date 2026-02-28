/// 文件用途：局域网同步状态管理（F12）——负责设备发现、配对流程、同步交换与状态展示（Riverpod）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import '../../di/providers.dart';
import '../../infrastructure/desktop/tray_service.dart';
import '../../infrastructure/sync/discovery_service.dart';
import '../../infrastructure/sync/pairing_service.dart';
import '../../infrastructure/sync/sync_models.dart';
import '../../infrastructure/sync/sync_service.dart';
import '../../infrastructure/sync/transfer_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';

/// 同步状态（用于 UI 展示）。
enum SyncState {
  /// 未连接/未配对。
  disconnected,

  /// 连接中（发现/配对/交换）。
  connecting,

  /// 已配对（可同步）。
  connected,

  /// 同步中。
  syncing,

  /// 同步完成（最近一次成功）。
  synced,

  /// 同步失败。
  error,
}

/// 连接设备（UI 友好模型）。
class ConnectedDevice {
  const ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.isMaster,
    required this.lastSyncMs,
    required this.isOnline,
    required this.lastSeenAtMs,
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final bool isMaster;
  final int? lastSyncMs;

  /// 是否在线（基于 UDP 发现/HTTP ping 的综合判定）。
  final bool isOnline;

  /// 最近一次“在线可见”的时间戳（毫秒，来自发现或 ping）。
  final int? lastSeenAtMs;
}

/// 主机侧待处理配对请求。
class PendingPairing {
  const PendingPairing({
    required this.sessionId,
    required this.clientDeviceId,
    required this.clientDeviceName,
    required this.clientDeviceType,
    required this.clientIp,
    required this.pairingCode,
    required this.expiresAtMs,
  });

  final String sessionId;
  final String clientDeviceId;
  final String clientDeviceName;
  final String clientDeviceType;
  final String clientIp;
  final String pairingCode;
  final int expiresAtMs;
}

/// 客户端侧进行中的配对会话（等待用户输入配对码）。
class OutgoingPairing {
  const OutgoingPairing({
    required this.masterDeviceId,
    required this.masterDeviceName,
    required this.masterIp,
    required this.sessionId,
    required this.expiresAtMs,
  });

  final String masterDeviceId;
  final String masterDeviceName;
  final String masterIp;
  final String sessionId;
  final int expiresAtMs;
}

/// 同步 UI 状态。
class SyncUiState {
  const SyncUiState({
    required this.state,
    required this.isMaster,
    required this.autoSyncEnabled,
    required this.includeMockData,
    required this.wifiOnly,
    required this.allowCellular,
    required this.discoveredDevices,
    required this.connectedDevices,
    required this.pendingPairings,
    required this.outgoingPairing,
    this.errorMessage,
  });

  final SyncState state;
  final bool isMaster;
  final bool autoSyncEnabled;

  /// 是否允许同步 Debug 模拟数据（isMockData=true）。
  ///
  /// 说明：
  /// - 仅用于开发联调（例如：用一键生成数据测试跨设备同步）
  /// - release 环境下默认为 false
  final bool includeMockData;
  final bool wifiOnly;
  final bool allowCellular;
  final List<DiscoveredDevice> discoveredDevices;
  final List<ConnectedDevice> connectedDevices;
  final List<PendingPairing> pendingPairings;
  final OutgoingPairing? outgoingPairing;
  final String? errorMessage;

  factory SyncUiState.initial() => const SyncUiState(
    state: SyncState.disconnected,
    isMaster: false,
    autoSyncEnabled: false,
    includeMockData: false,
    wifiOnly: true,
    allowCellular: false,
    discoveredDevices: [],
    connectedDevices: [],
    pendingPairings: [],
    outgoingPairing: null,
  );

  SyncUiState copyWith({
    SyncState? state,
    bool? isMaster,
    bool? autoSyncEnabled,
    bool? includeMockData,
    bool? wifiOnly,
    bool? allowCellular,
    List<DiscoveredDevice>? discoveredDevices,
    List<ConnectedDevice>? connectedDevices,
    List<PendingPairing>? pendingPairings,
    Object? outgoingPairing = _unset,
    Object? errorMessage = _unset,
  }) {
    return SyncUiState(
      state: state ?? this.state,
      isMaster: isMaster ?? this.isMaster,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      includeMockData: includeMockData ?? this.includeMockData,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      allowCellular: allowCellular ?? this.allowCellular,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      pendingPairings: pendingPairings ?? this.pendingPairings,
      // 说明：outgoingPairing/errorMessage 需要支持三态：
      // 1) 不传参：保持原值
      // 2) 显式传 null：清空
      // 3) 传入非空值：更新
      outgoingPairing: identical(outgoingPairing, _unset)
          ? this.outgoingPairing
          : outgoingPairing as OutgoingPairing?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// copyWith 三态参数哨兵：用于区分“未传参”和“显式传 null”。
const Object _unset = Object();

/// 同步控制器 Provider。
final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncUiState>((ref) {
      return SyncController(ref);
    });

/// 同步控制器。
class SyncController extends StateNotifier<SyncUiState> {
  SyncController(this._ref) : super(SyncUiState.initial());

  final Ref _ref;

  DiscoveryService? _discovery;
  StreamSubscription<List<DiscoveredDevice>>? _discoverySub;
  StreamSubscription<List<SyncDevice>>? _devicesSub;
  Timer? _autoSyncTimer;
  Timer? _presenceTimer;
  bool _initialized = false;
  bool _syncing = false;

  final TransferService _transfer = TransferService();
  final Map<String, PendingPairing> _pendingBySessionId = {};

  // 说明：在线状态为“内存态”，不持久化到数据库。
  // - 设备是否在线会频繁变动，不适合写库；
  // - UI 需要的是近实时展示，因此放在控制器内存里即可。
  List<SyncDevice> _pairedRows = const [];
  final Map<String, int> _lastSeenByDeviceId = {};
  final Map<String, int> _lastPingOkByDeviceId = {};

  /// 在线判定 TTL：超过该时间未发现/未 ping 成功即视为离线。
  static const Duration _onlineTtl = Duration(seconds: 12);

  static const String _prefIsMaster = 'sync_is_master';
  static const String _prefAutoSyncEnabled = 'sync_auto_sync_enabled';
  static const String _prefIncludeMockData = 'sync_include_mock_data';
  static const String _prefWifiOnly = 'sync_wifi_only';
  static const String _prefAllowCellular = 'sync_allow_cellular';

  /// 初始化同步模块（建议在 App 启动后调用一次）。
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadPrefs();

    final localDeviceId = _ref.read(deviceIdProvider);
    final identity = _ref.read(deviceIdentityServiceProvider);
    final localName = await identity.getDeviceName();
    final localType = identity.getDeviceType();

    // 启动发现服务。
    _discovery = DiscoveryService(localDeviceId: localDeviceId)
      ..configure(
        deviceName: localName,
        deviceType: localType,
        isMaster: state.isMaster,
      );
    await _discovery!.start();
    _discoverySub = _discovery!.devicesStream.listen((list) {
      state = state.copyWith(discoveredDevices: list);

      // 将“发现到的设备”写入在线缓存，并尽量更新已配对设备的 IP（方便后续 ping/同步）。
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final d in list) {
        _lastSeenByDeviceId[d.deviceId] = d.lastSeenAtMs;
      }
      _refreshOnlineState(nowMs: now, allowDbIpUpdate: true);
    });

    // 监听已配对设备列表（来自数据库）。
    final syncDeviceDao = _ref.read(syncDeviceDaoProvider);
    _devicesSub = syncDeviceDao.watchAll().listen((List<SyncDevice> rows) {
      _pairedRows = rows;

      final connected = rows.isNotEmpty
          ? SyncState.connected
          : SyncState.disconnected;
      state = state.copyWith(
        state: state.state == SyncState.syncing ? state.state : connected,
      );

      _refreshOnlineState(nowMs: DateTime.now().millisecondsSinceEpoch);
      _refreshTrayStatus();
    });

    // 启动本地传输服务端，并注册处理器。
    _transfer.onPairRequest = _handlePairRequest;
    _transfer.onPairConfirm = _handlePairConfirm;
    _transfer.validateToken = _validateToken;
    _transfer.onSyncExchange = _handleSyncExchange;
    await _transfer.startServer();

    _maybeStartAutoSyncTimer();
    _maybeStartPresenceTimer();
  }

  /// 刷新发现（主动广播一次）。
  void refreshDiscovery() {
    _discovery?.broadcastOnce();
  }

  /// 设置当前设备为主机/从机（仅影响发现广播与“设置以主机为准”策略）。
  Future<void> setIsMaster(bool value) async {
    state = state.copyWith(isMaster: value);
    await _writePrefBool(_prefIsMaster, value);
    final identity = _ref.read(deviceIdentityServiceProvider);
    final localName = await identity.getDeviceName();
    final localType = identity.getDeviceType();
    _discovery?.configure(
      deviceName: localName,
      deviceType: localType,
      isMaster: value,
    );
  }

  /// 开启/关闭自动同步。
  Future<void> setAutoSyncEnabled(bool enabled) async {
    state = state.copyWith(autoSyncEnabled: enabled);
    await _writePrefBool(_prefAutoSyncEnabled, enabled);
    _maybeStartAutoSyncTimer();
  }

  /// 是否允许同步 Debug 模拟数据（isMockData=true）。
  Future<void> setIncludeMockData(bool enabled) async {
    state = state.copyWith(includeMockData: enabled);
    await _writePrefBool(_prefIncludeMockData, enabled);
  }

  /// Wi-Fi 下自动同步（若无法识别网络类型，则按“允许”处理）。
  Future<void> setWifiOnly(bool value) async {
    state = state.copyWith(wifiOnly: value);
    await _writePrefBool(_prefWifiOnly, value);
  }

  /// 允许在移动网络下同步（仅在识别为 cellular 时生效）。
  Future<void> setAllowCellular(bool value) async {
    state = state.copyWith(allowCellular: value);
    await _writePrefBool(_prefAllowCellular, value);
  }

  /// 客户端：对某个主机发起配对请求。
  Future<OutgoingPairing> requestPairing(DiscoveredDevice master) async {
    final localDeviceId = _ref.read(deviceIdProvider);
    final identity = _ref.read(deviceIdentityServiceProvider);
    final localName = await identity.getDeviceName();
    final localType = identity.getDeviceType();

    state = state.copyWith(state: SyncState.connecting, errorMessage: null);
    _refreshTrayStatus();

    try {
      final resp = await _transfer.requestPairing(
        ipAddress: master.ipAddress,
        request: PairRequest(
          clientDeviceId: localDeviceId,
          clientDeviceName: localName,
          clientDeviceType: localType,
        ),
      );

      final outgoing = OutgoingPairing(
        masterDeviceId: master.deviceId,
        masterDeviceName: master.deviceName,
        masterIp: master.ipAddress,
        sessionId: resp.sessionId,
        expiresAtMs: resp.expiresAtMs,
      );
      state = state.copyWith(outgoingPairing: outgoing);
      return outgoing;
    } catch (e) {
      // 说明：配对请求失败时，将错误信息落到状态，避免 UI 弹窗链路因未捕获异常而中断。
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      );
      _refreshTrayStatus();
      rethrow;
    }
  }

  /// 客户端：提交配对码完成配对。
  Future<void> confirmPairing({required String pairingCode}) async {
    final outgoing = state.outgoingPairing;
    if (outgoing == null) {
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: '未找到进行中的配对会话',
      );
      _refreshTrayStatus();
      return;
    }

    if (DateTime.now().millisecondsSinceEpoch > outgoing.expiresAtMs) {
      state = state.copyWith(
        state: SyncState.error,
        outgoingPairing: null,
        errorMessage: '配对码已过期，请重新发起配对',
      );
      _refreshTrayStatus();
      return;
    }

    state = state.copyWith(state: SyncState.connecting, errorMessage: null);
    _refreshTrayStatus();

    try {
      final resp = await _transfer.confirmPairing(
        ipAddress: outgoing.masterIp,
        request: PairConfirmRequest(
          sessionId: outgoing.sessionId,
          pairingCode: pairingCode,
        ),
      );

      final syncDeviceDao = _ref.read(syncDeviceDaoProvider);
      await syncDeviceDao.upsert(
        SyncDevicesCompanion.insert(
          deviceId: outgoing.masterDeviceId,
          deviceName: outgoing.masterDeviceName,
          deviceType: 'unknown',
          ipAddress: Value(outgoing.masterIp),
          authToken: Value(resp.authToken),
          isMaster: const Value(true),
          lastSyncMs: const Value.absent(),
          lastOutgoingMs: const Value.absent(),
          lastIncomingMs: const Value.absent(),
        ),
      );

      state = state.copyWith(outgoingPairing: null, state: SyncState.connected);
      _refreshTrayStatus();

      // 首次配对后做一次全量同步。
      await syncNow();
    } catch (e) {
      // 说明：这里不向外抛异常，避免弹窗 onPressed 链路崩溃；错误统一展示在页面“错误”卡片。
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      );
      _refreshTrayStatus();
    }
  }

  /// 手动同步。
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;

    try {
      // 说明：手动同步仅在存在“在线同步目标”时执行，避免离线情况下长时间卡顿等待。
      _ensureHasOnlineSyncTarget();

      final canSync = await _shouldSyncWithNetworkPrefs();
      if (!canSync) {
        throw StateError('当前网络不满足同步设置（Wi-Fi/移动网络限制）');
      }

      state = state.copyWith(state: SyncState.syncing, errorMessage: null);
      _refreshTrayStatus();

      // 让出一帧：避免 UI 状态刚更新就进入大量数据库/网络操作而造成明显卡顿。
      await Future<void>.delayed(Duration.zero);

      final syncService = _buildSyncService();
      await syncService.ensureLocalSnapshotLogs(
        includeMockData: state.includeMockData,
      );

      if (state.isMaster) {
        await _syncAsMaster(syncService);
      } else {
        await _syncAsClient(syncService);
      }

      state = state.copyWith(state: SyncState.synced);
      _refreshTrayStatus();
    } catch (e) {
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      );
      _refreshTrayStatus();
    } finally {
      _syncing = false;
    }
  }

  void _ensureHasOnlineSyncTarget() {
    // - 主机：至少 1 个在线从机
    // - 从机：主机在线
    final hasOnlineTarget = state.isMaster
        ? state.connectedDevices.any((d) => !d.isMaster && d.isOnline)
        : state.connectedDevices.any((d) => d.isMaster && d.isOnline);
    if (!hasOnlineTarget) {
      throw StateError(
        state.connectedDevices.isEmpty
            ? '暂无已配对设备'
            : (state.isMaster ? '暂无在线从机' : '主机离线'),
      );
    }
  }

  Future<void> disconnectDevice(String deviceId) async {
    final syncDeviceDao = _ref.read(syncDeviceDaoProvider);
    await syncDeviceDao.deleteByDeviceId(deviceId);
  }

  Future<PairRequestResponse> _handlePairRequest(
    PairRequest request,
    InternetAddress peer,
  ) async {
    // 主机收到配对请求：生成 sessionId + 配对码，并在 UI 中展示。
    final sessionId = const Uuid().v4();
    final pairingCode = PairingService.generatePairingCode();
    final expiresAtMs = DateTime.now()
        .add(PairingService.pairingCodeValidity)
        .millisecondsSinceEpoch;

    final pending = PendingPairing(
      sessionId: sessionId,
      clientDeviceId: request.clientDeviceId,
      clientDeviceName: request.clientDeviceName,
      clientDeviceType: request.clientDeviceType,
      clientIp: peer.address,
      pairingCode: pairingCode,
      expiresAtMs: expiresAtMs,
    );
    _pendingBySessionId[sessionId] = pending;

    state = state.copyWith(
      pendingPairings: _pendingBySessionId.values.toList(),
    );
    return PairRequestResponse(sessionId: sessionId, expiresAtMs: expiresAtMs);
  }

  Future<PairConfirmResponse> _handlePairConfirm(
    PairConfirmRequest request,
    InternetAddress peer,
  ) async {
    final pending = _pendingBySessionId[request.sessionId];
    if (pending == null) {
      throw StateError('配对会话不存在或已失效');
    }

    if (DateTime.now().millisecondsSinceEpoch > pending.expiresAtMs) {
      _pendingBySessionId.remove(request.sessionId);
      state = state.copyWith(
        pendingPairings: _pendingBySessionId.values.toList(),
      );
      throw StateError('配对码已过期');
    }

    if (!PairingService.verifyPairingCode(
      request.pairingCode,
      pending.pairingCode,
    )) {
      throw StateError('配对码错误');
    }

    final token = const Uuid().v4();
    final syncDeviceDao = _ref.read(syncDeviceDaoProvider);
    await syncDeviceDao.upsert(
      SyncDevicesCompanion.insert(
        deviceId: pending.clientDeviceId,
        deviceName: pending.clientDeviceName,
        deviceType: pending.clientDeviceType,
        ipAddress: Value(peer.address),
        authToken: Value(token),
        isMaster: const Value(false),
        lastSyncMs: const Value.absent(),
        lastOutgoingMs: const Value.absent(),
        lastIncomingMs: const Value.absent(),
      ),
    );

    _pendingBySessionId.remove(request.sessionId);
    state = state.copyWith(
      pendingPairings: _pendingBySessionId.values.toList(),
    );
    return PairConfirmResponse(authToken: token);
  }

  Future<bool> _validateToken(String fromDeviceId, String token) async {
    final dao = _ref.read(syncDeviceDaoProvider);
    final row = await dao.getByDeviceId(fromDeviceId);
    return row != null && row.authToken == token;
  }

  Future<SyncExchangeResponse> _handleSyncExchange(
    SyncExchangeRequest request,
    InternetAddress peer,
  ) async {
    // 更新对端 IP（便于主机侧“手动同步”发起连接）。
    await _ref
        .read(syncDeviceDaoProvider)
        .updateIp(request.fromDeviceId, peer.address);

    final syncService = _buildSyncService();
    return syncService.handleExchangeRequest(
      request,
      isMaster: state.isMaster,
      includeMockData: state.includeMockData,
    );
  }

  Future<void> _syncAsClient(SyncService syncService) async {
    final list = await _ref.read(syncDeviceDaoProvider).getAll();
    final master = list.where((d) => d.isMaster).toList();
    if (master.isEmpty) {
      throw StateError('未找到主机设备，请先完成配对');
    }

    final target = master.first;
    if (target.ipAddress == null || target.authToken == null) {
      throw StateError('主机信息不完整（缺少 IP 或令牌）');
    }

    await _exchangeWithDevice(
      syncService: syncService,
      deviceId: target.deviceId,
      ipAddress: target.ipAddress!,
      token: target.authToken!,
      isMaster: false,
    );
  }

  Future<void> _syncAsMaster(SyncService syncService) async {
    final list = await _ref.read(syncDeviceDaoProvider).getAll();
    final clients = list.where((d) => !d.isMaster).toList();
    for (final c in clients) {
      if (c.ipAddress == null || c.authToken == null) continue;
      await _exchangeWithDevice(
        syncService: syncService,
        deviceId: c.deviceId,
        ipAddress: c.ipAddress!,
        token: c.authToken!,
        isMaster: true,
      );
    }
  }

  Future<void> _exchangeWithDevice({
    required SyncService syncService,
    required String deviceId,
    required String ipAddress,
    required String token,
    required bool isMaster,
  }) async {
    final dao = _ref.read(syncDeviceDaoProvider);
    final row = await dao.getByDeviceId(deviceId);
    final lastOutgoing = row?.lastOutgoingMs ?? 0;
    final lastIncoming = row?.lastIncomingMs ?? 0;

    // 关键逻辑：
    // - 从机 -> 主机：仅发送“本机 origin”的事件
    // - 主机 -> 从机：发送主机库中“聚合后的事件”（排除该从机自身的事件，避免回声）
    final localEvents = isMaster
        ? await syncService.buildOutgoingEventsSince(
            lastOutgoing,
            excludeDeviceId: deviceId,
          )
        : await syncService.buildLocalEventsSince(lastOutgoing);
    final req = SyncExchangeRequest(
      fromDeviceId: _ref.read(deviceIdProvider),
      sinceMs: lastIncoming,
      events: localEvents,
    );

    final resp = await _transfer.exchange(
      ipAddress: ipAddress,
      token: token,
      request: req,
    );

    await syncService.persistIncomingEvents(resp.events);
    await syncService.applyIncomingEvents(resp.events, isMaster: isMaster);

    final nextOutgoing = _maxTimestamp(lastOutgoing, localEvents);
    final nextIncoming = _maxTimestamp(lastIncoming, resp.events);
    final now = DateTime.now().millisecondsSinceEpoch;

    await dao.updateLastOutgoingMs(deviceId, nextOutgoing);
    await dao.updateLastIncomingMs(deviceId, nextIncoming);
    await dao.updateLastSyncMs(deviceId, now);
  }

  int _maxTimestamp(int base, List<SyncEvent> events) {
    var max = base;
    for (final e in events) {
      if (e.timestampMs > max) max = e.timestampMs;
    }
    return max;
  }

  SyncService _buildSyncService() {
    return SyncService(
      db: _ref.read(appDatabaseProvider),
      syncLogDao: _ref.read(syncLogDaoProvider),
      syncEntityMappingDao: _ref.read(syncEntityMappingDaoProvider),
      settingsDao: _ref.read(settingsDaoProvider),
      secureStorageService: _ref.read(secureStorageServiceProvider),
      localDeviceId: _ref.read(deviceIdProvider),
    );
  }

  void _maybeStartAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    if (!state.autoSyncEnabled) return;

    // 自动同步节奏：5 秒一次，避免频繁占用网络与电量。
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => syncNow(),
    );
  }

  void _maybeStartPresenceTimer() {
    _presenceTimer?.cancel();
    _presenceTimer = null;

    // 在线探测节奏：5 秒一次，与发现广播周期保持一致。
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _probePairedDevicesOnline(nowMs: now);
      _refreshOnlineState(nowMs: now);
    });
  }

  Future<void> _probePairedDevicesOnline({required int nowMs}) async {
    // 说明：仅对“已配对且有 IP”的设备做 ping，避免无谓的网络请求。
    final targets = _pairedRows
        .where((d) => d.ipAddress != null && d.ipAddress!.trim().isNotEmpty)
        .toList();
    if (targets.isEmpty) return;

    // 并发 ping（每个请求都有超时），避免串行阻塞 UI 线程。
    await Future.wait(
      targets.map((d) async {
        final ip = d.ipAddress!.trim();
        final ok = await _transfer.ping(ipAddress: ip);
        if (ok) {
          _lastPingOkByDeviceId[d.deviceId] = nowMs;
        }
      }),
    );
  }

  void _refreshOnlineState({required int nowMs, bool allowDbIpUpdate = false}) {
    // 在线判定：最近被发现(UDP) 或 最近 ping 成功(HTTP) 之一满足 TTL 即在线。
    bool isOnlineByDeviceId(String deviceId) {
      final lastSeen = _lastSeenByDeviceId[deviceId];
      final lastPing = _lastPingOkByDeviceId[deviceId];
      final seenOnline =
          lastSeen != null && (nowMs - lastSeen) <= _onlineTtl.inMilliseconds;
      final pingOnline =
          lastPing != null && (nowMs - lastPing) <= _onlineTtl.inMilliseconds;
      return seenOnline || pingOnline;
    }

    int? lastOnlineAtMs(String deviceId) {
      final lastSeen = _lastSeenByDeviceId[deviceId];
      final lastPing = _lastPingOkByDeviceId[deviceId];
      if (lastSeen == null) return lastPing;
      if (lastPing == null) return lastSeen;
      return lastSeen > lastPing ? lastSeen : lastPing;
    }

    // 尝试用发现到的 IP 覆盖数据库 IP（仅对已配对设备，且允许写库时执行）。
    if (allowDbIpUpdate) {
      final dao = _ref.read(syncDeviceDaoProvider);
      for (final d in state.discoveredDevices) {
        final paired = _pairedRows
            .where((p) => p.deviceId == d.deviceId)
            .toList();
        if (paired.isEmpty) continue;
        final existingIp = paired.first.ipAddress?.trim();
        if (existingIp == d.ipAddress.trim()) continue;
        // 异步写库：不等待返回，避免阻塞发现刷新。
        // ignore: discarded_futures
        dao.updateIp(d.deviceId, d.ipAddress.trim());
      }
    }

    final devices = _pairedRows
        .map(
          (d) => ConnectedDevice(
            deviceId: d.deviceId,
            deviceName: d.deviceName,
            deviceType: d.deviceType,
            ipAddress: d.ipAddress,
            isMaster: d.isMaster,
            lastSyncMs: d.lastSyncMs,
            isOnline: isOnlineByDeviceId(d.deviceId),
            lastSeenAtMs: lastOnlineAtMs(d.deviceId),
          ),
        )
        .toList();

    state = state.copyWith(connectedDevices: devices);
  }

  Future<void> _loadPrefs() async {
    final crypto = SettingsCrypto(
      secureStorageService: _ref.read(secureStorageServiceProvider),
    );
    final settingsDao = _ref.read(settingsDaoProvider);

    Future<bool> readBool(String key, bool fallback) async {
      final stored = await settingsDao.getValue(key);
      if (stored == null) return fallback;
      try {
        final decrypted = await crypto.decrypt(stored);
        final decoded = decrypted.trim().toLowerCase();
        if (decoded == 'true') return true;
        if (decoded == 'false') return false;
        // 兼容：可能被包了一层 JSON。
        if (decoded.startsWith('{') || decoded.startsWith('[')) {
          return fallback;
        }
        return fallback;
      } catch (_) {
        return fallback;
      }
    }

    final isMaster = await readBool(_prefIsMaster, false);
    final autoSync = await readBool(_prefAutoSyncEnabled, false);
    final includeMock = await readBool(_prefIncludeMockData, kDebugMode);
    final wifiOnly = await readBool(_prefWifiOnly, true);
    final allowCellular = await readBool(_prefAllowCellular, false);
    state = state.copyWith(
      isMaster: isMaster,
      autoSyncEnabled: autoSync,
      includeMockData: includeMock,
      wifiOnly: wifiOnly,
      allowCellular: allowCellular,
    );
  }

  Future<void> _writePrefBool(String key, bool value) async {
    final crypto = SettingsCrypto(
      secureStorageService: _ref.read(secureStorageServiceProvider),
    );
    final encrypted = await crypto.encrypt(value.toString());
    await _ref.read(settingsDaoProvider).upsertValue(key, encrypted);
  }

  /// 根据“Wi-Fi/移动网络”偏好判断是否允许同步。
  ///
  /// 说明：
  /// - 本项目不引入额外插件的前提下，仅做基于网卡名称的启发式识别
  /// - 若识别失败（unknown），默认允许，避免误伤桌面端有线网络等场景
  Future<bool> _shouldSyncWithNetworkPrefs() async {
    if (!state.autoSyncEnabled && state.state != SyncState.syncing) {
      // 手动同步也应尊重设置，但这里不做额外限制。
    }

    final net = await _detectNetworkType();
    if (!state.wifiOnly) {
      if (net == _NetworkType.cellular && !state.allowCellular) return false;
      return true;
    }

    // Wi-Fi only。
    if (net == _NetworkType.wifi) return true;
    if (net == _NetworkType.unknown) return true;
    return false;
  }

  Future<_NetworkType> _detectNetworkType() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      if (ifaces.isEmpty) return _NetworkType.unknown;

      final names = ifaces.map((e) => e.name.toLowerCase()).toList();
      bool matchAny(bool Function(String) pred) => names.any(pred);

      if (matchAny((n) => n.contains('wlan') || n.contains('wifi'))) {
        return _NetworkType.wifi;
      }
      // Android 常见移动网络接口名。
      if (matchAny(
        (n) =>
            n.contains('rmnet') || n.contains('ccmni') || n.contains('pdp_ip'),
      )) {
        return _NetworkType.cellular;
      }
      // iOS/macOS 常见 Wi-Fi/以太网接口名（en0/en1）。
      if (matchAny((n) => n == 'en0' || n == 'en1')) {
        return _NetworkType.wifi;
      }
      // 以太网接口名。
      if (matchAny((n) => n.contains('eth'))) {
        return _NetworkType.ethernet;
      }

      return _NetworkType.unknown;
    } catch (_) {
      return _NetworkType.unknown;
    }
  }

  void _refreshTrayStatus() {
    // 仅桌面端启用托盘时生效；移动端调用也不会产生副作用。
    final tray = TrayService.instance;
    final hasAnyOnline = state.connectedDevices.any((e) => e.isOnline);
    switch (state.state) {
      case SyncState.syncing:
        tray.updateStatus(TrayStatus.syncing);
        return;
      case SyncState.connected:
      case SyncState.synced:
        tray.updateStatus(
          hasAnyOnline ? TrayStatus.normal : TrayStatus.offline,
        );
        return;
      case SyncState.disconnected:
      case SyncState.connecting:
      case SyncState.error:
        tray.updateStatus(TrayStatus.offline);
        return;
    }
  }

  @override
  Future<void> dispose() async {
    _autoSyncTimer?.cancel();
    _presenceTimer?.cancel();
    await _discoverySub?.cancel();
    await _devicesSub?.cancel();
    await _discovery?.dispose();
    await _transfer.dispose();
    super.dispose();
  }
}

enum _NetworkType { wifi, ethernet, cellular, unknown }

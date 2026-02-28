/// 文件用途：局域网同步状态管理（F12）——负责设备发现、配对流程、同步交换与状态展示（Riverpod）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
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

  /// 已连接（可同步）。
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
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final bool isMaster;
  final int? lastSyncMs;
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
    bool? wifiOnly,
    bool? allowCellular,
    List<DiscoveredDevice>? discoveredDevices,
    List<ConnectedDevice>? connectedDevices,
    List<PendingPairing>? pendingPairings,
    OutgoingPairing? outgoingPairing,
    String? errorMessage,
  }) {
    return SyncUiState(
      state: state ?? this.state,
      isMaster: isMaster ?? this.isMaster,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      allowCellular: allowCellular ?? this.allowCellular,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      pendingPairings: pendingPairings ?? this.pendingPairings,
      outgoingPairing: outgoingPairing,
      errorMessage: errorMessage,
    );
  }
}

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
  bool _initialized = false;
  bool _syncing = false;

  final TransferService _transfer = TransferService();
  final Map<String, PendingPairing> _pendingBySessionId = {};

  static const String _prefIsMaster = 'sync_is_master';
  static const String _prefAutoSyncEnabled = 'sync_auto_sync_enabled';
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
    });

    // 监听已配对设备列表（来自数据库）。
    final syncDeviceDao = _ref.read(syncDeviceDaoProvider);
    _devicesSub = syncDeviceDao.watchAll().listen((List<SyncDevice> rows) {
      final devices = rows
          .map(
            (d) => ConnectedDevice(
              deviceId: d.deviceId,
              deviceName: d.deviceName,
              deviceType: d.deviceType,
              ipAddress: d.ipAddress,
              isMaster: d.isMaster,
              lastSyncMs: d.lastSyncMs,
            ),
          )
          .toList();

      final connected = devices.isNotEmpty
          ? SyncState.connected
          : SyncState.disconnected;
      state = state.copyWith(
        state: state.state == SyncState.syncing ? state.state : connected,
        connectedDevices: devices,
      );
      _refreshTrayStatus();
    });

    // 启动本地传输服务端，并注册处理器。
    _transfer.onPairRequest = _handlePairRequest;
    _transfer.onPairConfirm = _handlePairConfirm;
    _transfer.validateToken = _validateToken;
    _transfer.onSyncExchange = _handleSyncExchange;
    await _transfer.startServer();

    _maybeStartAutoSyncTimer();
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
      final canSync = await _shouldSyncWithNetworkPrefs();
      if (!canSync) {
        throw StateError('当前网络不满足同步设置（Wi-Fi/移动网络限制）');
      }

      state = state.copyWith(state: SyncState.syncing, errorMessage: null);
      _refreshTrayStatus();

      final syncService = _buildSyncService();
      await syncService.ensureLocalSnapshotLogs();

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
    return syncService.handleExchangeRequest(request, isMaster: state.isMaster);
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
    final wifiOnly = await readBool(_prefWifiOnly, true);
    final allowCellular = await readBool(_prefAllowCellular, false);
    state = state.copyWith(
      isMaster: isMaster,
      autoSyncEnabled: autoSync,
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
    switch (state.state) {
      case SyncState.syncing:
        tray.updateStatus(TrayStatus.syncing);
        return;
      case SyncState.connected:
      case SyncState.synced:
        tray.updateStatus(TrayStatus.normal);
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
    await _discoverySub?.cancel();
    await _devicesSub?.cancel();
    await _discovery?.dispose();
    await _transfer.dispose();
    super.dispose();
  }
}

enum _NetworkType { wifi, ethernet, cellular, unknown }

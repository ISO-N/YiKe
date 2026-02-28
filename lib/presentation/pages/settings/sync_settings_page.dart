/// 文件用途：同步设置页（F12）——设备发现、配对、连接设备管理、手动/自动同步入口。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/glass_card.dart';

/// 同步设置页。
class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
        actions: [
          IconButton(
            tooltip: '刷新发现',
            onPressed: controller.refreshDiscovery,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              _StatusCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('将本机设为主机'),
                      subtitle: const Text('主机负责接收配对与汇总同步（设置以主机为准）'),
                      value: state.isMaster,
                      onChanged: (v) => controller.setIsMaster(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('开启自动同步'),
                      subtitle: const Text('连接后每 5 秒自动同步一次'),
                      value: state.autoSyncEnabled,
                      onChanged: (v) => controller.setAutoSyncEnabled(v),
                    ),
                    const Divider(height: 1),
                    if (kDebugMode) ...[
                      SwitchListTile(
                        title: const Text('同步模拟数据（仅调试）'),
                        subtitle: const Text(
                          '开启后会将 isMockData=true 的模拟数据也纳入同步',
                        ),
                        value: state.includeMockData,
                        onChanged: (v) => controller.setIncludeMockData(v),
                      ),
                      const Divider(height: 1),
                    ],
                    SwitchListTile(
                      title: const Text('仅 Wi-Fi 下同步'),
                      subtitle: const Text('开启后将尝试仅在 Wi-Fi/有线网络下进行同步'),
                      value: state.wifiOnly,
                      onChanged: state.autoSyncEnabled
                          ? (v) => controller.setWifiOnly(v)
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('允许移动网络同步'),
                      subtitle: const Text('关闭时在移动网络下会跳过同步（若能识别网络类型）'),
                      value: state.allowCellular,
                      onChanged: (!state.autoSyncEnabled || state.wifiOnly)
                          ? null
                          : (v) => controller.setAllowCellular(v),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('手动同步'),
                      subtitle: const Text('立即执行一次双向同步'),
                      trailing: FilledButton(
                        onPressed: () => controller.syncNow(),
                        child: const Text('立即同步'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.isMaster) ...[
                _PendingPairingsCard(state: state),
                const SizedBox(height: AppSpacing.lg),
              ],
              _DiscoveredDevicesCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              _ConnectedDevicesCard(state: state),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      '错误：${state.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final SyncUiState state;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (state.state) {
      SyncState.disconnected => (Icons.cloud_off, '未连接', Colors.grey),
      SyncState.connecting => (Icons.sync, '连接中', Colors.blue),
      SyncState.connected => (Icons.cloud_done, '已连接', Colors.green),
      SyncState.syncing => (Icons.sync, '同步中', Colors.blue),
      SyncState.synced => (Icons.check_circle, '同步完成', Colors.green),
      SyncState.error => (Icons.error_outline, '同步失败', Colors.red),
    };

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('同步状态', style: AppTypography.h2(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(label, style: AppTypography.bodySecondary(context)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Text(label, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPairingsCard extends StatelessWidget {
  const _PendingPairingsCard({required this.state});

  final SyncUiState state;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('待配对请求', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '在客户端输入下列配对码完成配对（有效期 5 分钟）。',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.pendingPairings.isEmpty)
              Text('暂无请求', style: AppTypography.bodySecondary(context))
            else
              ...state.pendingPairings.map((p) {
                final expiresIn =
                    p.expiresAtMs - DateTime.now().millisecondsSinceEpoch;
                final minutesLeft = (expiresIn / 60000).floor().clamp(0, 99);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices),
                    title: Text(p.clientDeviceName),
                    subtitle: Text('IP：${p.clientIp} · 剩余约 $minutesLeft 分钟'),
                    trailing: SelectableText(
                      p.pairingCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _DiscoveredDevicesCard extends ConsumerWidget {
  const _DiscoveredDevicesCard({required this.state});

  final SyncUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(syncControllerProvider.notifier);

    final devices = state.discoveredDevices;
    final candidates = state.isMaster
        ? devices.where((d) => !d.isMaster).toList()
        : devices.where((d) => d.isMaster).toList();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('附近设备', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.isMaster ? '从机可在此发现主机，并发起配对。' : '选择一台主机发起配对。',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.md),
            if (candidates.isEmpty)
              Text('未发现附近设备', style: AppTypography.bodySecondary(context))
            else
              ...candidates.map((d) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(d.isMaster ? Icons.hub : Icons.phone_android),
                  title: Text(d.deviceName),
                  subtitle: Text('${d.deviceType} · ${d.ipAddress}'),
                  trailing: state.isMaster
                      ? const SizedBox.shrink()
                      : FilledButton(
                          onPressed: () async {
                            try {
                              await controller.requestPairing(d);
                              if (!context.mounted) return;
                              await _showPairingCodeDialog(
                                context: context,
                                ref: ref,
                              );
                            } catch (_) {
                              // 说明：失败原因会写入 SyncUiState.errorMessage 并在页面下方展示。
                              // 这里不再弹出“输入配对码”对话框，避免无效操作。
                            }
                          },
                          child: const Text('配对'),
                        ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _showPairingCodeDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final controller = ref.read(syncControllerProvider.notifier);
    final textController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入主机配对码'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '请输入 6 位配对码'),
            maxLength: 6,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final code = textController.text.trim();
                await controller.confirmPairing(pairingCode: code);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}

class _ConnectedDevicesCard extends ConsumerWidget {
  const _ConnectedDevicesCard({required this.state});

  final SyncUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(syncControllerProvider.notifier);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已连接的设备', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.connectedDevices.isEmpty ? '暂无已连接设备' : '可断开设备或查看最近同步时间。',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.connectedDevices.isEmpty)
              Text('未连接', style: AppTypography.bodySecondary(context))
            else
              ...state.connectedDevices.map((d) {
                final lastSyncText = d.lastSyncMs == null
                    ? '从未同步'
                    : DateTime.fromMillisecondsSinceEpoch(
                        d.lastSyncMs!,
                      ).toLocal().toString().split('.').first;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(d.isMaster ? Icons.hub : Icons.devices),
                  title: Text(d.deviceName),
                  subtitle: Text(
                    '${d.deviceType} · ${d.ipAddress ?? '-'} · $lastSyncText',
                  ),
                  trailing: TextButton(
                    onPressed: () => controller.disconnectDevice(d.deviceId),
                    child: const Text('断开'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// 文件用途：设置页（通知开关、提醒时间、免打扰时段等）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../infrastructure/notification/notification_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass_card.dart';

class SettingsPage extends ConsumerWidget {
  /// 设置页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    Future<void> save(AppSettingsEntity next) async {
      await notifier.save(next);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    }

    Future<void> pickTime({
      required String title,
      required String current,
      required ValueChanged<String> onPicked,
    }) async {
      final initial = TimeUtils.parseHHmm(current);
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        helpText: title,
      );
      if (picked == null) return;
      onPicked(TimeUtils.formatHHmm(picked));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('通知与提醒', style: AppTypography.h2),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'v1.0 MVP：使用后台定时检查方式提醒，时间精度约 ±30 分钟。',
                        style: AppTypography.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('开启通知提醒'),
                      subtitle: const Text('关闭后将不再发送复习提醒'),
                      value: state.settings.notificationsEnabled,
                      onChanged: state.isLoading
                          ? null
                          : (v) => save(state.settings.copyWith(notificationsEnabled: v)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('每日提醒时间'),
                      subtitle: Text(state.settings.reminderTime),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: state.isLoading
                          ? null
                          : () => pickTime(
                                title: '选择每日提醒时间',
                                current: state.settings.reminderTime,
                                onPicked: (v) => save(state.settings.copyWith(reminderTime: v)),
                              ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('免打扰开始时间'),
                      subtitle: Text(state.settings.doNotDisturbStart),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: state.isLoading
                          ? null
                          : () => pickTime(
                                title: '选择免打扰开始时间',
                                current: state.settings.doNotDisturbStart,
                                onPicked: (v) => save(state.settings.copyWith(doNotDisturbStart: v)),
                              ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('免打扰结束时间'),
                      subtitle: Text(state.settings.doNotDisturbEnd),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: state.isLoading
                          ? null
                          : () => pickTime(
                                title: '选择免打扰结束时间',
                                current: state.settings.doNotDisturbEnd,
                                onPicked: (v) => save(state.settings.copyWith(doNotDisturbEnd: v)),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('通知权限', style: AppTypography.h2),
                      const SizedBox(height: AppSpacing.sm),
                      FutureBuilder<bool?>(
                        future: NotificationService.instance.areNotificationsEnabled(),
                        builder: (context, snapshot) {
                          final enabled = snapshot.data;
                          final text = enabled == null
                              ? '当前平台不支持读取权限状态'
                              : (enabled ? '已开启' : '未开启（可能收不到提醒）');
                          return Row(
                            children: [
                              Expanded(child: Text(text, style: AppTypography.bodySecondary)),
                              OutlinedButton(
                                onPressed: () async {
                                  final ok = await NotificationService.instance.requestPermission();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(ok == true ? '已请求通知权限' : '未获取到通知权限')),
                                    );
                                  }
                                },
                                child: const Text('请求权限'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('错误：${state.errorMessage}', style: const TextStyle(color: Colors.red)),
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

/// 文件用途：同步模块启动器（F12）——在 App 启动后自动初始化同步控制器（避免在 build 中做副作用）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';

/// 同步启动器：包裹在应用根部即可。
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap> {
  @override
  void initState() {
    super.initState();
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) return;

    // 关键逻辑：在首帧后初始化，避免阻塞 MaterialApp/router 的构建。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

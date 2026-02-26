/// 文件用途：系统托盘服务（F11）——支持最小化到托盘、右键菜单与同步状态图标更新。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 托盘状态：用于切换托盘图标与菜单提示。
enum TrayStatus { normal, syncing, offline }

/// 托盘服务单例。
///
/// 说明：
/// - tray_manager 的 setIcon 通常需要文件路径；为避免不同平台对 assets 解析差异，本服务会把
///   assets 图标写入临时目录后再设置。
class TrayService with TrayListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  bool _initialized = false;
  TrayStatus _status = TrayStatus.normal;

  /// 初始化托盘。
  ///
  /// 返回值：无。
  /// 异常：初始化失败时抛出（由调用方兜底处理）。
  Future<void> init() async {
    if (_initialized) return;
    if (!_isDesktopSupported()) return;

    trayManager.addListener(this);

    await trayManager.setIcon(await _iconPathForStatus(TrayStatus.normal));
    await trayManager.setToolTip('忆刻');
    await _refreshMenu();

    _initialized = true;
  }

  /// 最小化到系统托盘。
  Future<void> minimizeToTray() async {
    if (!_initialized) return;

    // 关键逻辑：隐藏窗口并从任务栏移除，让用户从托盘恢复。
    await windowManager.setSkipTaskbar(true);
    await windowManager.hide();
  }

  /// 显示主窗口。
  Future<void> showMainWindow() async {
    if (!_initialized) return;

    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
  }

  /// 更新托盘状态（图标 + 菜单）。
  Future<void> updateStatus(TrayStatus status) async {
    if (!_initialized) return;
    if (_status == status) return;

    _status = status;
    await trayManager.setIcon(await _iconPathForStatus(status));
    await _refreshMenu();
  }

  Future<void> _refreshMenu() async {
    final statusLabel = switch (_status) {
      TrayStatus.normal => '状态：正常',
      TrayStatus.syncing => '状态：同步中',
      TrayStatus.offline => '状态：离线',
    };

    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'status', label: statusLabel, disabled: true),
          MenuItem.separator(),
          MenuItem(key: 'show', label: '显示主窗口'),
          MenuItem(key: 'minimize', label: '最小化到托盘'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    showMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        showMainWindow();
        return;
      case 'minimize':
        minimizeToTray();
        return;
      case 'exit':
        windowManager.close();
        return;
      default:
        return;
    }
  }

  /// 释放托盘资源。
  Future<void> dispose() async {
    if (!_initialized) return;
    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }

  bool _isDesktopSupported() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<String> _iconPathForStatus(TrayStatus status) async {
    final assetPath = switch (status) {
      TrayStatus.normal => 'assets/icons/app_icon.png',
      TrayStatus.syncing => 'assets/icons/app_icon_syncing.png',
      TrayStatus.offline => 'assets/icons/app_icon_offline.png',
    };
    return _materializeAssetToFile(assetPath);
  }

  Future<String> _materializeAssetToFile(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final iconDir = Directory('${dir.path}${Platform.pathSeparator}yike_icons');
    if (!await iconDir.exists()) {
      await iconDir.create(recursive: true);
    }

    final filename = assetPath.split('/').last;
    final file = File('${iconDir.path}${Platform.pathSeparator}$filename');
    if (!await file.exists() || await file.length() != bytes.lengthInBytes) {
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }
}

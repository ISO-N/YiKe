// 文件用途：iOS 应用入口与插件注册（含 Workmanager 后台任务插件注册回调）。
// 作者：Codex
// 创建日期：2026-02-25

import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // v1.0 MVP：为 Workmanager 后台任务注册插件，确保后台 isolate 可访问插件。
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // 隐式引擎注册（Flutter 3.22+ 模板）。
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

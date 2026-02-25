/**
 * 文件用途：应用主入口 Activity（FlutterActivity），负责承载 Flutter 引擎并处理启动 Intent。
 * 作者：Codex
 * 创建日期：2026-02-25
 */
package com.example.yike

import android.content.Intent
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity

/**
 * 主 Activity。
 *
 * 说明：
 * - 支持从桌面小组件通过 home_widget 的 LAUNCH Action 唤起；
 * - 兼容旧版 Widget 可能写入的非标准 URI（如 yike://home?...），避免 GoRouter 深链接解析失败导致无法启动。
 */
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // 关键逻辑：在 Flutter 引擎读取 initialRoute 之前，先规范化启动 Intent 的 data。
        intent = normalizeHomeWidgetLaunchIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        // 关键逻辑：singleTop 场景下会走 onNewIntent，必须同步 setIntent，否则 Flutter 侧拿到的仍是旧 Intent。
        val normalized = normalizeHomeWidgetLaunchIntent(intent)
        super.onNewIntent(normalized)
        setIntent(normalized)
    }

    /**
     * 规范化 home_widget 唤起时携带的 URI。
     *
     * 背景：旧实现使用 `yike://home?homeWidget`（host=home，path 为空），GoRouter 只匹配 path，
     * 会导致无法命中 `/home` 路由，从而出现“点击小组件/应用图标无法启动”的现象（Launcher 复用已有任务时尤为明显）。
     *
     * 处理：将 `yike://home?...` 统一改写为 `yike:///home?...`（path=/home）。
     */
    private fun normalizeHomeWidgetLaunchIntent(source: Intent): Intent {
        if (source.action != HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION) return source

        val data = source.data ?: return source
        val scheme = data.scheme ?: return source

        // 仅修复旧格式：scheme=yike 且 host=home 且 path 为空（或为 "/"）。
        val isLegacyHomeUri = scheme == "yike" &&
            data.host == "home" &&
            (data.path.isNullOrEmpty() || data.path == "/")

        if (!isLegacyHomeUri) return source

        val encodedQuery = data.encodedQuery
        val normalized = if (encodedQuery.isNullOrBlank()) {
            "$scheme:///home"
        } else {
            "$scheme:///home?$encodedQuery"
        }

        source.data = android.net.Uri.parse(normalized)
        return source
    }
}

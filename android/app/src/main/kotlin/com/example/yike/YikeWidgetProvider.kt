/**
 * 文件用途：忆刻桌面小组件 Provider（Android XML RemoteViews）。
 * 作者：Codex
 * 创建日期：2026-02-25
 */
package com.example.yike

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * 忆刻桌面小组件 Provider。
 *
 * 说明：
 * - v1.0 MVP：仅展示数据，不支持在小组件内直接勾选交互；
 * - 点击小组件打开 App 首页；
 * - 数据来源：Flutter 侧通过 home_widget 写入 SharedPreferences 的 `widget_data`。
 */
class YikeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val isLarge = isLargeWidget(appWidgetManager, widgetId)
            val layoutId = if (isLarge) R.layout.yike_widget_large else R.layout.yike_widget_small

            val views = RemoteViews(context.packageName, layoutId).apply {
                // 点击小组件打开 App（v1.0 MVP 不做组件内交互）。
                //
                // 重要说明：不要使用 `HomeWidgetLaunchIntent.getActivity`。
                // 在部分 Android 14+（例如 Oplus/Realme 系统）上，该方法在创建 PendingIntent 时会携带
                // `pendingIntentBackgroundActivityStartMode` 选项，从而触发系统的 IllegalArgumentException，
                // 导致 `AppWidgetProvider` 崩溃并连带使应用“无法启动”。
                //
                // 因此此处改为手动创建 PendingIntent，同时保留 home_widget 约定的 LAUNCH Action，便于未来在 Flutter 侧识别。
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                    // 注意：使用 `/home`（相对 URI）确保 Flutter deep link 解析得到的 location 以 `/` 开头，便于 GoRouter 匹配。
                    data = Uri.parse("/home?homeWidget=1")
                }

                var flags = PendingIntent.FLAG_UPDATE_CURRENT
                if (Build.VERSION.SDK_INT >= 23) {
                    flags = flags or PendingIntent.FLAG_IMMUTABLE
                }

                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                bindWidgetData(widgetData, isLarge, this)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindWidgetData(
        widgetData: SharedPreferences,
        isLarge: Boolean,
        views: RemoteViews
    ) {
        val raw = widgetData.getString("widget_data", null)
        val obj = try {
            if (raw.isNullOrBlank()) null else JSONObject(raw)
        } catch (_: Exception) {
            null
        }

        val totalCount = obj?.optInt("totalCount", 0) ?: 0
        val completedCount = obj?.optInt("completedCount", 0) ?: 0
        val pendingCount = obj?.optInt("pendingCount", totalCount) ?: totalCount
        val tasks = obj?.optJSONArray("tasks") ?: JSONArray()

        if (isLarge) {
            views.setTextViewText(R.id.widget_progress, "$completedCount/$totalCount 已完成")
            if (tasks.length() == 0) {
                views.setTextViewText(R.id.widget_task_1, "⬜ 暂无任务")
                views.setTextViewText(R.id.widget_task_2, "")
                views.setTextViewText(R.id.widget_task_3, "")
            } else {
                // 最多展示 3 条任务
                bindTaskLine(views, R.id.widget_task_1, tasks, 0)
                bindTaskLine(views, R.id.widget_task_2, tasks, 1)
                bindTaskLine(views, R.id.widget_task_3, tasks, 2)
            }
        } else {
            // 小组件 2×2：仅展示“待复习数量”。
            views.setTextViewText(R.id.widget_count, pendingCount.toString())
        }
    }

    private fun bindTaskLine(views: RemoteViews, viewId: Int, tasks: JSONArray, index: Int) {
        if (index >= tasks.length()) {
            views.setTextViewText(viewId, "")
            return
        }
        val taskObj = tasks.optJSONObject(index) ?: JSONObject()
        val title = taskObj.optString("title", "")
        val status = taskObj.optString("status", "pending")

        val prefix = when (status) {
            "done" -> "☑ "
            "skipped" -> "⏭ "
            else -> "⬜ "
        }
        views.setTextViewText(viewId, prefix + title)
    }

    /**
     * 简单判断当前 Widget 是否为大尺寸（近似用于区分 2×2 与 4×2）。
     *
     * 说明：不同 Launcher 的 dp 值存在差异，此处使用阈值做近似判断即可满足 MVP。
     */
    private fun isLargeWidget(appWidgetManager: AppWidgetManager, widgetId: Int): Boolean {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        // 经验阈值：宽或高较大时认为是 4×2（或更大）。
        return minWidth >= 180 || minHeight >= 110
    }
}

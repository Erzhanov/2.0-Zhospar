package com.zhospar.zhospar_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

class ZhosparWidgetMediumProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateMediumWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateMediumWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val streak = prefs.getLong("flutter.zhospar_widget_streak", 0L)
            val total = prefs.getLong("flutter.zhospar_widget_total", 0L)
            val done = prefs.getLong("flutter.zhospar_widget_done", 0L)
            val pct = prefs.getLong("flutter.zhospar_widget_pct", 0L).toInt()
            val date = prefs.getString("flutter.zhospar_widget_date", "Бүгінгі жоспар") ?: "Бүгінгі жоспар"
            val tasksJson = prefs.getString("flutter.zhospar_widget_tasks_json", "[]") ?: "[]"

            val views = RemoteViews(context.packageName, R.layout.zhospar_widget_medium)
            views.setTextViewText(R.id.widget_date_text, date)
            views.setTextViewText(R.id.widget_streak_badge, "🔥 $streak күн")
            views.setTextViewText(R.id.widget_progress_text, "$done/$total ($pct%)")
            views.setProgressBar(R.id.widget_progress_bar, 100, pct, false)

            try {
                val array = JSONArray(tasksJson)
                if (array.length() > 0) {
                    val t1 = array.getJSONObject(0)
                    val time1 = t1.optString("time", "")
                    val prefix1 = if (time1.isNotEmpty()) "$time1 • " else "• "
                    val check1 = if (t1.optBoolean("isDone", false)) "✓ " else ""
                    views.setTextViewText(R.id.widget_task_1, "$check1$prefix1${t1.optString("title", "")}")
                } else {
                    views.setTextViewText(R.id.widget_task_1, "• Тапсырмалар жоқ")
                }

                if (array.length() > 1) {
                    val t2 = array.getJSONObject(1)
                    val time2 = t2.optString("time", "")
                    val prefix2 = if (time2.isNotEmpty()) "$time2 • " else "• "
                    val check2 = if (t2.optBoolean("isDone", false)) "✓ " else ""
                    views.setTextViewText(R.id.widget_task_2, "$check2$prefix2${t2.optString("title", "")}")
                } else {
                    views.setTextViewText(R.id.widget_task_2, "")
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.widget_task_1, "• Барлық жоспар орындалды")
                views.setTextViewText(R.id.widget_task_2, "")
            }

            // Click to open main app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class ZhosparWidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val streak = prefs.getLong("flutter.zhospar_widget_streak", 0L)
            val total = prefs.getLong("flutter.zhospar_widget_total", 0L)
            val done = prefs.getLong("flutter.zhospar_widget_done", 0L)
            val pct = prefs.getLong("flutter.zhospar_widget_pct", 0L).toInt()

            val views = RemoteViews(context.packageName, R.layout.zhospar_widget_small)
            views.setTextViewText(R.id.widget_small_pct, "$pct%")
            views.setTextViewText(R.id.widget_small_count, "$done/$total орындалды")
            views.setTextViewText(R.id.widget_small_streak, "🔥 $streak күн")

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_small_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

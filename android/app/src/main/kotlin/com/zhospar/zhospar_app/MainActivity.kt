package com.zhospar.zhospar_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.zhospar.zhospar_app/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                
                // Update medium widgets
                val mediumComponent = ComponentName(context, ZhosparWidgetMediumProvider::class.java)
                val mediumIds = appWidgetManager.getAppWidgetIds(mediumComponent)
                for (id in mediumIds) {
                    ZhosparWidgetMediumProvider.updateMediumWidget(context, appWidgetManager, id)
                }

                // Update small widgets
                val smallComponent = ComponentName(context, ZhosparWidgetSmallProvider::class.java)
                val smallIds = appWidgetManager.getAppWidgetIds(smallComponent)
                val smallProvider = ZhosparWidgetSmallProvider()
                smallProvider.onUpdate(context, appWidgetManager, smallIds)

                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}

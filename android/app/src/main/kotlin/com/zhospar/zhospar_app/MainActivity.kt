package com.zhospar.zhospar_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private val WIDGET_CHANNEL = "com.zhospar.zhospar_app/widget"
    private val SENSOR_CHANNEL = "com.zhospar.zhospar_app/sensors"
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var sensorSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorSink = events
                    accelerometer?.let {
                        sensorManager?.registerListener(this@MainActivity, it, SensorManager.SENSOR_DELAY_UI)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    sensorSink = null
                    sensorManager?.unregisterListener(this@MainActivity)
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val mediumComponent = ComponentName(context, ZhosparWidgetMediumProvider::class.java)
                    val mediumIds = appWidgetManager.getAppWidgetIds(mediumComponent)
                    for (id in mediumIds) {
                        ZhosparWidgetMediumProvider.updateMediumWidget(context, appWidgetManager, id)
                    }

                    val smallComponent = ComponentName(context, ZhosparWidgetSmallProvider::class.java)
                    val smallIds = appWidgetManager.getAppWidgetIds(smallComponent)
                    val smallProvider = ZhosparWidgetSmallProvider()
                    smallProvider.onUpdate(context, appWidgetManager, smallIds)

                    result.success(true)
                }
                "pinWidget" -> {
                    val size = call.argument<String>("size") ?: "medium"
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val component = if (size == "small") {
                        ComponentName(context, ZhosparWidgetSmallProvider::class.java)
                    } else {
                        ComponentName(context, ZhosparWidgetMediumProvider::class.java)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && appWidgetManager.isRequestPinAppWidgetSupported) {
                        appWidgetManager.requestPinAppWidget(component, null, null)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0].toDouble()
            val y = event.values[1].toDouble()
            val z = event.values[2].toDouble()
            sensorSink?.success(listOf(x, y, z))
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }
}
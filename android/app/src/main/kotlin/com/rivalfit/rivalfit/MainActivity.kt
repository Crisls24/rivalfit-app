package com.rivalfit.rivalfit

import android.Manifest
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private var dailySteps: DailyStepsChannel? = null
    private val sensors by lazy { getSystemService(SensorManager::class.java) }
    private var stepStream: EventChannel? = null
    private var stepControl: MethodChannel? = null
    private var stepListener: SensorEventListener? = null
    private var permissionRequest: MethodChannel.Result? = null
    private var trainingTones: ToneGenerator? = null
    private var trainingChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        dailySteps = DailyStepsChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        configureSteps(flutterEngine)
        trainingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rivalfit/training_audio")
        trainingChannel?.setMethodCallHandler { call, result ->
            val cue = when (call.method) {
                "start" -> ToneGenerator.TONE_PROP_ACK to 180
                "ready" -> ToneGenerator.TONE_PROP_BEEP2 to 110
                "rep" -> ToneGenerator.TONE_PROP_BEEP to 90
                "lost" -> ToneGenerator.TONE_PROP_NACK to 240
                else -> null
            }
            if (cue == null) {
                result.notImplemented()
            } else {
                try {
                    val tones = trainingTones ?: ToneGenerator(AudioManager.STREAM_MUSIC, 65)
                        .also { trainingTones = it }
                    tones.startTone(cue.first, cue.second)
                    result.success(null)
                } catch (_: RuntimeException) {
                    result.error("audio_unavailable", "Training audio unavailable", null)
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rivalfit/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    try {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("settings_unavailable", "No se pudieron abrir los ajustes", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun configureSteps(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger
        stepControl = MethodChannel(messenger, "rivalfit/cardio")
        stepControl?.setMethodCallHandler { call, result ->
            val permission = Manifest.permission.ACTIVITY_RECOGNITION
            when {
                call.method != "prepare" && call.method != "prepareDaily" ->
                    result.notImplemented()
                sensors?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR) == null &&
                    (call.method != "prepareDaily" ||
                        sensors?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) == null) ->
                    result.success("unavailable")
                Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
                    checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED ->
                    result.success("ready")
                permissionRequest != null -> result.success("denied")
                else -> {
                    val daily = call.method == "prepareDaily"
                    val preferences = getPreferences(MODE_PRIVATE)
                    if (daily && preferences.getBoolean("daily_steps_permission_asked", false)) {
                        result.success("denied")
                    } else {
                        permissionRequest = result
                        if (daily) {
                            preferences.edit().putBoolean("daily_steps_permission_asked", true).apply()
                        }
                        requestPermissions(arrayOf(permission), STEP_PERMISSION)
                    }
                }
            }
        }
        stepStream = EventChannel(messenger, "rivalfit/cardio_steps")
        stepStream?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                stopSteps()
                val manager = sensors
                val sensor = manager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
                val daily = arguments == false
                val acceleration = if (daily) manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) else null
                val rotation = if (daily) manager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE) else null
                val primary = sensor ?: acceleration
                if (manager == null || primary == null) {
                    events.error("unavailable", null, null)
                    return
                }
                val filter = if (daily) DailyStepFilter(sensor != null) else null
                val listener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent) {
                        if (stepListener !== this) return
                        val count = when (event.sensor.type) {
                            Sensor.TYPE_STEP_DETECTOR -> filter?.candidate(event.timestamp) ?: 1
                            Sensor.TYPE_ACCELEROMETER -> filter?.acceleration(
                                event.timestamp, event.values[0], event.values[1], event.values[2],
                            ) ?: 0
                            Sensor.TYPE_GYROSCOPE -> {
                                filter?.rotation(
                                    event.timestamp, event.values[0], event.values[1], event.values[2],
                                )
                                0
                            }
                            else -> 0
                        }
                        if (count > 0) events.success(count)
                    }
                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
                }
                try {
                    val rate = if (primary == acceleration) {
                        SensorManager.SENSOR_DELAY_GAME
                    } else {
                        SensorManager.SENSOR_DELAY_NORMAL
                    }
                    if (manager.registerListener(listener, primary, rate)) {
                        stepListener = listener
                        if (acceleration != null && acceleration != primary) {
                            manager.registerListener(listener, acceleration, SensorManager.SENSOR_DELAY_GAME)
                        }
                        if (rotation != null) {
                            manager.registerListener(listener, rotation, SensorManager.SENSOR_DELAY_GAME)
                        }
                        if (!daily) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                    } else {
                        events.error("unavailable", null, null)
                    }
                } catch (_: SecurityException) {
                    stopSteps()
                    events.error("denied", null, null)
                }
            }

            override fun onCancel(arguments: Any?) = stopSteps()
        })
    }

    private fun stopSteps() {
        val listener = stepListener ?: return
        sensors?.unregisterListener(listener)
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        stepListener = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        dailySteps?.onPermissionsResult(requestCode, grantResults)
        if (requestCode != STEP_PERMISSION) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        permissionRequest?.success(if (granted) "ready" else "denied")
        permissionRequest = null
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        dailySteps?.close()
        dailySteps = null
        stopSteps()
        permissionRequest?.success("denied")
        permissionRequest = null
        stepControl?.setMethodCallHandler(null)
        stepStream?.setStreamHandler(null)
        stepControl = null
        stepStream = null
        trainingChannel?.setMethodCallHandler(null)
        trainingChannel = null
        trainingTones?.release()
        trainingTones = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        const val STEP_PERMISSION = 823
    }
}

package com.rivalfit.rivalfit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private var trainingTones: ToneGenerator? = null
    private var trainingChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        trainingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rivalfit/training_audio")
        trainingChannel?.setMethodCallHandler { call, result ->
            val cue = when (call.method) {
                "start" -> ToneGenerator.TONE_PROP_ACK to 180
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

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        trainingChannel?.setMethodCallHandler(null)
        trainingChannel = null
        trainingTones?.release()
        trainingTones = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

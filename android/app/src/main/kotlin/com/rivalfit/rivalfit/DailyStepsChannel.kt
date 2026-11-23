package com.rivalfit.rivalfit

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.health.connect.AggregateRecordsRequest
import android.health.connect.AggregateRecordsResponse
import android.health.connect.HealthConnectException
import android.health.connect.HealthConnectManager
import android.health.connect.TimeInstantRangeFilter
import android.health.connect.datatypes.StepsRecord
import android.os.Build
import android.os.OutcomeReceiver
import android.os.ext.SdkExtensions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.time.ZonedDateTime

internal class DailyStepsChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "rivalfit/daily_steps")
    private var permissionResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method !in setOf("today", "requestAccess", "openSettings")) {
                result.notImplemented()
            } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                result.success(mapOf("status" to "unsupported"))
            } else {
                try {
                    val manager = activity.getSystemService(HealthConnectManager::class.java)
                    when {
                        manager == null -> result.success(mapOf("status" to "unsupported"))
                        call.method == "openSettings" -> openSettings(result)
                        call.method == "requestAccess" && !hasAccess() -> requestAccess(result)
                        !hasAccess() -> result.success(mapOf("status" to "permission"))
                        else -> readToday(manager, result)
                    }
                } catch (_: SecurityException) {
                    result.success(mapOf("status" to "permission"))
                } catch (_: RuntimeException) {
                    result.success(mapOf("status" to "error"))
                }
            }
        }
    }

    private fun hasAccess() =
        activity.checkSelfPermission(READ_STEPS) == PackageManager.PERMISSION_GRANTED

    private fun requestAccess(result: MethodChannel.Result) {
        if (permissionResult != null) {
            result.success(mapOf("status" to "permission"))
            return
        }
        permissionResult = result
        try {
            activity.requestPermissions(arrayOf(READ_STEPS), REQUEST_STEPS)
        } catch (error: RuntimeException) {
            permissionResult = null
            throw error
        }
    }

    private fun openSettings(result: MethodChannel.Result) {
        try {
            activity.startActivity(Intent(HealthConnectManager.ACTION_MANAGE_HEALTH_PERMISSIONS)
                .putExtra(Intent.EXTRA_PACKAGE_NAME, activity.packageName))
            result.success(mapOf("status" to "settingsOpened"))
        } catch (_: ActivityNotFoundException) {
            result.success(mapOf("status" to "error"))
        }
    }

    fun onPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_STEPS) return
        val result = permissionResult ?: return
        permissionResult = null
        val status = if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            "granted"
        } else {
            "denied"
        }
        result.success(mapOf("status" to status))
    }

    @android.annotation.TargetApi(34)
    private fun readToday(manager: HealthConnectManager, result: MethodChannel.Result) {
        val now = ZonedDateTime.now()
        val midnight = now.toLocalDate().atStartOfDay(now.zone).toInstant()
        val end = now.toInstant()
        val range = TimeInstantRangeFilter.Builder()
            .setStartTime(midnight)
            .setEndTime(if (end.isAfter(midnight)) end else end.plusMillis(1))
            .build()
        val request = AggregateRecordsRequest.Builder<Long>(range)
            .addAggregationType(StepsRecord.STEPS_COUNT_TOTAL)
            .build()
        val nativeCounting = SdkExtensions.getExtensionVersion(
            Build.VERSION_CODES.UPSIDE_DOWN_CAKE,
        ) >= 20 && activity.packageManager.hasSystemFeature(
            PackageManager.FEATURE_SENSOR_STEP_COUNTER,
        )
        manager.aggregate(
            request,
            activity.mainExecutor,
            object : OutcomeReceiver<AggregateRecordsResponse<Long>, HealthConnectException> {
                override fun onResult(response: AggregateRecordsResponse<Long>) {
                    val count = response.get(StepsRecord.STEPS_COUNT_TOTAL)
                    result.success(mapOf(
                        "status" to if (count == null && !nativeCounting) "needsSource" else "ready",
                        "steps" to (count ?: 0L),
                    ))
                }

                override fun onError(error: HealthConnectException) {
                    result.success(mapOf("status" to if (hasAccess()) "error" else "permission"))
                }
            },
        )
    }

    fun close() {
        channel.setMethodCallHandler(null)
        permissionResult?.success(mapOf("status" to "denied"))
        permissionResult = null
    }

    private companion object {
        const val READ_STEPS = "android.permission.health.READ_STEPS"
        const val REQUEST_STEPS = 824
    }
}

package com.rivalfit.rivalfit

import kotlin.math.abs
import kotlin.math.sqrt

/** Verifies a short walking cadence before publishing the first steps. */
internal class DailyStepFilter(private val hardwareDetector: Boolean) {
    private var gravity: FloatArray? = null
    private var lastCandidate = 0L
    private var lastInterval = 0L
    private var consecutive = 0
    private var unstableUntil = 0L
    private var aboveThreshold = false

    fun rotation(time: Long, x: Float, y: Float, z: Float) {
        if (x * x + y * y + z * z > 16f) interrupt(time)
    }

    fun acceleration(time: Long, x: Float, y: Float, z: Float): Int {
        val acceleration = sqrt(x * x + y * y + z * z)
        val g = gravity ?: floatArrayOf(x, y, z).also {
            gravity = it
            return 0
        }
        val length = sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2])
        val vertical = if (length > 1f) {
            (x * g[0] + y * g[1] + z * g[2]) / length - length
        } else {
            0f
        }
        g[0] += (x - g[0]) * .06f
        g[1] += (y - g[1]) * .06f
        g[2] += (z - g[2]) * .06f
        if (acceleration > 24f) {
            interrupt(time)
            return 0
        }
        if (hardwareDetector) return 0
        if (vertical < .45f) aboveThreshold = false
        if (vertical < 1.6f || aboveThreshold) return 0
        aboveThreshold = true
        return candidate(time)
    }

    fun candidate(time: Long): Int {
        if (time <= unstableUntil || time <= lastCandidate) return 0
        val interval = time - lastCandidate
        // Ignore closely spaced impacts and restart after a pause or sudden change.
        if (lastCandidate != 0L && interval < 260_000_000L) {
            interrupt(time)
            return 0
        }
        if (lastCandidate == 0L || interval > 1_100_000_000L ||
            (lastInterval != 0L && abs(interval - lastInterval) > 250_000_000L)
        ) {
            consecutive = 1
            lastInterval = 0L
        } else {
            consecutive++
            lastInterval = interval
        }
        lastCandidate = time
        return when {
            consecutive == 3 -> 3
            consecutive > 3 -> 1
            else -> 0
        }
    }

    private fun interrupt(time: Long) {
        unstableUntil = time + 900_000_000L
        lastCandidate = 0L
        lastInterval = 0L
        consecutive = 0
    }
}

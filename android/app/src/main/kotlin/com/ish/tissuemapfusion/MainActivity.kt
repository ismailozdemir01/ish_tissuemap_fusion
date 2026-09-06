package com.ish.tissuemapfusion

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val channelName = "ish_tissuemap_fusion/rf"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readWifiRf" -> result.success(readWifiRf())
                    else -> result.notImplemented()
                }
            }
    }

    private fun readWifiRf(): Map<String, Any?> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return mapOf("accessLevel" to "unavailable", "quality" to 0.0, "reason" to "WIFI_SERVICE_UNAVAILABLE")

        @Suppress("DEPRECATION")
        val info = wifiManager.connectionInfo
        if (info == null || info.networkId == -1) {
            return mapOf("accessLevel" to "unavailable", "quality" to 0.0, "reason" to "WIFI_NOT_CONNECTED")
        }

        val frequency = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) info.frequency else 0
        val rssi = info.rssi.toDouble()
        val quality = if (rssi <= -100.0) 0.0 else if (rssi >= -50.0) 1.0 else (rssi + 100.0) / 50.0
        val tx = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) info.txLinkSpeedMbps.toDouble() else null
        val rx = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) info.rxLinkSpeedMbps.toDouble() else null
        val width = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) info.channelWidth.toDouble() else null

        return mapOf(
            "timestampMicros" to System.currentTimeMillis() * 1000L,
            "accessLevel" to "rssi",
            "frequencyMHz" to frequency.toDouble(),
            "channel" to frequencyToChannel(frequency),
            "rssiDbm" to rssi,
            "txLinkMbps" to tx,
            "rxLinkMbps" to rx,
            "channelWidthMHz" to width,
            "quality" to min(1.0, max(0.0, quality)),
            "reason" to "ANDROID_WIFIINFO_RSSI"
        )
    }

    private fun frequencyToChannel(frequency: Int): Int? {
        if (frequency in 2412..2472 && (frequency - 2407) % 5 == 0) return (frequency - 2407) / 5
        if (frequency in 5000..5900 && (frequency - 5000) % 5 == 0) return (frequency - 5000) / 5
        return null
    }
}

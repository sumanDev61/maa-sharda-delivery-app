package com.example.rider_app

import android.os.Build
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "maa_sharda/device_utils")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimNumbers" -> result.success(getSimNumbers())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getSimNumbers(): List<String> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return emptyList()
        val manager =
            getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager ?: return emptyList()
        val infos = try {
            manager.activeSubscriptionInfoList ?: emptyList()
        } catch (_: SecurityException) {
            return emptyList()
        }
        return infos
            .mapNotNull { sanitizePhone(it.number) }
            .distinct()
    }

    private fun sanitizePhone(number: String?): String? {
        if (number.isNullOrBlank()) return null
        val cleaned = buildString {
            number.forEachIndexed { index, char ->
                if (char.isDigit()) append(char)
                if (char == '+' && index == 0) append(char)
            }
        }.trim()
        val digitsCount = cleaned.count { it.isDigit() }
        return if (digitsCount >= 10) cleaned else null
    }
}

package com.ar.mobilelearning

import android.os.Build
import com.ar.mobilelearning.ar_engine.ArEngineView
import com.ar.mobilelearning.ar_engine.ArEngineViewFactory
import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.frontend/ar_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getArCoreAvailability" -> result.success(getArCoreAvailability())
                "requestArCoreInstall" -> result.success(requestArCoreInstall())
                "getDeviceInfo" -> result.success(getDeviceInfo())
                else -> result.notImplemented()
            }
        }

        flutterEngine.platformViewsController.registry.registerViewFactory(
            ArEngineView.VIEW_TYPE,
            ArEngineViewFactory(
                messenger = flutterEngine.dartExecutor.binaryMessenger,
                lifecycleOwner = this,
            )
        )
    }

    private fun getArCoreAvailability(): String {
        return try {
            val availability = ArCoreApk.getInstance().checkAvailability(this)
            when (availability) {
                ArCoreApk.Availability.SUPPORTED_INSTALLED -> "supported"
                ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
                ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED -> "not_installed"
                ArCoreApk.Availability.UNSUPPORTED_DEVICE_NOT_CAPABLE -> "unsupported"
                else -> "unknown"
            }
        } catch (_: Exception) {
            "unknown"
        }
    }

    private fun requestArCoreInstall(): Boolean {
        return try {
            val availability = ArCoreApk.getInstance().checkAvailability(this)
            val needsInstall = availability == ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED ||
                    availability == ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD
            if (needsInstall) {
                ArCoreApk.getInstance().requestInstall(this, true)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }
}

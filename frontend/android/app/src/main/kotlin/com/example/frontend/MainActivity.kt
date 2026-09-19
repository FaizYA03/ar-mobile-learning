package com.example.frontend

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.frontend/ar_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isARCoreSupported") {
                val supported = checkARCoreSupport()
                result.success(supported)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkARCoreSupport(): Boolean {
        return try {
            val pm = packageManager
            val hasARFeature = pm.hasSystemFeature("android.hardware.camera.ar")
            val arCorePackage = pm.getPackageInfo("com.google.ar.core", 0)
            val hasRealARCore = arCorePackage.versionCode > 0
            hasARFeature && hasRealARCore
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Throwable) {
            false
        }
    }
}

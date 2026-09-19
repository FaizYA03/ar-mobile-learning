package com.example.frontend.ar_engine

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.google.ar.core.ArCoreApk
import io.github.sceneview.ar.ARPermissionHandler

/**
 * Opsi 3 (renderer native) — mengadaptasi permintaan izin ARCore agar tidak ganda
 * dengan pemintaan izin dari Flutter (permission_handler). Izin kamera & instalasi
 * ARCore sudah ditangani di sisi Dart sebelum view AR dibuat; handler ini hanya
 * mengonfirmasi status ke SceneView.
 */
class FlutterArPermissionHandler(private val activity: Activity) : ARPermissionHandler {

    override fun hasCameraPermission(): Boolean =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED

    override fun requestCameraPermission(onResult: (granted: Boolean) -> Unit) {
        // Flutter (permission_handler) sudah meminta izin kamera lebih dulu.
        onResult(hasCameraPermission())
    }

    override fun shouldShowPermissionRationale(): Boolean = false

    override fun openAppSettings() {
        try {
            activity.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${activity.packageName}")
                )
            )
        } catch (_: Exception) {
            // ignore
        }
    }

    override fun checkARCoreAvailability(): ArCoreApk.Availability =
        ArCoreApk.getInstance().checkAvailability(activity)

    override fun requestARCoreInstall(userRequestedInstall: Boolean): Boolean =
        ArCoreApk.getInstance().requestInstall(activity, userRequestedInstall) ==
            ArCoreApk.InstallStatus.INSTALL_REQUESTED
}
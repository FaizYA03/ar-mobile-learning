package com.ar.mobilelearning.ar_engine

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import androidx.lifecycle.LifecycleOwner

class ArEngineViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleOwner: LifecycleOwner
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val activity = (context as? Activity)
            ?: (lifecycleOwner as? Activity)
            ?: throw IllegalStateException("ArEngine requires an Activity context")
        return ArEngineView(
            context = context,
            messenger = messenger,
            lifecycleOwner = lifecycleOwner,
            permissionHandler = FlutterArPermissionHandler(activity)
        )
    }
}

package com.ar.mobilelearning.ar_engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.platform.PlatformView
import io.github.sceneview.SurfaceType
import io.github.sceneview.ar.ARPermissionHandler
import io.github.sceneview.ar.ARSceneView
import io.github.sceneview.ar.arcore.getUpdatedAugmentedImages
import io.github.sceneview.math.Position
import io.github.sceneview.rememberModelInstance

/**
 * Opsi 3 — rendering AR native (SceneView 4.x: Filament + ARCore + AugmentedImage + glTF/GLB).
 *
 * Pipeline:
 *   Dart menyiapkan izin kamera + ARCore, lalu mengirim daftar marker (nama = marker_id backend,
 *   path bitmap cache, lebar fisik) + peta marker→GLB lokal via [ArEngineView.configure].
 *   View ini:
 *    1. membuat ARCore [Session] + [AugmentedImageDatabase] dari image marker (nama = marker_id);
 *    2. mendeteksi gambar via callback frame ARCore;
 *    3. membuat [AugmentedImageNode] per marker yang terdeteksi dan melekatkan [ModelNode] GLB;
 *    4. mengirim event ke Flutter (session siap/gagal, marker terdeteksi/hilang, state pelacakan kamera).
 */
class ArEngineView(
    private val context: Context,
    messenger: BinaryMessenger,
    val lifecycleOwner: LifecycleOwner,
    val permissionHandler: ARPermissionHandler
) : PlatformView, EventChannel.StreamHandler {

    companion object {
        const val VIEW_TYPE = "com.example.frontend/ar_engine"
        const val METHOD_CHANNEL = "com.example.frontend/ar_engine"
        const val EVENT_CHANNEL = "com.example.frontend/ar_engine_events"
        private const val TAG = "ArEngine"
    }

    data class MarkerSpec(
        val name: String,
        val imagePath: String,
        val widthMeters: Float?
    )

    data class EngineConfig(
        val markers: List<MarkerSpec>,
        val modelsByMarker: Map<String, String>,
        val scaleToUnits: Float
    )

    /** State komposisi yang dibaca/ditulis dari sisi Compose (harus di main thread). */
    var config by mutableStateOf<EngineConfig?>(null)
    val detectedImages = mutableStateListOf<AugmentedImage>()

    private val mainHandler = Handler(Looper.getMainLooper())
    private val eventSink = java.util.concurrent.atomic.AtomicReference<EventChannel.EventSink?>(null)

    private val methodChannel = MethodChannel(
        messenger,
        METHOD_CHANNEL,
        StandardMethodCodec.INSTANCE
    )

    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)

    private val composeView = ComposeView(context).apply {
        setContent {
            ArSceneContent(this@ArEngineView)
        }
    }

    init {
        eventChannel.setStreamHandler(this)
        methodChannel.setMethodCallHandler(::onMethodCall)
    }

    // ---------------------------------------------------------------------------------
    // MethodChannel (Dart -> native)
    // ---------------------------------------------------------------------------------

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val markers = (call.argument<Any>("markers") as? List<*>)?.mapNotNull { raw ->
                    (raw as? Map<*, *>)?.let { m ->
                        MarkerSpec(
                            name = m["name"] as? String ?: return@let null,
                            imagePath = m["imagePath"] as? String ?: return@let null,
                            widthMeters = (m["widthMeters"] as? Number)?.toFloat()
                        )
                    }
                } ?: emptyList()

                val models = (call.argument<Any>("models") as? Map<*, *>)
                    ?.mapKeys { (k, _) -> k.toString() }
                    ?.mapValues { (_, v) -> v.toString() }
                    ?: emptyMap()

                val scale = (call.argument<Number>("scaleToUnits") ?: 0.2).toFloat()

                mainHandler.post {
                    config = EngineConfig(markers, models, scale)
                    Log.i(TAG, "configured markers=${markers.size} models=${models.size} scale=$scale")
                    sendEvent(
                        mapOf(
                            "event" to "configured",
                            "markerCount" to markers.size,
                            "modelCount" to models.size
                        )
                    )
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------------------
    // EventChannel (native -> Dart)
    // ---------------------------------------------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink.set(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink.set(null)
    }

    private fun sendEvent(payload: Map<String, Any?>) {
        val sink = eventSink.get() ?: return
        try {
            sink.success(payload)
        } catch (e: Exception) {
            Log.w(TAG, "sendEvent failed", e)
        }
    }

    private fun log(message: String) {
        Log.i(TAG, message)
    }

    // ---------------------------------------------------------------------------------
    // Callback dari AR composable
    // ---------------------------------------------------------------------------------

    fun onSessionCreated(session: Session) {
        log("AR session created")
        sendEvent(mapOf("event" to "sessionCreated"))
    }

    fun onSessionFailed(error: Exception) {
        Log.e(TAG, "AR session failed", error)
        sendEvent(mapOf("event" to "sessionFailed", "message" to (error.message ?: error.toString())))
    }

    fun onSessionUpdated(frame: Frame) {
        val updated = try {
            frame.getUpdatedAugmentedImages()
        } catch (e: Exception) {
            Log.w(TAG, "getUpdatedAugmentedImages failed", e)
            return
        }
        for (image in updated) {
            if (image.trackingState == TrackingState.TRACKING) {
                if (detectedImages.none { it.name == image.name }) {
                    mainHandler.post {
                        detectedImages.add(image)
                    }
                }
            }
        }
    }

    fun onImageTrackingStateChanged(name: String, state: TrackingState) {
        log("Augmented image '$name' -> ${state.name}")
        sendEvent(
            mapOf(
                "event" to "trackedAugmentedImage",
                "name" to name,
                "trackingState" to state.name
            )
        )
    }

    fun onCameraTrackingChanged(reason: com.google.ar.core.TrackingFailureReason?) {
        sendEvent(
            mapOf(
                "event" to "cameraTrackingStateChanged",
                "reason" to reason?.name
            )
        )
    }

    fun modelFileUriFor(name: String): String? {
        val path = config?.modelsByMarker?.get(name) ?: return null
        if (path.startsWith("file://")) return path
        return "file://$path"
    }

    // ---------------------------------------------------------------------------------
    // Konfigurasi ARCore (dijalankan saat session dikonfigurasi)
    // ---------------------------------------------------------------------------------

    fun applySessionConfiguration(session: Session, config: Config) {
        val database = AugmentedImageDatabase(session)
        val specs = this.config?.markers.orEmpty()
        for (spec in specs) {
            val bitmap = decodeMarkerImage(context, spec.imagePath)
            if (bitmap == null) {
                log("Marker image missing for '${spec.name}': ${spec.imagePath}")
                continue
            }
            try {
                if (spec.widthMeters != null && spec.widthMeters > 0f) {
                    database.addImage(spec.name, bitmap, spec.widthMeters)
                } else {
                    database.addImage(spec.name, bitmap)
                }
                log("Image target registered: ${spec.name}")
            } catch (e: Exception) {
                Log.e(TAG, "addImage failed for '${spec.name}'", e)
            } finally {
                bitmap.recycle()
            }
        }
        config.augmentedImageDatabase = database
        Log.i(TAG, "Session configured with ${specs.size} marker image(s)")
    }

    private fun decodeMarkerImage(context: Context, path: String): Bitmap? {
        val bitmap = if (path.startsWith("assets/")) {
            try {
                context.assets.open(path.substringAfter("assets/")).use { BitmapFactory.decodeStream(it) }
            } catch (e: Exception) {
                Log.w(TAG, "asset decode failed: $path", e)
                null
            }
        } else {
            BitmapFactory.decodeFile(path)
        } ?: return null
        return if (bitmap.config != Bitmap.Config.ARGB_8888) {
            bitmap.copy(Bitmap.Config.ARGB_8888, false).also { bitmap.recycle() }
        } else {
            bitmap
        }
    }

    // ---------------------------------------------------------------------------------
    // PlatformView
    // ---------------------------------------------------------------------------------

    override fun getView() = composeView

    override fun dispose() {
        mainHandler.post {
            eventSink.set(null)
            config = null
            detectedImages.clear()
            composeView.disposeComposition()
        }
    }
}

/**
 * Composable AR scene untuk [io.github.sceneview.ar.ARSceneView].
 *
 * Semua marker didaftarkan ke augment image database saat sesi dikonfigurasi; setiap gambar yang
 * mulai di-TRACKING otomatis diberi [AugmentedImageNode] + [ModelNode] (GLB lokal) di atasnya.
 */
@androidx.compose.runtime.Composable
private fun ArSceneContent(view: ArEngineView) {
    CompositionLocalProvider(LocalLifecycleOwner provides view.lifecycleOwner) {
        var session by remember { androidx.compose.runtime.mutableStateOf<Session?>(null) }
        var sessionConfig by remember { androidx.compose.runtime.mutableStateOf<Config?>(null) }

        ARSceneView(
            modifier = Modifier.fillMaxSize(),
            surfaceType = SurfaceType.TextureSurface,
            planeRenderer = false,
            lifecycle = view.lifecycleOwner.lifecycle,
            sessionConfiguration = { s, c ->
                view.applySessionConfiguration(s, c)
                sessionConfig = c
            },
            onSessionCreated = { s ->
                view.onSessionCreated(s)
                session = s
            },
            onSessionFailed = { error -> view.onSessionFailed(error) },
            onSessionUpdated = { _, frame -> view.onSessionUpdated(frame) },
            onTrackingFailureChanged = { reason -> view.onCameraTrackingChanged(reason) },
            permissionHandler = view.permissionHandler
        ) {
            view.detectedImages.forEach { image ->
                val fileUri = view.modelFileUriFor(image.name)
                if (fileUri != null) {
                    AugmentedImageNode(
                        augmentedImage = image,
                        onTrackingStateChanged = { state ->
                            view.onImageTrackingStateChanged(image.name, state)
                        }
                    ) {
                        val instance = rememberModelInstance(modelLoader, fileUri)
                        if (instance != null) {
                            ModelNode(
                                modelInstance = instance,
                                scaleToUnits = view.config?.scaleToUnits,
                                centerOrigin = Position(0.0f, -1.0f, 0.0f)
                            )
                        }
                    }
                }
            }
        }

        // `configure` dari Flutter dapat tiba setelah session ARCore dibuat, sehingga image
        // target database harus dibangun ulang secara reaktif begitu config + session siap.
        // Memakai instance Config yang sama agar preset SceneView (light estimation, dst.)
        // tetap dipertahankan.
        LaunchedEffect(view.config, session, sessionConfig) {
            val cfg = view.config ?: return@LaunchedEffect
            val s = session ?: return@LaunchedEffect
            val c = sessionConfig ?: return@LaunchedEffect
            view.applySessionConfiguration(s, c)
            s.configure(c)
        }
    }
}
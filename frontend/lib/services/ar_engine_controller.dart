import 'dart:async';

import 'package:flutter/services.dart';

/// Spesifikasi satu image marker yang akan didaftarkan ke ARCore.
class ArEngineMarker {
  final String name;
  final String imagePath;
  final double? widthMeters;

  const ArEngineMarker({
    required this.name,
    required this.imagePath,
    this.widthMeters,
  });
}

/// Event native -> Flutter dari [ArEngineView].
class ArEngineEvent {
  final String name;
  final Map<String, dynamic> payload;

  const ArEngineEvent(this.name, this.payload);

  String get message => payload['message'] as String? ?? '';
  String? get markerName => payload['name'] as String?;
  String? get trackingState => payload['trackingState'] as String?;
  bool get isDetected => trackingState == 'TRACKING';
  bool get isLost => trackingState == 'STOPPED' || trackingState == 'PAUSED';
  int get markerCount => payload['markerCount'] as int? ?? 0;
  int get modelCount => payload['modelCount'] as int? ?? 0;
}

/// Kontrol untuk engine AR native (Opsi 3: ARCore + GLB renderer sendiri).
///
/// API komunikasi:
///  - `configure(...)` mengirim daftar marker (nama = marker_id backend) + peta
///    marker -> GLB lokal + skala model.
///  - native melaporkan via [events]: configured, sessionCreated, sessionFailed,
///    trackedAugmentedImage, cameraTrackingStateChanged.
class ArEngineController {
  static const _methodChannel = MethodChannel('com.example.frontend/ar_engine');
  static const _eventChannel =
      EventChannel('com.example.frontend/ar_engine_events');

  final StreamController<ArEngineEvent> _streamController =
      StreamController<ArEngineEvent>.broadcast();

  StreamSubscription<dynamic>? _eventSubscription;
  bool _configured = false;

  ArEngineController() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((raw) {
      if (raw is Map) {
        _streamController.add(
          ArEngineEvent(
            raw['event'] as String? ?? 'unknown',
            Map<String, dynamic>.from(raw),
          ),
        );
      }
    }, onError: (Object error) {
      _streamController.addError(error);
    });
  }

  Stream<ArEngineEvent> get events => _streamController.stream;

  bool get isConfigured => _configured;

  /// Mengirim konfigurasi marker + model GLB ke engine native.
  ///
  /// [markers] — semua marker aktif; `name` harus sama dengan `marker_id`
  /// backend (mis. `MARKER-CPU-001`), `imagePath` = file cache lokal atau
  /// `assets/...`.
  /// [modelsByMarker] — pemetaan `marker_id` -> path GLB lokal (render di native).
  /// [scaleToUnits] — skala model agar muat di kubus berukuran sekian meter.
  Future<void> configure({
    required List<ArEngineMarker> markers,
    required Map<String, String> modelsByMarker,
    double scaleToUnits = 0.2,
  }) async {
    await _methodChannel.invokeMethod<void>('configure', {
      'markers': markers
          .map((m) => {
                'name': m.name,
                'imagePath': m.imagePath,
                'widthMeters': m.widthMeters,
              })
          .toList(),
      'models': modelsByMarker,
      'scaleToUnits': scaleToUnits,
    });
    _configured = true;
  }

  void dispose() {
    _eventSubscription?.cancel();
    _streamController.close();
    _configured = false;
  }
}

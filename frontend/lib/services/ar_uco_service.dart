import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'ar_uco_frame_math.dart';

/// Format piksel aktif dari kamera. Bervariasi antar device Android.
enum ArFrameFormat {
  /// `ImageFormatGroup.yuv420` (paling umum, dipakai mayoritas device).
  yuv420,

  /// `ImageFormatGroup.bgra8888` (fallback untuk device yang menolak yuv420).
  bgra8888,
}

extension ArFrameFormatLabel on ArFrameFormat {
  String get label => switch (this) {
        ArFrameFormat.yuv420 => 'yuv420',
        ArFrameFormat.bgra8888 => 'bgra8888',
      };
}

/// Pipeline deteksi ArUco dengan fokus kompatibilitas lintas device Android:
///
/// 1. Negosiasi format kamera (yuv420 -> bgra8888 fallback).
/// 2. Konversi frame -> grayscale tanpa menyentuh native thread blocking UI
///    (grayscale Y sudah chanel tunggal, tidak perlu cvtColor).
/// 3. Deteksi asinkron via native OpenCV (`detectMarkersAsync`) sehingga
///    frame berat tidak memblokir UI thread (penting untuk HP kelas bawah).
/// 4. Detektor/dictionary dibuat sekali dan dipakai ulang (bukan tiap frame).
/// 5. Geometri frame + orientasi sensor diekspos agar overlay dapat
///    memetakan koordinat corner ke ruang preview yang benar (rotasi aman).
class ArUcoService {
  CameraController? _controller;
  final ValueNotifier<List<ArUcoResult>> _resultsNotifier =
      ValueNotifier<List<ArUcoResult>>([]);

  bool _isScanning = false;
  bool _nativeLibraryReady = false;
  String? _nativeLibraryError;
  ArFrameFormat _frameFormat = ArFrameFormat.yuv420;
  int _sensorOrientation = 90;

  int _frameSkip = 5;
  int _frameCount = 0;
  bool _isProcessing = false;
  bool _disposeRequested = false;

  int _frameWidth = 0;
  int _frameHeight = 0;
  int _processedFrames = 0;
  int? _lastProcessMicros;

  Uint8List? _pendingGray;
  Uint8List _grayBuffer = Uint8List(0);

  /// Dictionary yang didukung backend (`ArMarkerGenerator::DICTIONARIES`).
  /// Deteksi dijalankan untuk semuanya agar marker 5x5/6x6/7x7 tidak lagi
  /// gagal terdeteksi hanya karena scanner mengunci ke DICT_4X4_50.
  static const Map<String, cv.PredefinedDictionaryType> supportedDictionaries =
      {
    'DICT_4X4_50': cv.PredefinedDictionaryType.DICT_4X4_50,
    'DICT_5X5_100': cv.PredefinedDictionaryType.DICT_5X5_100,
    'DICT_6X6_250': cv.PredefinedDictionaryType.DICT_6X6_250,
    'DICT_7X7_1000': cv.PredefinedDictionaryType.DICT_7X7_1000,
  };

  final Map<String, cv.ArucoDictionary> _dictionaries = {};
  cv.ArucoDetectorParameters? _detectorParams;
  final Map<String, cv.ArucoDetector> _detectors = {};

  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;
  ValueNotifier<List<ArUcoResult>> get resultsNotifier => _resultsNotifier;
  bool get isScanning => _isScanning;
  bool get nativeLibraryReady => _nativeLibraryReady;
  String? get nativeLibraryError => _nativeLibraryError;

  /// Format piksel aktif saat ini (untuk statistik/debugging).
  String get frameFormatLabel => _frameFormat.label;

  /// Orientasi sensor kamera dalam derajat (biasanya 90 atau 270).
  int get sensorOrientation => _sensorOrientation;

  /// Dimensi frame terakhir yang diproses.
  int get frameWidth => _frameWidth;
  int get frameHeight => _frameHeight;

  /// Jumlah frame yang berhasil dideteksi (untuk pemonitoran performa).
  int get processedFrameCount => _processedFrames;

  /// Waktu proses deteksi terakhir dalam milidetik.
  double? get lastProcessMs =>
      _lastProcessMicros == null ? null : _lastProcessMicros! / 1000.0;

  /// Seberapa sering frame diproses. 1 = setiap frame, 5 = tiap frame ke-5.
  /// Turunkan pada perangkat kelas bawah untuk menghemat CPU.
  int get frameSkip => _frameSkip;
  set frameSkip(int value) {
    _frameSkip = value < 1 ? 1 : value;
  }

  Future<void> initialize() async {
    _cameras = await availableCameras();
    final backCamera = _cameras?.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    final controller = await _tryCreateController(
      backCamera!,
      ImageFormatGroup.yuv420,
    );
    if (controller != null) {
      _frameFormat = ArFrameFormat.yuv420;
      _controller = controller;
    } else {
      final fallback =
          await _tryCreateController(backCamera, ImageFormatGroup.bgra8888);
      if (fallback != null) {
        _frameFormat = ArFrameFormat.bgra8888;
        _controller = fallback;
      }
    }

    if (_controller == null) {
      throw CameraException(
        'initialize',
        'Tidak dapat menginisialisasi kamera '
            '(format yuv420 dan bgra8888 gagal di device ini).',
      );
    }

    _sensorOrientation = backCamera.sensorOrientation;

    // Catatan exposure: JANGAN mengunci exposure di sini. Auto-exposure
    // membutuhkan beberapa frame untuk converges; mengunci-nya sebelum itu
    // membuat exposure terkunci pada nilai yang belum benar. Gejalanya preview
    // kamera menjadi putih terang dan deteksi marker selalu gagal di device
    // tertentu. Pen Stabilanannya dilakukan setelah streaming berjalan
    // (lihat _stabilizeCamera).

    _nativeLibraryReady = await _probeNativeLibrary();
    if (kDebugMode) {
      debugPrint('Camera initialized: ${_controller!.description}');
      debugPrint(
        'Frame format: ${_frameFormat.label}, '
        'sensorOrientation: $_sensorOrientation',
      );
      debugPrint('Native library ready: $_nativeLibraryReady');
    }
  }

  Future<CameraController?> _tryCreateController(
    CameraDescription description,
    ImageFormatGroup format,
  ) async {
    final controller = CameraController(
      description,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: format,
    );
    try {
      await controller.initialize();
      return controller;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Camera init failed (${format.name}): $e');
      }
      try {
        await controller.dispose();
      } catch (_) {
        // Abaikan: controller gagal initialize, dispose sebatas bisa.
      }
      return null;
    }
  }

  Future<bool> _probeNativeLibrary() async {
    _nativeLibraryError = null;
    try {
      _detectorParams = cv.ArucoDetectorParameters.empty();
      for (final entry in supportedDictionaries.entries) {
        cv.ArucoDictionary? dictionary;
        try {
          dictionary = cv.ArucoDictionary.predefined(entry.value);
          _detectors[entry.key] = cv.ArucoDetector.create(
            dictionary,
            _detectorParams!,
          );
          _dictionaries[entry.key] = dictionary;
        } catch (e, stack) {
          // Satu dictionary yang tidak didukung build OpenCV tidak boleh
          // mematikan scanner untuk dictionary lain.
          dictionary?.dispose();
          if (kDebugMode) {
            debugPrint(
              'ArUco dictionary unavailable (${entry.key}): $e',
            );
            debugPrint('$stack');
          }
        }
      }

      if (_detectors.isEmpty) {
        throw StateError(
            'Tidak ada ArUco dictionary yang bisa diinisialisasi.');
      }

      // Smoke-test alokasi native agar status "siap" benar-benar akurat.
      final probe =
          cv.Mat.fromList(16, 16, cv.MatType.CV_8UC1, List<int>.filled(256, 0));
      probe.dispose();
      return true;
    } catch (e, stack) {
      _nativeLibraryError = '$e';
      if (kDebugMode) {
        debugPrint('OpenCV native library probe failed: $e');
        debugPrint('$stack');
      }
      _disposeDetectors();
      return false;
    }
  }

  void startScanning() {
    if (_isScanning || _controller == null) return;
    if (!_nativeLibraryReady) {
      if (kDebugMode) debugPrint('Native library not ready!');
      return;
    }
    _isScanning = true;
    _frameCount = 0;
    _processedFrames = 0;
    _lastProcessMicros = null;
    _pendingGray = null;
    _isProcessing = false;
    _controller!.startImageStream(_onCameraFrame);
    unawaited(_stabilizeCamera());
    if (kDebugMode) debugPrint('Scanning started');
  }

  /// Menstabilkan kamera setelah auto-exposure sempat converged.
  ///
  /// Eksposure sengaja TIDAK dikunci agar pencahayaan tetap adaptsi terhadap
  /// kondisi ruangan - itu justru membantu deteksi saat cahaya berubah.
  /// Fokus dikunci saja (dan hanya setelah jeda), karena fokus tidak memengaruhi
  /// kecerahan tetapi membuat gambar lebih stabil untuk OpenCV.
  Future<void> _stabilizeCamera() async {
    final controller = _controller;
    if (controller == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (_disposeRequested || _controller != controller) return;

    try {
      await controller.setFocusMode(FocusMode.locked);
    } catch (_) {
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {
// Sebagian device tidak mendukung penguncian fokus pada format ini.
// Biarkan saja, deteksi tetap berjalan dengan fokus otomatis.
      }
    }
  }

  void stopScanning() {
    _isScanning = false;
    _pendingGray = null;
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _resultsNotifier.value = [];
    if (kDebugMode) debugPrint('Scanning stopped');
  }

  void _onCameraFrame(CameraImage image) {
    if (!_isScanning || _disposeRequested) return;
    _frameCount++;
    if (_frameCount % _frameSkip != 0) return;

    final gray = _extractGray(image);
    if (gray.isEmpty) return;

    _frameWidth = image.width;
    _frameHeight = image.height;
    _pendingGray = gray;
    _pump();
  }

  Future<void> _pump() async {
    if (_isProcessing || _pendingGray == null) return;
    if (_detectors.isEmpty) return;

    final gray = _pendingGray!;
    _pendingGray = null;
    _isProcessing = true;
    try {
      final results = await _detectMarkers(gray);
      if (_disposeRequested) return;
      _resultsNotifier.value = results;
    } finally {
      _isProcessing = false;
      if (!_disposeRequested) _pump();
    }
  }

  Future<List<ArUcoResult>> _detectMarkers(Uint8List gray) async {
    final w = _frameWidth;
    final h = _frameHeight;
    final stopwatch = Stopwatch()..start();

    final mat = cv.Mat.fromList(h, w, cv.MatType.CV_8UC1, gray);
    final results = <ArUcoResult>[];
    try {
      // Jalankan tiap dictionary secara berurutan pada Mat yang sama.
      // Deteksi tetap di thread native (tidak memblokir UI isolate).
      for (final entry in _detectors.entries) {
        cv.VecVecPoint2f? cornersVec;
        cv.VecI32? idsVec;
        cv.VecVecPoint2f? rejectedVec;
        try {
          final detectResult = await entry.value.detectMarkersAsync(mat);
          cornersVec = detectResult.$1;
          idsVec = detectResult.$2;
          rejectedVec = detectResult.$3;

          final ids = idsVec.toList().cast<int>();
          if (ids.isEmpty) continue;

          final cornersList = cornersVec.toList();
          for (int i = 0; i < ids.length && i < cornersList.length; i++) {
            final points = <List<double>>[];
            for (final p in cornersList[i].toList()) {
              points.add([p.x, p.y]);
            }
            results.add(ArUcoResult(
              markerId: ids[i],
              arucoDictionary: entry.key,
              corners: points,
            ));
          }
        } catch (e, stack) {
          // Satu dictionary gagal tidak boleh menghentikan dictionary lain.
          if (kDebugMode) {
            debugPrint('ArUco detection error (${entry.key}): $e');
            debugPrint('$stack');
          }
        } finally {
          cornersVec?.dispose();
          idsVec?.dispose();
          rejectedVec?.dispose();
        }
      }

      _processedFrames++;
      _lastProcessMicros = stopwatch.elapsedMicroseconds;
      if (kDebugMode && results.isNotEmpty) {
        debugPrint(
          'Detected ${results.length} markers in '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
      return results;
    } finally {
      mat.dispose();
    }
  }

  void _disposeDetectors() {
    for (final detector in _detectors.values) {
      detector.dispose();
    }
    _detectors.clear();
    for (final dictionary in _dictionaries.values) {
      dictionary.dispose();
    }
    _dictionaries.clear();
    _detectorParams?.dispose();
    _detectorParams = null;
  }

  Uint8List _extractGray(CameraImage image) {
    try {
      final w = image.width;
      final h = image.height;
      if (_grayBuffer.length != w * h) {
        _grayBuffer = Uint8List(w * h);
      }
      final plane = image.planes[0];
      switch (_frameFormat) {
        case ArFrameFormat.yuv420:
          ArUcoFrameMath.cropYPlane(plane.bytes, w, h,
              stride: plane.bytesPerRow, out: _grayBuffer);
        case ArFrameFormat.bgra8888:
          ArUcoFrameMath.bgraToGray(plane.bytes, w, h,
              rowStride: plane.bytesPerRow, out: _grayBuffer);
      }
      return _grayBuffer;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Extract grayscale error: $e');
        debugPrint('$stack');
      }
      return Uint8List(0);
    }
  }

  // ---------------------------------------------------------------------
  // Delegasi ke helper murni (di-unit-test via ar_uco_frame_math.dart).
  // ---------------------------------------------------------------------

  static int normalizeDegrees(int deg) => ArUcoFrameMath.normalizeDegrees(deg);

  static Uint8List cropYPlane(
    Uint8List bytes,
    int width,
    int height, {
    int stride = -1,
    Uint8List? out,
  }) =>
      ArUcoFrameMath.cropYPlane(bytes, width, height, stride: stride, out: out);

  static Uint8List bgraToGray(
    Uint8List bgra,
    int width,
    int height, {
    int rowStride = -1,
    Uint8List? out,
  }) =>
      ArUcoFrameMath.bgraToGray(bgra, width, height,
          rowStride: rowStride, out: out);

  static List<List<double>> mapCornersToPreview({
    required List<List<double>> corners,
    required double imageWidth,
    required double imageHeight,
    required int sensorOrientationDeg,
    required int deviceRotationDeg,
  }) =>
      ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        sensorOrientationDeg: sensorOrientationDeg,
        deviceRotationDeg: deviceRotationDeg,
      );

  static ({double outW, double outH}) previewSpace({
    required double imageWidth,
    required double imageHeight,
    required int sensorOrientationDeg,
    required int deviceRotationDeg,
  }) =>
      ArUcoFrameMath.previewSpace(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        sensorOrientationDeg: sensorOrientationDeg,
        deviceRotationDeg: deviceRotationDeg,
      );

  static ({double scale, double dx, double dy}) coverTransform({
    required double outW,
    required double outH,
    required double previewWidth,
    required double previewHeight,
  }) =>
      ArUcoFrameMath.coverTransform(
        outW: outW,
        outH: outH,
        previewWidth: previewWidth,
        previewHeight: previewHeight,
      );

  Future<void> dispose() async {
    _disposeRequested = true;
    stopScanning();
    await _controller?.dispose();
    _controller = null;
    _disposeDetectors();
  }
}

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/foundation.dart';

import '../models/models.dart';

class ArUcoService {
  CameraController? _controller;
  final ValueNotifier<List<ArUcoResult>> _resultsNotifier =
      ValueNotifier<List<ArUcoResult>>([]);
  bool _isScanning = false;
  Timer? _debounceTimer;
  int _frameCount = 0;

  CameraController? get controller => _controller;
  ValueNotifier<List<ArUcoResult>> get resultsNotifier => _resultsNotifier;
  bool get isScanning => _isScanning;
  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    final backCamera = _cameras?.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      backCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.setExposureMode(ExposureMode.locked);
    await _controller!.setFocusMode(FocusMode.locked);
  }

  void startScanning() {
    if (_isScanning || _controller == null) return;
    _isScanning = true;
    _frameCount = 0;
    _controller!.startImageStream(_onCameraFrame);
  }

  void stopScanning() {
    _isScanning = false;
    _debounceTimer?.cancel();
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _resultsNotifier.value = [];
  }

  void _onCameraFrame(CameraImage image) {
    if (!_isScanning) return;
    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isScanning) return;
      _processFrame(image);
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final mat = _convertCameraImageToMat(image);
      if (mat == null) return;

      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
      final dict = cv.ArucoDictionary.predefined(
        cv.PredefinedDictionaryType.DICT_4X4_50,
      );
      final detectorParams = cv.ArucoDetectorParameters.empty();
      final detector = cv.ArucoDetector.create(dict, detectorParams);

      final detectResult = detector.detectMarkers(gray);
      final cornersVec = detectResult.$1;
      final idsVec = detectResult.$2;
      final rejectedVec = detectResult.$3;

      final corners = cornersVec.toList().cast<cv.Mat>();
      final ids = idsVec.toList().cast<int>();
      final rejected = rejectedVec.toList().cast<cv.Mat>();

      if (ids.isNotEmpty) {
        final results = <ArUcoResult>[];
        for (int i = 0; i < ids.length; i++) {
          final cornerPoints = <List<double>>[];
          final cornerMat = corners[i];
          for (int r = 0; r < cornerMat.rows; r++) {
            for (int c = 0; c < cornerMat.cols; c++) {
              final point = cornerMat.at<cv.Point2f>(r, c);
              cornerPoints.add([point.x, point.y]);
            }
          }
          results.add(ArUcoResult(
            markerId: ids[i],
            corners: cornerPoints,
          ));
        }
        _resultsNotifier.value = results;
      } else {
        _resultsNotifier.value = [];
      }

      for (final c in corners) c.dispose();
      for (final r in rejected) r.dispose();
      gray.dispose();
      mat.dispose();
      detector.dispose();
    } catch (e) {
      if (kDebugMode) print('ArUco detection error: $e');
    }
  }

  cv.Mat? _convertCameraImageToMat(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      final plane = image.planes[0];
      final Uint8List yBytes = plane.bytes;

      final List<num> yData = yBytes.toList();
      final mat = cv.Mat.fromList(
        height,
        width,
        cv.MatType.CV_8UC1,
        yData,
      );
      return mat;
    } catch (e) {
      if (kDebugMode) print('Convert CameraImage to Mat error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    stopScanning();
    await _controller?.dispose();
    _controller = null;
  }
}

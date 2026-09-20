import 'dart:io';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/foundation.dart';

class MarkerGenerator {
  static final MarkerGenerator _instance = MarkerGenerator._internal();
  factory MarkerGenerator() => _instance;
  MarkerGenerator._internal();

  Future<void> generateMarker({
    required int markerId,
    required cv.PredefinedDictionaryType markerType,
    required String outputPath,
    int pixelSize = 500,
  }) async {
    final dict = cv.ArucoDictionary.predefined(markerType);
    final mat = dict.generateImageMarker(markerId, pixelSize);
    final bytes = mat.data;

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

    mat.dispose();
  }

  Future<void> generateMultipleMarkers({
    required List<int> markerIds,
    cv.PredefinedDictionaryType markerType =
        cv.PredefinedDictionaryType.DICT_4X4_50,
    required String outputDir,
    int pixelSize = 500,
  }) async {
    for (final id in markerIds) {
      final path = '$outputDir/marker_$id.png';
      await generateMarker(
        markerId: id,
        markerType: markerType,
        outputPath: path,
        pixelSize: pixelSize,
      );
    }
  }

  Future<cv.Mat?> loadMarkerImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return cv.imdecode(bytes, cv.IMREAD_COLOR);
  }
}

Future<void> generateTestMarkers() async {
  final generator = MarkerGenerator();
  final outputDir = 'assets/markers';
  await Directory(outputDir).create(recursive: true);

  await generator.generateMultipleMarkers(
    markerIds: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    markerType: cv.PredefinedDictionaryType.DICT_4X4_50,
    outputDir: outputDir,
    pixelSize: 500,
  );

  if (kDebugMode) print('Generated 10 test markers in $outputDir');
}

Future<void> main() async {
  await generateTestMarkers();
}

import 'dart:math' as math;
import 'dart:typed_data';

/// Helper matematis/frame murni untuk pipeline deteksi ArUco.
///
/// File ini sengaja TIDAK mengimpor `dartcv4` atau `camera` agar dapat
/// di-unit-test tanpa memicu build native OpenCV.
class ArUcoFrameMath {
  ArUcoFrameMath._();

  /// Normalisasi sudut (derajat) ke rentang 0..359.
  static int normalizeDegrees(int deg) {
    final d = deg % 360;
    return d < 0 ? d + 360 : d;
  }

  /// Menyalin plane Y (grayscale) dari frame YUV420.
  ///
  /// Beberapa device memberi `stride != width` (tiap baris berisi padding di
  /// akhir baris). Helper ini memotong padding dengan aman. Mengembalikan
  /// buffer tujuan agar bisa dirantai.
  static Uint8List cropYPlane(
    Uint8List bytes,
    int width,
    int height, {
    int stride = -1,
    Uint8List? out,
  }) {
    final dst = out ?? Uint8List(width * height);
    final s = stride >= 0 ? stride : width;
    if (s == width) {
      final copyLen = math.min(bytes.length, dst.length);
      dst.setRange(0, copyLen, bytes);
      return dst;
    }
    for (int y = 0; y < height; y++) {
      final src = y * s;
      final dstStart = y * width;
      final safe = math.min(width, math.max(0, bytes.length - src));
      dst.setRange(dstStart, dstStart + safe, bytes, src);
    }
    return dst;
  }

  /// Konversi manual BGRA (4 byte/pixel) -> grayscale (BT.601).
  ///
  /// Dipakai untuk format `bgra8888` / `image_io`. Biaya O(w*h) dengan
  /// aritmetika integer sederhana sehingga tetap ringan di device pas-pasan.
  static Uint8List bgraToGray(
    Uint8List bgra,
    int width,
    int height, {
    int rowStride = -1,
    Uint8List? out,
  }) {
    final dst = out ?? Uint8List(width * height);
    final stride = rowStride >= 0 ? rowStride : width * 4;
    final len = bgra.length;
    int index = 0;
    for (int y = 0; y < height; y++) {
      final row = y * stride;
      for (int x = 0; x < width; x++, index++) {
        final i = row + x * 4;
        if (i + 2 >= len) {
          dst[index] = 0;
          continue;
        }
        final b = bgra[i];
        final g = bgra[i + 1];
        final r = bgra[i + 2];
        dst[index] = (r * 77 + g * 150 + b * 29 + 128) >> 8;
      }
    }
    return dst;
  }

  /// Memetakan koordinat corner (pixel, ruang frame sensor) ke koordinat
  /// ternormalisasi (0..1) dalam orientasi preview device.
  ///
  /// [sensorOrientationDeg] — dari `CameraDescription.sensorOrientation`
  /// (biasanya 90/270). [deviceRotationDeg] — rotasi layar device:
  /// 0 potret, 90/270 landscape.
  ///
  /// Hasil memakai aspek rasio gambar (bukan ukuran layar); UI yang
  /// menampilkan overlay cukup mengalikan dengan ukuran box preview yang
  /// sudah di-fit.
  static List<List<double>> mapCornersToPreview({
    required List<List<double>> corners,
    required double imageWidth,
    required double imageHeight,
    required int sensorOrientationDeg,
    required int deviceRotationDeg,
  }) {
    final rot = normalizeDegrees(sensorOrientationDeg - deviceRotationDeg);
    final w = imageWidth;
    final h = imageHeight;
    final swap = rot == 90 || rot == 270;
    final outW = swap ? h : w;
    final outH = swap ? w : h;

    return corners.map((c) {
      if (c.length < 2) return <double>[0.0, 0.0];
      final x = c[0];
      final y = c[1];
      late final double nx;
      late final double ny;
      switch (rot) {
        case 90:
          nx = h - y;
          ny = x;
        case 180:
          nx = w - x;
          ny = h - y;
        case 270:
          nx = y;
          ny = w - x;
        default:
          nx = x;
          ny = y;
      }
      return <double>[
        outW == 0 ? 0.0 : nx / outW,
        outH == 0 ? 0.0 : ny / outH,
      ];
    }).toList();
  }

  /// Dimensi ruang ternormalisasi hasil [mapCornersToPreview]
  /// (aspek gambar setelah kompensasi rotasi).
  static ({double outW, double outH}) previewSpace({
    required double imageWidth,
    required double imageHeight,
    required int sensorOrientationDeg,
    required int deviceRotationDeg,
  }) {
    final rot = normalizeDegrees(sensorOrientationDeg - deviceRotationDeg);
    final swap = rot == 90 || rot == 270;
    return (
      outW: swap ? imageHeight : imageWidth,
      outH: swap ? imageWidth : imageHeight,
    );
  }

  /// Transform BoxFit.cover dari ruang ternormalisasi (0..1, berdimensi
  /// [previewSpace]) ke piksel viewport [previewWidth]x[previewHeight].
  ///
  /// Mengembalikan (scale, offsetX, offsetY) sehingga:
  ///   display = norm * outDim * scale + offset
  /// Offset negatif = tepi ter-crop (wajar untuk cover).
  static ({double scale, double dx, double dy}) coverTransform({
    required double outW,
    required double outH,
    required double previewWidth,
    required double previewHeight,
  }) {
    if (outW <= 0 || outH <= 0 || previewWidth <= 0 || previewHeight <= 0) {
      return (scale: 1.0, dx: 0.0, dy: 0.0);
    }
    final scale =
        math.max(previewWidth / outW, previewHeight / outH).toDouble();
    return (
      scale: scale,
      dx: (previewWidth - outW * scale) / 2,
      dy: (previewHeight - outH * scale) / 2,
    );
  }
}

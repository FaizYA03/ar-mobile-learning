import 'dart:math' as math;

/// Jejak marker di ruang preview: titik tengah + ukuran (berbasis rata-rata
/// panjang sisi yang berseberangan) agar kokoh walau marker miring.
class MarkerFootprint {
  final double centerX;
  final double centerY;
  final double width;
  final double height;

  const MarkerFootprint({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });

  bool get isValid =>
      width > 0 && height > 0 && width.isFinite && height.isFinite;
}

/// Anchor untuk menaruh model 3D di layar preview: kotak (left, top, w, h)
/// dihitung agar "kaki" model berada tepat di atas marker.
class ModelAnchor {
  final double left;
  final double top;
  final double width;
  final double height;

  const ModelAnchor({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  bool get isValid => left.isFinite && top.isFinite && width > 0 && height > 0;
}

/// Perhitungan murni tanpa native/UI, dapat diuji dengan `dart run` biasa.
class ArCameraProjector {
  ArCameraProjector._();

  static double _dist(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Menghitung footprint marker dari 4 corner (urut 0-1-2-3 mengelilingi
  /// marker). Aman terhadap marker yang dimiringkan.
  static MarkerFootprint computeMarkerFootprint(List<List<double>> corners) {
    if (corners.length < 4) {
      return const MarkerFootprint(centerX: 0, centerY: 0, width: 0, height: 0);
    }

    var cx = 0.0;
    var cy = 0.0;
    for (final p in corners) {
      cx += p[0];
      cy += p[1];
    }
    final centerX = cx / 4.0;
    final centerY = cy / 4.0;

    final w1 =
        _dist(corners[0][0], corners[0][1], corners[1][0], corners[1][1]);
    final w2 =
        _dist(corners[2][0], corners[2][1], corners[3][0], corners[3][1]);
    final h1 =
        _dist(corners[1][0], corners[1][1], corners[2][0], corners[2][1]);
    final h2 =
        _dist(corners[3][0], corners[3][1], corners[0][0], corners[0][1]);

    final width = (w1 + w2) / 2.0;
    final height = (h1 + h2) / 2.0;

    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return const MarkerFootprint(centerX: 0, centerY: 0, width: 0, height: 0);
    }

    return MarkerFootprint(
        centerX: centerX, centerY: centerY, width: width, height: height);
  }

  /// Menempatkan kotak model di atas marker.
  ///
  /// [previewW]/[previewH] = ukuran viewport (0 = tanpa clamp).
  /// [modelScale] = rasio lebar model terhadap lebar marker.
  /// [liftFactor] = jarak "kaki" model dari titik tengah marker (dalam
  /// satuan tinggi marker).
  /// [modelAspectRatio] = tinggi / lebar kotak model.
  static ModelAnchor computeModelAnchor(
    MarkerFootprint footprint, {
    double previewW = 0,
    double previewH = 0,
    double modelScale = 3.0,
    double liftFactor = 1.0,
    double modelAspectRatio = 1.0,
  }) {
    if (!footprint.isValid) {
      return const ModelAnchor(left: 0, top: 0, width: 0, height: 0);
    }

    final modelWidth = footprint.width * modelScale;
    final modelHeight = modelWidth * modelAspectRatio;
    final liftPx = footprint.height * liftFactor;

    var left = footprint.centerX - modelWidth / 2.0;
    final feetY = footprint.centerY - liftPx;
    var top = feetY - modelHeight;

    if (previewW > 0 && previewH > 0) {
      const pad = 24.0;
      left = left < pad
          ? pad
          : (left > previewW - modelWidth - pad
              ? previewW - modelWidth - pad
              : left);
      top = top < pad
          ? pad
          : (top > previewH - modelHeight - pad
              ? previewH - modelHeight - pad
              : top);
    }

    return ModelAnchor(
      left: left,
      top: top,
      width: modelWidth,
      height: modelHeight,
    );
  }

  /// Memetakan DeviceOrientation (indeks enum camera plugin) ke derajat.
  static int deviceRotationToDegrees(int deviceOrientationIndex) {
    switch (deviceOrientationIndex) {
      case 1:
        return 90;
      case 2:
        return 180;
      case 3:
        return 270;
      default:
        return 0;
    }
  }
}

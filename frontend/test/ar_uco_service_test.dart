import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/ar_camera_projector.dart';
import 'package:frontend/services/ar_uco_frame_math.dart';

void main() {
  group('ArUcoFrameMath.cropYPlane', () {
    test('contiguous (stride == width) copies all bytes', () {
      final bytes = Uint8List.fromList(List<int>.generate(12, (i) => i));
      final out = ArUcoFrameMath.cropYPlane(bytes, 4, 3);
      expect(out.length, 12);
      expect(out[0], 0);
      expect(out[11], 11);
    });

    test('padded stride crops padding from each row', () {
      // 4x3 dengan stride 6 (tiap baris ada 2 byte padding = 9).
      final bytes = Uint8List.fromList([
        0, 1, 2, 3, 9, 9, //
        4, 5, 6, 7, 9, 9, //
        8, 9, 10, 11, 9, 9, //
      ]);
      final out = ArUcoFrameMath.cropYPlane(bytes, 4, 3, stride: 6);
      expect(out.length, 12);
      expect(out[0], 0);
      expect(out[3], 3);
      expect(out[4], 4);
      expect(out[7], 7);
      expect(out[8], 8);
      expect(out[11], 11);
    });

    test('short row fills remaining with zero', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final out = ArUcoFrameMath.cropYPlane(bytes, 4, 1);
      expect(out.length, 4);
      expect(out[0], 1);
      expect(out[1], 2);
      expect(out[3], 0);
    });

    test('writes into provided buffer', () {
      final bytes = Uint8List.fromList(List<int>.generate(6, (i) => i + 1));
      final out = Uint8List(6);
      ArUcoFrameMath.cropYPlane(bytes, 3, 2, out: out);
      expect(out[5], 6);
    });
  });

  group('ArUcoFrameMath.bgraToGray', () {
    test('black pixel maps to 0, white pixel maps to 255', () {
      final bgra = Uint8List.fromList(
          [0, 0, 0, 255, 255, 255, 255, 255]); // 2 pixel (1x2)
      final out = ArUcoFrameMath.bgraToGray(bgra, 2, 1);
      expect(out[0], 0);
      expect(out[1], 255);
    });

    test('pure red maps to 77 (BT.601)', () {
      // R=255,G=0,B=0 -> (77*255 + 128) >> 8 = 19763 >> 8 = 77
      final bgra = Uint8List.fromList([0, 0, 255, 255]);
      final out = ArUcoFrameMath.bgraToGray(bgra, 1, 1);
      expect(out[0], 77);
    });

    test('gray = (77r + 150g + 29b + 128) >> 8', () {
      // r=100,g=150,b=200 -> (7700 + 22500 + 5800 + 128) >> 8 = 36128 >> 8 = 141
      final bgra = Uint8List.fromList([200, 150, 100, 255]);
      final out = ArUcoFrameMath.bgraToGray(bgra, 1, 1);
      expect(out[0], 36128 >> 8);
    });

    test('handles rowStride padding', () {
      final bgra = Uint8List.fromList([
        0, 0, 0, 255, 0, 0, 0, 0, // pixel hitam + 4 byte padding
        255, 255, 255, 255, 0, 0, 0, 0, //
      ]);
      final out = ArUcoFrameMath.bgraToGray(bgra, 1, 2, rowStride: 8);
      expect(out[0], 0);
      expect(out[1], 255);
    });
  });

  group('ArUcoFrameMath.normalizeDegrees', () {
    test('positive wraps to 0..359', () {
      expect(ArUcoFrameMath.normalizeDegrees(360), 0);
      expect(ArUcoFrameMath.normalizeDegrees(450), 90);
    });

    test('negative becomes positive', () {
      expect(ArUcoFrameMath.normalizeDegrees(-90), 270);
      expect(ArUcoFrameMath.normalizeDegrees(-180), 180);
    });
  });

  group('ArUcoFrameMath.mapCornersToPreview', () {
    const w = 640.0;
    const h = 480.0;

    test('sensor 90, portrait (0): rotates 90 deg clockwise', () {
      final corners = [
        [0.0, 0.0],
        [100.0, 0.0],
      ];
      final out = ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: w,
        imageHeight: h,
        sensorOrientationDeg: 90,
        deviceRotationDeg: 0,
      );
      // rot = 90 -> (h - y, x); output width = h, height = w.
      expect(out[0][0], closeTo(1.0, 1e-9)); // (480-0)/480
      expect(out[0][1], closeTo(0.0, 1e-9)); // 0/640
      expect(out[1][0], closeTo(1.0, 1e-9)); // (480-0)/480
      expect(out[1][1], closeTo(100.0 / 640.0, 1e-9));
    });

    test('sensor 90, landscapeLeft (90): no extra rotation', () {
      final corners = [
        [320.0, 240.0],
      ];
      final out = ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: w,
        imageHeight: h,
        sensorOrientationDeg: 90,
        deviceRotationDeg: 90,
      );
      expect(out[0][0], closeTo(0.5, 1e-9));
      expect(out[0][1], closeTo(0.5, 1e-9));
    });

    test('sensor 90, landscapeRight (270): rotates 180 deg', () {
      final corners = [
        [0.0, 0.0],
      ];
      final out = ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: w,
        imageHeight: h,
        sensorOrientationDeg: 90,
        deviceRotationDeg: 270,
      );
      // rot = 180 -> (w - x, h - y) = (640, 480); normal = (1,1).
      expect(out[0][0], closeTo(1.0, 1e-9));
      expect(out[0][1], closeTo(1.0, 1e-9));
    });

    test('sensor 270, portrait (0): rotates 270 deg clockwise', () {
      final corners = [
        [640.0, 480.0],
      ];
      final out = ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: w,
        imageHeight: h,
        sensorOrientationDeg: 270,
        deviceRotationDeg: 0,
      );
      // rot = 270 -> (y, w - x) = (480, 0); normal = (1.0, 0.0).
      expect(out[0][0], closeTo(1.0, 1e-9));
      expect(out[0][1], closeTo(0.0, 1e-9));
    });

    test('degrades gracefully when corner has single element', () {
      final corners = [
        [10.0],
      ];
      final out = ArUcoFrameMath.mapCornersToPreview(
        corners: corners,
        imageWidth: w,
        imageHeight: h,
        sensorOrientationDeg: 90,
        deviceRotationDeg: 0,
      );
      expect(out[0][0], 0.0);
      expect(out[0][1], 0.0);
    });
  });

  group('ArCameraProjector.computeMarkerFootprint', () {
    test('computes center and size from square corners', () {
      final square = [
        [100.0, 100.0],
        [200.0, 100.0],
        [200.0, 200.0],
        [100.0, 200.0],
      ];
      final fp = ArCameraProjector.computeMarkerFootprint(square);
      expect(fp.isValid, isTrue);
      expect(fp.centerX, closeTo(150, 1e-9));
      expect(fp.centerY, closeTo(150, 1e-9));
      expect(fp.width, closeTo(100, 1e-9));
      expect(fp.height, closeTo(100, 1e-9));
    });

    test('returns invalid for < 4 corners', () {
      final fp = ArCameraProjector.computeMarkerFootprint([
        [0.0, 0.0],
      ]);
      expect(fp.isValid, isFalse);
    });
  });

  group('ArCameraProjector.computeModelAnchor', () {
    test('places model above marker center', () {
      final fp = ArCameraProjector.computeMarkerFootprint([
        [100.0, 100.0],
        [200.0, 100.0],
        [200.0, 200.0],
        [100.0, 200.0],
      ]);
      final anchor = ArCameraProjector.computeModelAnchor(fp);
      expect(anchor.isValid, isTrue);
      expect(anchor.width, closeTo(300, 1e-9));
      // Kaki model di markerCenterY - lift (1x tinggi marker).
      expect(anchor.top + anchor.height, closeTo(50, 1e-9));
    });

    test('clamps within preview viewport', () {
      final fp = ArCameraProjector.computeMarkerFootprint([
        [10.0, 10.0],
        [30.0, 10.0],
        [30.0, 30.0],
        [10.0, 30.0],
      ]);
      final anchor = ArCameraProjector.computeModelAnchor(
        fp,
        previewW: 200,
        previewH: 300,
      );
      expect(anchor.left, greaterThanOrEqualTo(24));
      expect(anchor.top, greaterThanOrEqualTo(24));
      expect(anchor.left + anchor.width, lessThanOrEqualTo(200 - 24 + 1e-9));
      expect(anchor.top + anchor.height, lessThanOrEqualTo(300 - 24 + 1e-9));
    });
  });

  group('ArCameraProjector.deviceRotationToDegrees', () {
    test('maps DeviceOrientation index to degrees', () {
      expect(ArCameraProjector.deviceRotationToDegrees(0), 0);
      expect(ArCameraProjector.deviceRotationToDegrees(1), 90);
      expect(ArCameraProjector.deviceRotationToDegrees(2), 180);
      expect(ArCameraProjector.deviceRotationToDegrees(3), 270);
    });
  });
}

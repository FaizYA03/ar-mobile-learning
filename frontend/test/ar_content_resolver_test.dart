import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/services/ar_content_resolver.dart';

void main() {
  group('ArContentResolver', () {
    setUp(() {
      ArContentResolver.resetForTest();
    });

    test('content is empty by default', () {
      expect(ArContentResolver.content, isEmpty);
    });

    test('isContentLoaded is false when empty', () {
      expect(ArContentResolver.isContentLoaded, isFalse);
    });

    test('contentCount is 0 when empty', () {
      expect(ArContentResolver.contentCount, 0);
    });

    test('resolveByModelId returns null when content not loaded', () {
      expect(ArContentResolver.resolveByModelId(1), isNull);
    });

    test('resolveByMarkerId returns null when content not loaded', () {
      expect(ArContentResolver.resolveByMarkerId('marker-1'), isNull);
    });

    test('resolveByArucoId returns null when content not loaded', () {
      expect(ArContentResolver.resolveByArucoId(0), isNull);
    });

    test('resolveHotspots returns empty list when content not loaded', () {
      expect(ArContentResolver.resolveHotspots(1), isEmpty);
    });

    test('setContent and resolveByModelId works', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 10,
              markerId: 'MARKER-CPU-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 0,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [
            ArHotspotData(id: 20, title: 'Info CPU'),
          ],
        ),
        ArContentItem(
          id: 2,
          modelName: 'RAM',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 11,
              markerId: 'MARKER-RAM-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 1,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      expect(ArContentResolver.content.length, 2);
      expect(ArContentResolver.isContentLoaded, isTrue);
      expect(ArContentResolver.contentCount, 2);

      final resolved = ArContentResolver.resolveByModelId(1);
      expect(resolved, isNotNull);
      expect(resolved!.modelName, 'CPU');

      final notFound = ArContentResolver.resolveByModelId(99);
      expect(notFound, isNull);
    });

    test('resolveByMarkerId finds correct model', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 10,
              markerId: 'MARKER-CPU-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 0,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [],
        ),
        ArContentItem(
          id: 2,
          modelName: 'RAM',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 20,
              markerId: 'MARKER-RAM-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 1,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final resolved = ArContentResolver.resolveByMarkerId('MARKER-RAM-001');
      expect(resolved, isNotNull);
      expect(resolved!.modelName, 'RAM');

      final notFound = ArContentResolver.resolveByMarkerId('MARKER-99');
      expect(notFound, isNull);
    });

    test('resolveByArucoId finds correct model via backend ar_uco_id', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 10,
              markerId: 'MARKER-CPU-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 0,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [],
        ),
        ArContentItem(
          id: 2,
          modelName: 'Keyboard',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 20,
              markerId: 'MARKER-KEYBOARD-001',
              markerType: 'pattern',
              status: 'active',
              arUcoId: 2,
              arucoDictionary: 'DICT_4X4_50',
            ),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final resolved0 = ArContentResolver.resolveByArucoId(0);
      expect(resolved0, isNotNull);
      expect(resolved0!.modelName, 'CPU');

      final resolved2 = ArContentResolver.resolveByArucoId(2);
      expect(resolved2, isNotNull);
      expect(resolved2!.modelName, 'Keyboard');

      final notFound = ArContentResolver.resolveByArucoId(99);
      expect(notFound, isNull);
    });

    test('resolveByArucoId returns null when marker has no ar_uco_id', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'Test',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 10,
              markerId: 'MARKER-NO-ARUCO',
              markerType: 'pattern',
              status: 'active',
            ),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final resolved = ArContentResolver.resolveByArucoId(0);
      expect(resolved, isNull);
    });

    test('resolveByMarkerCode delegates to resolveByMarkerId', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(
              id: 10,
              markerId: 'CODE-123',
              markerType: 'image',
              status: 'active',
            ),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final resolved = ArContentResolver.resolveByMarkerCode('CODE-123');
      expect(resolved, isNotNull);
      expect(resolved!.id, 1);
    });

    test('resolveHotspots returns correct hotspots', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [],
          hotspots: [
            ArHotspotData(id: 1, title: 'Hotspot A'),
            ArHotspotData(id: 2, title: 'Hotspot B'),
          ],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final hotspots = ArContentResolver.resolveHotspots(1);
      expect(hotspots.length, 2);
      expect(hotspots[0].title, 'Hotspot A');
      expect(hotspots[1].title, 'Hotspot B');

      final emptyHotspots = ArContentResolver.resolveHotspots(99);
      expect(emptyHotspots, isEmpty);
    });

    test('lastFetchTime is null by default', () {
      expect(ArContentResolver.lastFetchTime, isNull);
    });
  });

  group('ArResolveResult', () {
    test('parses from JSON correctly', () {
      final json = {
        'marker': {
          'id': 1,
          'marker_id': 'MARKER-CPU-001',
          'ar_uco_id': 0,
          'aruco_dictionary': 'DICT_4X4_50',
          'marker_type': 'pattern',
          'status': 'active',
        },
        'model': {
          'id': 1,
          'model_name': 'Microprocessor CPU 3D',
          'description': 'CPU model',
          'category': 'Hardware',
          'version': 1,
          'glb_url': '/storage/models/cpu.glb',
          'glb_path': 'models/cpu.glb',
          'thumbnail_url': '/storage/thumbnails/cpu.png',
          'thumbnail_path': 'thumbnails/cpu.png',
        },
        'hotspots': [
          {
            'id': 1,
            'title': 'ALU',
            'description': 'Arithmetic Logic Unit',
            'position_x': 0.0,
            'position_y': 0.0,
            'position_z': 0.0,
            'rotation_x': 0.0,
            'rotation_y': 0.0,
            'rotation_z': 0.0,
            'scale': 1.0,
            'sort_order': 0,
          },
        ],
      };

      final result = ArResolveResult.fromJson(json);

      expect(result.marker.id, 1);
      expect(result.marker.markerId, 'MARKER-CPU-001');
      expect(result.marker.arUcoId, 0);
      expect(result.marker.arucoDictionary, 'DICT_4X4_50');

      expect(result.model.id, 1);
      expect(result.model.modelName, 'Microprocessor CPU 3D');
      expect(result.model.glbUrl, '/storage/models/cpu.glb');
      expect(result.model.glbPath, 'models/cpu.glb');

      expect(result.hotspots.length, 1);
      expect(result.hotspots[0].title, 'ALU');
    });

    test('parses marker not found error response', () {
      final json = {
        'success': false,
        'message': 'Marker tidak ditemukan',
        'data': null,
      };

      expect(json['success'], false);
      expect(json['data'], isNull);
    });
  });

  group('ArMarkerData', () {
    test('parses arUcoId and arucoDictionary from JSON', () {
      final json = {
        'id': 1,
        'marker_id': 'MARKER-CPU-001',
        'ar_uco_id': 0,
        'aruco_dictionary': 'DICT_4X4_50',
        'marker_type': 'pattern',
        'status': 'active',
      };

      final marker = ArMarkerData.fromJson(json);

      expect(marker.id, 1);
      expect(marker.markerId, 'MARKER-CPU-001');
      expect(marker.arUcoId, 0);
      expect(marker.arucoDictionary, 'DICT_4X4_50');
      expect(marker.markerType, 'pattern');
      expect(marker.status, 'active');
    });

    test('handles null arUcoId and arucoDictionary', () {
      final json = {
        'id': 1,
        'marker_id': 'MARKER-LEGACY',
        'marker_type': 'image',
        'status': 'active',
      };

      final marker = ArMarkerData.fromJson(json);

      expect(marker.arUcoId, isNull);
      expect(marker.arucoDictionary, isNull);
    });
  });

  group('ArUcoResult', () {
    test('parses arucoDictionary from JSON', () {
      final json = {
        'marker_id': 0,
        'aruco_dictionary': 'DICT_4X4_50',
        'corners': [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
        ],
        'marker_type': 'aruco',
        'detected_at': '2026-09-20T12:00:00.000Z',
      };

      final result = ArUcoResult.fromJson(json);

      expect(result.markerId, 0);
      expect(result.arucoDictionary, 'DICT_4X4_50');
      expect(result.corners.length, 4);
    });

    test('defaults arucoDictionary to DICT_4X4_50', () {
      final json = {
        'marker_id': 1,
        'corners': [],
      };

      final result = ArUcoResult.fromJson(json);

      expect(result.arucoDictionary, 'DICT_4X4_50');
    });
  });
}

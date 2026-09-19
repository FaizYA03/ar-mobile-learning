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
            ArMarkerData(id: 10, markerId: 'MARKER-1', markerType: 'image', status: 'active'),
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
          markers: [],
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
            ArMarkerData(id: 10, markerId: 'MARKER-1', markerType: 'image', status: 'active'),
          ],
          hotspots: [],
        ),
        ArContentItem(
          id: 2,
          modelName: 'RAM',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(id: 20, markerId: 'MARKER-2', markerType: 'image', status: 'active'),
          ],
          hotspots: [],
        ),
      ];

      ArContentResolver.setContentForTest(items);

      final resolved = ArContentResolver.resolveByMarkerId('MARKER-2');
      expect(resolved, isNotNull);
      expect(resolved!.modelName, 'RAM');

      final notFound = ArContentResolver.resolveByMarkerId('MARKER-99');
      expect(notFound, isNull);
    });

    test('resolveByMarkerCode delegates to resolveByMarkerId', () {
      final items = [
        ArContentItem(
          id: 1,
          modelName: 'CPU',
          version: 1,
          isActive: true,
          markers: [
            ArMarkerData(id: 10, markerId: 'CODE-123', markerType: 'image', status: 'active'),
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
}

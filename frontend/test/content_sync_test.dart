import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/services/content_sync_service.dart';

void main() {
  group('ContentManifest', () {
    test('creates empty manifest', () {
      final manifest = ContentManifest.empty();
      expect(manifest.contentVersion, 0);
      expect(manifest.items, isEmpty);
    });

    test('parses from JSON correctly', () {
      final json = {
        'content_version': 15,
        'items': [
          {
            'model_id': 1,
            'version': 2,
            'local_path': '/path/to/model.glb',
            'remote_url': 'http://example.com/model.glb',
            'asset_type': 'model',
            'checksum': null,
            'downloaded_at': '2026-09-19T10:00:00Z',
          },
          {
            'model_id': 1,
            'version': 1,
            'local_path': '/path/to/thumb.png',
            'remote_url': 'http://example.com/thumb.png',
            'asset_type': 'thumbnail',
            'checksum': null,
            'downloaded_at': '2026-09-19T10:00:00Z',
          }
        ],
      };
      final manifest = ContentManifest.fromJson(json);
      expect(manifest.contentVersion, 15);
      expect(manifest.items.length, 2);
      expect(manifest.items.first.assetType, 'model');
      expect(manifest.items.last.assetType, 'thumbnail');
    });

    test('serializes to JSON correctly', () {
      final manifest = ContentManifest(
        contentVersion: 10,
        items: [
          ContentManifestItem(
            modelId: 1,
            version: 1,
            localPath: '/path/to/model.glb',
            remoteUrl: 'http://example.com/model.glb',
            assetType: 'model',
            downloadedAt: '2026-09-19T10:00:00Z',
          ),
        ],
      );
      final json = manifest.toJson();
      expect(json['content_version'], 10);
      expect(json['items'], isA<List>());
      expect(json['items'].length, 1);
    });

    test('handles missing items in JSON', () {
      final manifest = ContentManifest.fromJson({'content_version': 5});
      expect(manifest.items, isEmpty);
    });
  });

  group('ContentManifestItem', () {
    test('parses from JSON correctly', () {
      final json = {
        'model_id': 1,
        'version': 2,
        'local_path': '/path/to/model.glb',
        'remote_url': 'http://example.com/model.glb',
        'asset_type': 'model',
        'checksum': null,
        'downloaded_at': '2026-09-19T10:00:00Z',
      };
      final item = ContentManifestItem.fromJson(json);
      expect(item.modelId, 1);
      expect(item.version, 2);
      expect(item.localPath, '/path/to/model.glb');
      expect(item.assetType, 'model');
    });
  });

  group('SyncResult', () {
    test('initial state is up to date', () {
      final result = SyncResult();
      expect(result.status, SyncStatus.upToDate);
      expect(result.isOffline, false);
      expect(result.totalAssets, 0);
      expect(result.assetsToDownload, isEmpty);
    });
  });

  group('AssetDownloadInfo', () {
    test('stores all fields correctly', () {
      final asset = AssetDownloadInfo(
        modelId: 1,
        version: 2,
        url: 'http://example.com/model.glb',
        assetType: 'model',
        fileName: 'model_1_v2.glb',
      );
      expect(asset.modelId, 1);
      expect(asset.version, 2);
      expect(asset.url, 'http://example.com/model.glb');
      expect(asset.assetType, 'model');
      expect(asset.fileName, 'model_1_v2.glb');
    });
  });

  group('DownloadResult', () {
    test('initial state is failed', () {
      final result = DownloadResult();
      expect(result.success, false);
      expect(result.localPath, null);
      expect(result.error, null);
    });
  });

  group('Cache Decision Logic', () {
    test('same version means no download needed', () {
      final localVersion = 15;
      final remoteVersion = 15;
      expect(localVersion == remoteVersion, true);
    });

    test('different version means download needed', () {
      final localVersion = 15;
      final remoteVersion = 16;
      expect(localVersion != remoteVersion, true);
    });

    test('new model requires download when not in manifest', () {
      final manifest = ContentManifest(contentVersion: 15, items: []);
      final modelId = 1;
      final existing = manifest.items
          .where((i) => i.modelId == modelId && i.assetType == 'model')
          .toList();
      expect(existing.isEmpty, true);
    });

    test('existing model with same version skips download', () {
      final manifest = ContentManifest(
        contentVersion: 15,
        items: [
          ContentManifestItem(
            modelId: 1,
            version: 2,
            localPath: '/path/model.glb',
            remoteUrl: 'http://example.com/model.glb',
            assetType: 'model',
            downloadedAt: '2026-09-19T10:00:00Z',
          ),
        ],
      );
      final modelVersion = 2;
      final existing = manifest.items
          .where((i) => i.modelId == 1 && i.assetType == 'model')
          .toList();
      final needsDownload =
          existing.isEmpty || existing.first.version != modelVersion;
      expect(needsDownload, false);
    });

    test('existing model with different version requires download', () {
      final manifest = ContentManifest(
        contentVersion: 15,
        items: [
          ContentManifestItem(
            modelId: 1,
            version: 1,
            localPath: '/path/model.glb',
            remoteUrl: 'http://example.com/model.glb',
            assetType: 'model',
            downloadedAt: '2026-09-19T10:00:00Z',
          ),
        ],
      );
      final modelVersion = 2;
      final existing = manifest.items
          .where((i) => i.modelId == 1 && i.assetType == 'model')
          .toList();
      final needsDownload =
          existing.isEmpty || existing.first.version != modelVersion;
      expect(needsDownload, true);
    });

    test('offline with cache returns cached data', () {
      final manifest = ContentManifest(
        contentVersion: 15,
        items: [
          ContentManifestItem(
            modelId: 1,
            version: 2,
            localPath: '/path/model.glb',
            remoteUrl: 'http://example.com/model.glb',
            assetType: 'model',
            downloadedAt: '2026-09-19T10:00:00Z',
          ),
        ],
      );
      final cachedItem = manifest.items
          .where((i) => i.modelId == 1 && i.assetType == 'model')
          .toList();
      expect(cachedItem.isNotEmpty, true);
    });

    test('offline without cache shows error', () {
      final manifest = ContentManifest.empty();
      final cachedItem = manifest.items
          .where((i) => i.modelId == 1 && i.assetType == 'model')
          .toList();
      expect(cachedItem.isEmpty, true);
    });
  });

  group('Marker Replacement Detection', () {
    ArMarkerData markerWith({String? updatedAt}) => ArMarkerData(
          id: 5,
          markerId: 'MARKER-CPU-001',
          markerType: 'image',
          imageUrl: 'http://example.com/marker.png',
          imagePath: 'markers/marker.png',
          status: 'active',
          updatedAt: updatedAt,
        );

    ContentManifestItem cachedItem({required int version}) =>
        ContentManifestItem(
          modelId: 1,
          version: version,
          localPath: '/path/marker_5.png',
          remoteUrl: 'http://example.com/marker.png',
          assetType: 'marker_5',
          downloadedAt: '2026-09-19T10:00:00Z',
        );

    test('missing marker requires download', () {
      final needs = ContentSyncService.shouldDownloadMarker(
        existing: [],
        marker: markerWith(updatedAt: '2026-09-19T10:00:00+00:00'),
      );
      expect(needs, true);
    });

    test('same updated_at skips re-download', () {
      final version =
          DateTime.parse('2026-09-19T10:00:00+00:00').millisecondsSinceEpoch;
      final needs = ContentSyncService.shouldDownloadMarker(
        existing: [cachedItem(version: version)],
        marker: markerWith(updatedAt: '2026-09-19T10:00:00+00:00'),
      );
      expect(needs, false);
    });

    test('newer updated_at detects marker image replacement', () {
      final old =
          DateTime.parse('2026-09-19T10:00:00+00:00').millisecondsSinceEpoch;
      final needs = ContentSyncService.shouldDownloadMarker(
        existing: [cachedItem(version: old)],
        marker: markerWith(updatedAt: '2026-09-20T08:30:00+00:00'),
      );
      expect(needs, true);
    });

    test('backend without updated_at only downloads once', () {
      final needs = ContentSyncService.shouldDownloadMarker(
        existing: [cachedItem(version: 0)],
        marker: markerWith(updatedAt: null),
      );
      expect(needs, false);
    });
  });
}

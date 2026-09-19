import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';

void main() {
  group('AppUser', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'siswa',
        'avatar': null,
      };
      final user = AppUser.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, 'siswa');
      expect(user.avatar, null);
    });

    test('role checks work correctly', () {
      expect(AppUser(id: 1, name: '', email: '', role: 'admin').isAdmin, true);
      expect(AppUser(id: 1, name: '', email: '', role: 'guru').isGuru, true);
      expect(AppUser(id: 1, name: '', email: '', role: 'siswa').isSiswa, true);
      expect(AppUser(id: 1, name: '', email: '', role: 'admin').isSiswa, false);
    });

    test('serializes to JSON correctly', () {
      final user = AppUser(id: 1, name: 'Test', email: 't@t.com', role: 'guru');
      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test');
      expect(json['role'], 'guru');
    });
  });

  group('LoginResponse', () {
    test('parses from JSON correctly', () {
      final json = {
        'user': {'id': 1, 'name': 'Test', 'email': 't@t.com', 'role': 'siswa'},
        'token': 'abc123',
      };
      final response = LoginResponse.fromJson(json);
      expect(response.user.id, 1);
      expect(response.token, 'abc123');
    });
  });

  group('AppConfigData', () {
    test('parses from JSON correctly', () {
      final json = {
        'maintenance_mode': false,
        'latest_version': '1.0.0',
        'minimum_supported_version': '1.0.0',
        'build_number': '1',
        'release_notes': 'Initial release',
        'download_url': null,
        'content_version': 15,
      };
      final config = AppConfigData.fromJson(json);
      expect(config.maintenanceMode, false);
      expect(config.latestVersion, '1.0.0');
      expect(config.contentVersion, 15);
    });

    test('defaults to safe values when missing', () {
      final config = AppConfigData.fromJson({});
      expect(config.maintenanceMode, false);
      expect(config.latestVersion, null);
      expect(config.contentVersion, 0);
    });
  });

  group('ContentVersionData', () {
    test('parses from JSON correctly', () {
      final json = {
        'content_version': 42,
        'updated_at': '2026-09-19T10:00:00Z',
      };
      final data = ContentVersionData.fromJson(json);
      expect(data.contentVersion, 42);
      expect(data.updatedAt, '2026-09-19T10:00:00Z');
    });
  });

  group('ArContentItem', () {
    test('parses from JSON correctly with all fields', () {
      final json = {
        'id': 1,
        'model_name': 'CPU 3D',
        'description': 'A CPU model',
        'category': 'Hardware',
        'version': 2,
        'is_active': true,
        'glb_url': 'http://example.com/models/cpu_v2.glb',
        'glb_path': 'models/cpu_v2.glb',
        'thumbnail_url': 'http://example.com/thumbnails/cpu.png',
        'thumbnail_path': 'thumbnails/cpu.png',
        'markers': [
          {
            'id': 1,
            'marker_id': 'MARKER-CPU-001',
            'marker_type': 'pattern',
            'image_url': 'http://example.com/markers/cpu.png',
            'image_path': 'markers/cpu.png',
            'status': 'active',
          }
        ],
        'hotspots': [
          {
            'id': 1,
            'title': 'ALU',
            'description': 'Arithmetic Logic Unit',
            'latitude': 0.02,
            'longitude': 0.01,
            'image_url': null,
            'image_path': null,
          }
        ],
      };
      final item = ArContentItem.fromJson(json);
      expect(item.id, 1);
      expect(item.modelName, 'CPU 3D');
      expect(item.version, 2);
      expect(item.markers.length, 1);
      expect(item.hotspots.length, 1);
      expect(item.markers.first.markerId, 'MARKER-CPU-001');
      expect(item.hotspots.first.title, 'ALU');
    });

    test('handles null markers and hotspots', () {
      final json = {
        'id': 1,
        'model_name': 'Test',
        'version': 1,
        'is_active': true,
        'markers': null,
        'hotspots': null,
      };
      final item = ArContentItem.fromJson(json);
      expect(item.markers, isEmpty);
      expect(item.hotspots, isEmpty);
    });
  });

  group('ArMarkerData', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 1,
        'marker_id': 'CPU-001',
        'marker_type': 'image',
        'image_url': 'http://example.com/marker.png',
        'image_path': 'markers/marker.png',
        'status': 'active',
      };
      final marker = ArMarkerData.fromJson(json);
      expect(marker.id, 1);
      expect(marker.markerId, 'CPU-001');
      expect(marker.markerType, 'image');
      expect(marker.status, 'active');
    });
  });

  group('ArHotspotData', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 1,
        'title': 'ALU',
        'description': 'Arithmetic Logic Unit',
        'latitude': 0.02,
        'longitude': 0.01,
        'image_url': null,
        'image_path': null,
      };
      final hotspot = ArHotspotData.fromJson(json);
      expect(hotspot.id, 1);
      expect(hotspot.title, 'ALU');
      expect(hotspot.latitude, 0.02);
    });

    test('handles null coordinates', () {
      final hotspot = ArHotspotData.fromJson({'id': 1, 'title': 'Test'});
      expect(hotspot.latitude, null);
      expect(hotspot.longitude, null);
    });
  });
}

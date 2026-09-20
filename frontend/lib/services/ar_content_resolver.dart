import 'dart:io';
import '../models/models.dart';
import '../services/content_sync_service.dart';
import '../services/api_client.dart';

class ArContentResolver {
  static List<ArContentItem>? _cachedContent;
  static DateTime? _lastFetchTime;

  static Future<void> refreshContent() async {
    try {
      final response = await ApiClient.getV1('/ar/content');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        _cachedContent =
            data.map((item) => ArContentItem.fromJson(item)).toList();
        _lastFetchTime = DateTime.now();
      }
    } catch (_) {}
  }

  static List<ArContentItem> get content => _cachedContent ?? [];
  static DateTime? get lastFetchTime => _lastFetchTime;

  static ArContentItem? resolveByModelId(int modelId) {
    if (_cachedContent == null) return null;
    try {
      return _cachedContent!.firstWhere((item) => item.id == modelId);
    } catch (_) {
      return null;
    }
  }

  static ArContentItem? resolveByMarkerId(String markerId) {
    if (_cachedContent == null) return null;
    try {
      return _cachedContent!.firstWhere(
        (item) => item.markers.any((m) => m.markerId == markerId),
      );
    } catch (_) {
      return null;
    }
  }

  static ArContentItem? resolveByArucoId(int arUcoId) {
    if (_cachedContent == null) return null;
    try {
      // Map ArUco dictionary ID (0-49) to marker_id string
      // The mapping is: arUcoId -> marker_id like 'MARKER-XXXXX'
      // Based on backend seeding: MARKER-CPU-001, MARKER-ROUTER-001
      // We'll use a simple mapping: ID 0 -> MARKER-CPU-001, ID 1 -> MARKER-ROUTER-001, etc.
      // In production, this should be configured per marker in the backend
      if (arUcoId >= 0 && arUcoId <= 49) {
        // Simple mapping: use marker_id format from backend
        // This assumes admins configure marker IDs to match ArUco positions
        final String? markerId = _mapArucoIdToMarkerId(arUcoId);
        if (markerId != null) {
          return _cachedContent!.firstWhere(
            (item) => item.markers.any((m) => m.markerId == markerId),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _mapArucoIdToMarkerId(int arUcoId) {
    // Default mapping based on common backend marker IDs
    // Admins should configure this per their marker setup
    final Map<int, String> defaultMapping = {
      0: 'MARKER-CPU-001',
      1: 'MARKER-ROUTER-001',
    };
    return defaultMapping[arUcoId];
  }

  static Future<String?> resolveLocalModelPath(int modelId) async {
    final cachedPath = await ContentSyncService.getCachedModelPath(modelId);
    if (cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists()) return cachedPath;
    }

    final item = resolveByModelId(modelId);
    if (item?.glbUrl != null) return item!.glbUrl;

    return null;
  }

  static Future<String?> resolveModelUrl(int modelId) async {
    final localPath = await resolveLocalModelPath(modelId);
    if (localPath != null && !localPath.startsWith('http')) {
      return localPath;
    }

    final item = resolveByModelId(modelId);
    if (item?.glbUrl != null) return item!.glbUrl;
    if (item?.glbPath != null) {
      final base = ApiClient.instance.options.baseUrl;
      return '${base.replaceFirst('/api', '')}/storage/${item!.glbPath}';
    }

    return null;
  }

  static Future<String?> resolveMarkerImagePath(
      int modelId, int markerId) async {
    final cachedPath = await ContentSyncService.getCachedMarkerPath(markerId);
    if (cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists()) return cachedPath;
    }

    final item = resolveByModelId(modelId);
    if (item != null) {
      final marker = item.markers.where((m) => m.id == markerId).toList();
      if (marker.isNotEmpty) {
        if (marker.first.imageUrl != null) return marker.first.imageUrl;
        if (marker.first.imagePath != null) {
          final base = ApiClient.instance.options.baseUrl;
          return '${base.replaceFirst('/api', '')}/storage/${marker.first.imagePath}';
        }
      }
    }

    return null;
  }

  static List<ArHotspotData> resolveHotspots(int modelId) {
    final item = resolveByModelId(modelId);
    return item?.hotspots ?? [];
  }

  static bool get isContentLoaded =>
      _cachedContent != null && _cachedContent!.isNotEmpty;

  static int get contentCount => _cachedContent?.length ?? 0;

  static void setContentForTest(List<ArContentItem> items) {
    _cachedContent = items;
    _lastFetchTime = DateTime.now();
  }

  static void resetForTest() {
    _cachedContent = null;
    _lastFetchTime = null;
  }
}

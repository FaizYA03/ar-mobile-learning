import 'dart:io';
import '../models/models.dart';
import '../services/content_sync_service.dart';
import '../services/api_client.dart';

class ArContentResolver {
  static List<ArContentItem>? _cachedContent;
  static DateTime? _lastFetchTime;

  static const Duration maxCacheAge = Duration(minutes: 5);

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

  /// Menyegarkan konten hanya jika cache kosong atau sudah basi
  /// (melewati [maxCacheAge]) sejak pemuatan terakhir.
  ///
  /// Dipakai saat kembali dari layar penuh (ModelViewerScreen) agar tidak
  /// memicu request `/ar/content` yang tidak perlu jika data masih segar.
  /// Hotspot AR overlay di scanner sudah disuplai dari `/ar/resolve`,
  /// sehingga cache hanya perlu disinkronkan ulang bila jarang ter-update.
  static Future<void> refreshIfNeeded() async {
    final now = DateTime.now();
    final cached = _cachedContent;
    if (cached != null &&
        cached.isNotEmpty &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) <= maxCacheAge) {
      return;
    }
    await refreshContent();
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
      return _cachedContent!.firstWhere(
        (item) => item.markers.any((m) => m.arUcoId == arUcoId),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ArResolveResult?> resolveFromApi({
    String? arucoDictionary,
    int? arucoId,
    String? markerId,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (arucoDictionary != null && arucoId != null) {
        queryParams['aruco_dictionary'] = arucoDictionary;
        queryParams['aruco_id'] = arucoId;
        final response = await ApiClient.getV1(
          '/ar/resolve',
          queryParameters: queryParams,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          return ArResolveResult.fromJson(response.data['data']);
        }
      } else if (markerId != null) {
        queryParams['marker_id'] = markerId;
        final response = await ApiClient.getV1(
          '/ar/resolve/marker',
          queryParameters: queryParams,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          return ArResolveResult.fromJson(response.data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static ArContentItem? resolveByMarkerCode(String code) {
    return resolveByMarkerId(code);
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

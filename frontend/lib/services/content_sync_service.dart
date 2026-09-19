import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'api_client.dart';

class ContentManifest {
  int contentVersion;
  List<ContentManifestItem> items;

  ContentManifest({required this.contentVersion, required this.items});

  factory ContentManifest.empty() {
    return ContentManifest(contentVersion: 0, items: []);
  }

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    return ContentManifest(
      contentVersion: json['content_version'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => ContentManifestItem.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'content_version': contentVersion,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class ContentManifestItem {
  final int modelId;
  int version;
  String localPath;
  String remoteUrl;
  String assetType;
  String? checksum;
  String downloadedAt;

  ContentManifestItem({
    required this.modelId,
    required this.version,
    required this.localPath,
    required this.remoteUrl,
    required this.assetType,
    this.checksum,
    required this.downloadedAt,
  });

  factory ContentManifestItem.fromJson(Map<String, dynamic> json) {
    return ContentManifestItem(
      modelId: json['model_id'] ?? 0,
      version: json['version'] ?? 1,
      localPath: json['local_path'] ?? '',
      remoteUrl: json['remote_url'] ?? '',
      assetType: json['asset_type'] ?? 'model',
      checksum: json['checksum'],
      downloadedAt: json['downloaded_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'model_id': modelId,
        'version': version,
        'local_path': localPath,
        'remote_url': remoteUrl,
        'asset_type': assetType,
        'checksum': checksum,
        'downloaded_at': downloadedAt,
      };
}

class ContentSyncService {
  static ContentManifest? _manifest;

  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/ar_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static Future<File> _getManifestFile() async {
    final cacheDir = await _getCacheDir();
    return File('${cacheDir.path}/content_manifest.json');
  }

  static Future<ContentManifest> loadManifest() async {
    if (_manifest != null) return _manifest!;

    try {
      final file = await _getManifestFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _manifest = ContentManifest.fromJson(jsonDecode(content));
        return _manifest!;
      }
    } catch (_) {}

    _manifest = ContentManifest.empty();
    return _manifest!;
  }

  static Future<void> saveManifest(ContentManifest manifest) async {
    _manifest = manifest;
    final file = await _getManifestFile();
    await file.writeAsString(jsonEncode(manifest.toJson()));
  }

  static Future<int> getLocalContentVersion() async {
    final manifest = await loadManifest();
    return manifest.contentVersion;
  }

  static Future<ContentVersionData?> fetchRemoteContentVersion() async {
    try {
      final response = await ApiClient.getV1('/content/version');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ContentVersionData.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  static Future<AppConfigData?> fetchAppConfig() async {
    try {
      final response = await ApiClient.getV1('/app/config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return AppConfigData.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<ArContentItem>?> fetchArContent() async {
    try {
      final response = await ApiClient.getV1('/ar/content');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        return data.map((item) => ArContentItem.fromJson(item)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<SyncResult> sync() async {
    final result = SyncResult();

    final remoteVersion = await fetchRemoteContentVersion();
    if (remoteVersion == null) {
      result.isOffline = true;
      result.manifest = await loadManifest();
      return result;
    }

    final localVersion = await getLocalContentVersion();
    result.remoteVersion = remoteVersion.contentVersion;
    result.localVersion = localVersion;

    if (localVersion == remoteVersion.contentVersion) {
      result.status = SyncStatus.upToDate;
      result.manifest = await loadManifest();
      return result;
    }

    result.status = SyncStatus.needsUpdate;

    final arContent = await fetchArContent();
    if (arContent == null) {
      result.isOffline = true;
      result.manifest = await loadManifest();
      return result;
    }

    final manifest = await loadManifest();

    for (final item in arContent) {
      if (item.glbUrl != null && item.glbPath != null) {
        final existing = manifest.items.where((i) =>
            i.modelId == item.id && i.assetType == 'model').toList();

        if (existing.isEmpty || existing.first.version != item.version) {
          result.assetsToDownload.add(AssetDownloadInfo(
            modelId: item.id,
            version: item.version,
            url: item.glbUrl!,
            assetType: 'model',
            fileName: 'model_${item.id}_v${item.version}.glb',
          ));
        }
      }

      if (item.thumbnailUrl != null && item.thumbnailPath != null) {
        final existing = manifest.items.where((i) =>
            i.modelId == item.id && i.assetType == 'thumbnail').toList();

        if (existing.isEmpty) {
          result.assetsToDownload.add(AssetDownloadInfo(
            modelId: item.id,
            version: item.version,
            url: item.thumbnailUrl!,
            assetType: 'thumbnail',
            fileName: 'thumb_${item.id}.png',
          ));
        }
      }

      for (final marker in item.markers) {
        if (marker.imageUrl != null && marker.imagePath != null) {
          final existing = manifest.items.where((i) =>
              i.modelId == item.id &&
              i.assetType == 'marker_${marker.id}').toList();

          if (existing.isEmpty) {
            result.assetsToDownload.add(AssetDownloadInfo(
              modelId: item.id,
              version: marker.id,
              url: marker.imageUrl!,
              assetType: 'marker_${marker.id}',
              fileName: 'marker_${marker.id}.png',
            ));
          }
        }
      }
    }

    result.totalAssets = result.assetsToDownload.length;
    result.manifest = manifest;
    result.remoteManifest = manifest;
    result.remoteContentVersion = remoteVersion.contentVersion;

    return result;
  }

  static Future<DownloadResult> downloadAsset(AssetDownloadInfo asset) async {
    final result = DownloadResult();
    final cacheDir = await _getCacheDir();

    try {
      final targetDir = Directory('${cacheDir.path}/${asset.assetType}');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final tempFile = File('${targetDir.path}/${asset.fileName}.tmp');
      final finalFile = File('${targetDir.path}/${asset.fileName}');

      final dio = ApiClient.instance;
      await dio.download(
        asset.url,
        tempFile.path,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (await tempFile.exists() && await tempFile.length() > 0) {
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tempFile.rename(finalFile.path);

        result.success = true;
        result.localPath = finalFile.path;
      } else {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        result.success = false;
        result.error = 'Downloaded file is empty';
      }
    } catch (e) {
      result.success = false;
      result.error = e.toString();

      final tempFile = File('${cacheDir.path}/${asset.assetType}/${asset.fileName}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    return result;
  }

  static Future<void> updateManifestAfterDownload(
    AssetDownloadInfo asset,
    String localPath,
  ) async {
    final manifest = await loadManifest();

    manifest.items.removeWhere((i) =>
        i.modelId == asset.modelId && i.assetType == asset.assetType);

    manifest.items.add(ContentManifestItem(
      modelId: asset.modelId,
      version: asset.version,
      localPath: localPath,
      remoteUrl: asset.url,
      assetType: asset.assetType,
      downloadedAt: DateTime.now().toIso8601String(),
    ));

    await saveManifest(manifest);
  }

  static Future<String?> getCachedModelPath(int modelId) async {
    final manifest = await loadManifest();
    final item = manifest.items.where(
        (i) => i.modelId == modelId && i.assetType == 'model').toList();
    if (item.isNotEmpty) {
      final file = File(item.first.localPath);
      if (await file.exists()) return item.first.localPath;
    }
    return null;
  }

  static Future<String?> getCachedMarkerPath(int markerId) async {
    final manifest = await loadManifest();
    final item = manifest.items.where(
        (i) => i.assetType == 'marker_$markerId').toList();
    if (item.isNotEmpty) {
      final file = File(item.first.localPath);
      if (await file.exists()) return item.first.localPath;
    }
    return null;
  }

  static void invalidateCache() {
    _manifest = null;
  }
}

enum SyncStatus { upToDate, needsUpdate, error }

class SyncResult {
  SyncStatus status = SyncStatus.upToDate;
  bool isOffline = false;
  int localVersion = 0;
  int remoteVersion = 0;
  int totalAssets = 0;
  int downloadedAssets = 0;
  ContentManifest? manifest;
  ContentManifest? remoteManifest;
  int? remoteContentVersion;
  List<AssetDownloadInfo> assetsToDownload = [];
  String? error;
}

class AssetDownloadInfo {
  final int modelId;
  final int version;
  final String url;
  final String assetType;
  final String fileName;

  AssetDownloadInfo({
    required this.modelId,
    required this.version,
    required this.url,
    required this.assetType,
    required this.fileName,
  });
}

class DownloadResult {
  bool success = false;
  String? localPath;
  String? error;
}

import 'package:shared_preferences/shared_preferences.dart';
import '../core/debug/ar_debug_log.dart';
import 'ar_content_resolver.dart';
import 'ar_service.dart';
import 'content_sync_service.dart';

class ArDiagnosticsData {
  final ArCoreAvailability arCoreAvailability;
  final ArCoreDeviceInfo? deviceInfo;
  final bool cameraPermissionGranted;
  final String apiStatus;
  final int remoteContentVersion;
  final int localContentVersion;
  final int activeMarkerCount;
  final int arContentCount;
  final int cachedModelCount;
  final int cachedMarkerCount;
  final DateTime? lastSync;
  final DateTime? contentFetchedAt;
  final List<String> syncErrors;

  const ArDiagnosticsData({
    required this.arCoreAvailability,
    this.deviceInfo,
    required this.cameraPermissionGranted,
    required this.apiStatus,
    required this.remoteContentVersion,
    required this.localContentVersion,
    required this.activeMarkerCount,
    required this.arContentCount,
    required this.cachedModelCount,
    required this.cachedMarkerCount,
    this.lastSync,
    this.contentFetchedAt,
    required this.syncErrors,
  });

  bool get isArReady =>
      arCoreAvailability == ArCoreAvailability.supportedInstalled &&
      cameraPermissionGranted;

  String get arCoreLabel {
    switch (arCoreAvailability) {
      case ArCoreAvailability.supportedInstalled:
        return 'SUPPORTED_INSTALLED';
      case ArCoreAvailability.supportedNotInstalled:
        return 'SUPPORTED_NOT_INSTALLED';
      case ArCoreAvailability.unsupported:
        return 'UNSUPPORTED';
      case ArCoreAvailability.unknown:
        return 'UNKNOWN';
    }
  }
}

class ArDiagnosticsService {
  static Future<ArDiagnosticsData> collect() async {
    final availability = await ARService.checkAvailability();
    final deviceInfo = await ARService.getDeviceInfo();
    final cameraGranted = await ARService.hasCameraPermission();

    final remoteVersion = await ContentSyncService.fetchRemoteContentVersion();
    final localVersion = await ContentSyncService.getLocalContentVersion();
    final manifest = await ContentSyncService.loadManifest();

    final cachedModelCount =
        manifest.items.where((i) => i.assetType == 'model').length;
    final cachedMarkerCount =
        manifest.items.where((i) => i.assetType.startsWith('marker_')).length;

    var activeMarkerCount = 0;
    for (final item in ArContentResolver.content) {
      activeMarkerCount += item.markers.length;
    }

    final lastSync = await _readLastSync();
    final hasSyncError = localVersion != (remoteVersion?.contentVersion ?? 0);

    ArDebugLog.log(
      'Diagnostics: device=$deviceInfo, ARCore=$availability, '
      'camera=$cameraGranted, api=${remoteVersion != null ? 'online' : 'offline'}, '
      'content v$localVersion/$remoteVersion, markers=$activeMarkerCount, '
      'cache models=$cachedModelCount markers=$cachedMarkerCount',
    );

    return ArDiagnosticsData(
      arCoreAvailability: availability,
      deviceInfo: deviceInfo,
      cameraPermissionGranted: cameraGranted,
      apiStatus: remoteVersion != null ? 'online' : 'offline',
      remoteContentVersion: remoteVersion?.contentVersion ?? 0,
      localContentVersion: localVersion,
      activeMarkerCount: activeMarkerCount,
      arContentCount: ArContentResolver.contentCount,
      cachedModelCount: cachedModelCount,
      cachedMarkerCount: cachedMarkerCount,
      lastSync: lastSync,
      contentFetchedAt: ArContentResolver.lastFetchTime,
      syncErrors: hasSyncError
          ? [
              'Local content version ($localVersion) != remote (${remoteVersion?.contentVersion ?? 0})'
            ]
          : const [],
    );
  }

  static Future<DateTime?> _readLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt('content_last_sync');
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }
}

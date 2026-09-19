import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/app_config_service.dart';

void main() {
  group('AppConfigService version comparison', () {
    test('isVersionSupported returns true when no minimum set', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.isVersionSupported('1.0.0'), isTrue);
    });

    test('isUpdateAvailable returns false when no latest set', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.isUpdateAvailable('1.0.0'), isFalse);
    });

    test('isMaintenanceMode defaults to false', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.isMaintenanceMode, isFalse);
    });

    test('contentVersion defaults to 0', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.contentVersion, 0);
    });

    test('latestVersion defaults to null', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.latestVersion, isNull);
    });

    test('minimumSupportedVersion defaults to null', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.minimumSupportedVersion, isNull);
    });

    test('config defaults to null', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.config, isNull);
    });

    test('lastFetchTime defaults to null', () {
      AppConfigService.resetForTest();
      expect(AppConfigService.lastFetchTime, isNull);
    });
  });
}

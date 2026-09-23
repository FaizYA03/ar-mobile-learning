import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/app_config_service.dart';

void main() {
  setUp(() {
    AppConfigService.resetForTest();
  });

  testWidgets('App renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Startup kini fetch config publik (real network) — jalankan
    // dalam zona async nyata agar tidak ada timer fake yang menggantung.
    await tester.runAsync(() async {
      await tester.pumpWidget(const ARMobileLearningApp());
      await tester.pump();
    });
    expect(find.byType(ARMobileLearningApp), findsOneWidget);
  });
}

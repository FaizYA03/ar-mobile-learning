import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/info_screen.dart';
import 'package:frontend/services/app_config_service.dart';

void main() {
  setUp(() {
    AppConfigService.resetForTest();
  });

  group('InfoScreen.waUrl', () {
    test('builds wa.me link from plain number', () {
      expect(InfoScreen.waUrl('6281234567890'), 'https://wa.me/6281234567890');
    });

    test('strips non-digit characters', () {
      expect(
          InfoScreen.waUrl('+62 812-3456-7890'), 'https://wa.me/6281234567890');
    });
  });

  group('InfoScreen widget', () {
    testWidgets('renders Bantuan with fallback text when offline',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InfoScreen.help()));
      expect(find.text('Bantuan'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsNothing);
    });

    testWidgets('renders Tentang title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InfoScreen.about()));
      expect(find.text('Tentang'), findsOneWidget);
    });
  });
}

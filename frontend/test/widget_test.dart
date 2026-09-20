import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ARMobileLearningApp());
    await tester.pump();
    expect(find.byType(ARMobileLearningApp), findsOneWidget);
  });
}

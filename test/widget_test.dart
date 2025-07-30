import 'package:flutter_test/flutter_test.dart';

import 'package:pinkycash_app/main.dart';

void main() {
  testWidgets('PinkyCash app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CuteMoneyTrackerApp());

    // Verify that the app starts correctly
    expect(find.text('Halo Cantik! 💕'), findsOneWidget);
  });
}
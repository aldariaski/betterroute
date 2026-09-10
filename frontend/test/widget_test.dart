import 'package:flutter_test/flutter_test.dart';

import 'package:betterroute/main.dart';

void main() {
  testWidgets('BetterRoute app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BetterRouteApp());

    expect(find.text('BetterRoute'), findsOneWidget);
  });
}
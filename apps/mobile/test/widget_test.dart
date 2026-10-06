import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('mobile shell shows dashboard and core tabs (no capture)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MobileApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Capture'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Words'), findsWidgets);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}

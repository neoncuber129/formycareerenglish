import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: shell and vocabulary tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Words'), findsOneWidget);
    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();

    expect(find.text('Vocabulary'), findsOneWidget);
  });
}

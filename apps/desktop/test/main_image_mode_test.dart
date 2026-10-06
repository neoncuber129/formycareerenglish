import 'package:desktop/core/hotkey/hotkey_provider.dart';
import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/capture/presentation/capture_popup.dart';
import 'package:desktop/features/capture/presentation/desktop_capture_intents.dart';
import 'package:desktop/features/capture/presentation/region_selector_overlay.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:desktop/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _actionsMapsDesktopCaptureImageIntent(Widget widget) {
  return widget is Actions &&
      widget.actions.containsKey(DesktopCaptureImageIntent);
}

class _FakeHotkeyService implements HotkeyService {
  _FakeHotkeyService();

  @override
  Stream<HotkeyPressEvent> get onHotkeyPressed =>
      const Stream<HotkeyPressEvent>.empty();

  @override
  HotkeyDiagnostics get diagnostics => const HotkeyDiagnostics(
        isSupported: true,
        isEventBridgeConnected: true,
        registeredIds: <int>[],
        lastError: null,
      );

  @override
  Future<bool> registerHotkey(HotkeyBinding binding) async => true;

  @override
  Future<void> unregisterAll() async {}

  @override
  Future<void> unregisterHotkey(int id) async {}
}

class _FakeVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getAllVocab() async => <Vocab>[];

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async => <Vocab>[];

  @override
  Future<void> saveVocab(Vocab vocab) async {}

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> updateReviewProgress(Vocab vocab) async {}

  @override
  Future<List<Vocab>> getTrashedVocab() async => const <Vocab>[];

  @override
  Future<void> updateVocabsBulk(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {}

  @override
  Future<void> deleteVocabsBulk(List<String> ids) async {}

  @override
  Future<void> resetSrsBulk(List<String> ids) async {}

  @override
  Future<void> renameTagAcrossVocabs(String oldTag, String newTag) async {}

  @override
  Future<void> deleteTagAcrossVocabs(String tag) async {}
}

class _FakeSyncService extends SyncService {
  _FakeSyncService() : super(_FakeVocabRepository());

  @override
  Future<void> syncNow() async {}
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('image capture intent opens selector and ESC cancels safely', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hotkeyServiceProvider.overrideWithValue(_FakeHotkeyService()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
        ],
        child: const DesktopApp(),
      ),
    );
    await tester.pumpAndSettle();

    final capturePaneKey = find.byKey(const ValueKey<String>('pane_capture'));
    await tester.tap(capturePaneKey);
    await tester.pumpAndSettle();

    final shortcutsFinder = find.descendant(
      of: find.byType(DesktopHomePage),
      matching: find.byType(Shortcuts),
    );
    expect(shortcutsFinder, findsOneWidget);
    final actionsFinder = find.descendant(
      of: shortcutsFinder,
      matching: find.byWidgetPredicate(_actionsMapsDesktopCaptureImageIntent),
    );
    expect(actionsFinder, findsOneWidget);
    final belowActions = find.descendant(
      of: actionsFinder,
      matching: find.byType(Listener),
    );
    expect(belowActions, findsWidgets);
    Actions.invoke<DesktopCaptureImageIntent>(
      tester.element(belowActions.first),
      const DesktopCaptureImageIntent(),
    );
    await tester.pump();

    expect(find.byType(RegionSelectorOverlay), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(RegionSelectorOverlay), findsNothing);
    expect(find.byType(CapturePopup), findsNothing);
  });
}

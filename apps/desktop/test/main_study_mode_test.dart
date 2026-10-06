import 'dart:async';

import 'package:desktop/core/hotkey/hotkey_provider.dart';
import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/capture/presentation/capture_dashboard_page.dart';
import 'package:desktop/features/capture/presentation/capture_popup.dart';
import 'package:desktop/features/capture/presentation/desktop_capture_intents.dart';
import 'package:desktop/features/dashboard/presentation/dashboard_home_screen.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:desktop/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _actionsMapsDesktopCaptureTextIntent(Widget widget) {
  return widget is Actions &&
      widget.actions.containsKey(DesktopCaptureTextIntent);
}

class _FakeHotkeyService implements HotkeyService {
  _FakeHotkeyService();

  final StreamController<HotkeyPressEvent> _events =
      StreamController<HotkeyPressEvent>.broadcast();

  @override
  Stream<HotkeyPressEvent> get onHotkeyPressed => _events.stream;

  @override
  HotkeyDiagnostics get diagnostics => const HotkeyDiagnostics(
    isSupported: true,
    isEventBridgeConnected: true,
    registeredIds: <int>[1001, 1002],
    lastError: null,
  );

  @override
  Future<bool> registerHotkey(HotkeyBinding binding) async => true;

  @override
  Future<void> unregisterAll() async {}

  @override
  Future<void> unregisterHotkey(int id) async {}

  Future<void> dispose() async => _events.close();
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

  testWidgets('Capture tab shows Auto capture (no study mode gate)', (
    WidgetTester tester,
  ) async {
    final fakeHotkey = _FakeHotkeyService();
    addTearDown(() async => fakeHotkey.dispose());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hotkeyServiceProvider.overrideWithValue(fakeHotkey),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
        ],
        child: const DesktopApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardHomeScreen), findsOneWidget);

    final capturePaneKey = find.byKey(const ValueKey<String>('pane_capture'));
    expect(capturePaneKey, findsOneWidget);
    await tester.tap(capturePaneKey);
    await tester.pumpAndSettle();

    expect(find.byType(CaptureDashboardPage), findsOneWidget);
    expect(find.text('Auto capture'), findsOneWidget);
  });

  testWidgets('desktop capture intent opens capture popup', (
    WidgetTester tester,
  ) async {
    final fakeHotkey = _FakeHotkeyService();
    addTearDown(() async => fakeHotkey.dispose());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hotkeyServiceProvider.overrideWithValue(fakeHotkey),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
        ],
        child: const DesktopApp(),
      ),
    );
    await tester.pumpAndSettle();

    final shortcutsFinder = find.descendant(
      of: find.byType(DesktopHomePage),
      matching: find.byType(Shortcuts),
    );
    expect(shortcutsFinder, findsOneWidget);
    final actionsFinder = find.descendant(
      of: shortcutsFinder,
      matching: find.byWidgetPredicate(_actionsMapsDesktopCaptureTextIntent),
    );
    expect(actionsFinder, findsOneWidget);
    final belowActions = find.descendant(
      of: actionsFinder,
      matching: find.byType(Listener),
    );
    expect(belowActions, findsWidgets);
    Actions.invoke<DesktopCaptureTextIntent>(
      tester.element(belowActions.first),
      const DesktopCaptureTextIntent(),
    );
    await tester.pump();
    // CapturePopup shell may animate indefinitely; avoid pumpAndSettle here.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CapturePopup), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:desktop/core/hotkey/hotkey_provider.dart';
import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:desktop/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('desktop home renders', (WidgetTester tester) async {
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
    expect(capturePaneKey, findsOneWidget);
    await tester.tap(capturePaneKey);
    await tester.pumpAndSettle();

    expect(find.text('Text from selection'), findsOneWidget);
    expect(find.text('Image / region OCR'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:desktop/core/hotkey/hotkey_provider.dart';
import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:desktop/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHotkeyService implements HotkeyService {
  _FakeHotkeyService({required this.registerResult});

  final bool registerResult;
  int unregisterAllCalls = 0;

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
  Future<bool> registerHotkey(HotkeyBinding binding) async => registerResult;

  @override
  Future<void> unregisterAll() async {
    unregisterAllCalls += 1;
  }

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

  testWidgets('shows fallback hint when global hotkey registration fails', (
    WidgetTester tester,
  ) async {
    final fakeHotkey = _FakeHotkeyService(registerResult: false);
    final container = ProviderContainer(
      overrides: [
        hotkeyServiceProvider.overrideWithValue(fakeHotkey),
        syncServiceProvider.overrideWithValue(_FakeSyncService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DesktopApp(),
      ),
    );
    await tester.pumpAndSettle();

    final capturePaneKey = find.byKey(const ValueKey<String>('pane_capture'));
    await tester.tap(capturePaneKey);
    await tester.pumpAndSettle();

    expect(find.textContaining('Global hotkey unavailable'), findsOneWidget);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected index for [MobileShell] bottom navigation / [IndexedStack].
final mobileShellTabIndexProvider =
    NotifierProvider<MobileShellTabIndexNotifier, int>(
  MobileShellTabIndexNotifier.new,
);

class MobileShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected vocabulary ids for bulk actions (multi-select UI).
final vocabSelectionProvider =
    NotifierProvider<VocabSelection, Set<String>>(VocabSelection.new);

class VocabSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (!next.remove(id)) {
      next.add(id);
    }
    state = next;
  }

  void selectAll(Iterable<String> ids) {
    state = Set<String>.from(ids);
  }

  void clear() {
    state = <String>{};
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected vocabulary ids + anchor row for Shift+range selection (desktop library UI).
final vocabSelectionProvider =
    NotifierProvider<VocabSelection, VocabSelectionState>(VocabSelection.new);

@immutable
class VocabSelectionState {
  const VocabSelectionState({
    this.selectedIds = const <String>{},
    this.anchorId,
  });

  final Set<String> selectedIds;
  final String? anchorId;

  int get count => selectedIds.length;

  bool get isEmpty => selectedIds.isEmpty;

  bool contains(String id) => selectedIds.contains(id);
}

class VocabSelection extends Notifier<VocabSelectionState> {
  @override
  VocabSelectionState build() => const VocabSelectionState();

  void toggle(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (!next.remove(id)) {
      next.add(id);
    }
    state = VocabSelectionState(selectedIds: next, anchorId: id);
  }

  void selectAll(Iterable<String> ids) {
    final list = ids.toList();
    state = VocabSelectionState(
      selectedIds: Set<String>.from(ids),
      anchorId: list.isEmpty ? null : list.first,
    );
  }

  void clear() {
    state = const VocabSelectionState();
  }

  /// Single row selection (e.g. row tap without Shift, or context-menu focus row).
  void selectSingle(String id) {
    state = VocabSelectionState(selectedIds: <String>{id}, anchorId: id);
  }

  /// Row primary tap: Shift extends range from [anchorId]; otherwise replaces selection.
  void onRowTap(
    String id, {
    required bool shift,
    required List<String> orderedVisibleIds,
  }) {
    if (shift && state.anchorId != null) {
      final a = orderedVisibleIds.indexOf(state.anchorId!);
      final b = orderedVisibleIds.indexOf(id);
      if (a == -1 || b == -1) {
        state = VocabSelectionState(selectedIds: <String>{id}, anchorId: id);
        return;
      }
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      final range = orderedVisibleIds.sublist(lo, hi + 1).toSet();
      state = VocabSelectionState(
        selectedIds: range,
        anchorId: state.anchorId,
      );
      return;
    }
    state = VocabSelectionState(selectedIds: <String>{id}, anchorId: id);
  }
}

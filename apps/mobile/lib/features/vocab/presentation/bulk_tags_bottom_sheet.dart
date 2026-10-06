import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/presentation/safe_dialog.dart';

/// Bottom sheet: pick one tag (radio) to apply to the current selection.
class BulkTagsBottomSheet extends StatefulWidget {
  const BulkTagsBottomSheet({
    super.key,
    required this.allVocabs,
    required this.selectedIds,
    required this.onApply,
    required this.onRenameTag,
    required this.onDeleteTag,
  });

  final List<Vocab> allVocabs;
  final Set<String> selectedIds;
  final Future<void> Function(Map<String, bool?> states) onApply;
  final Future<void> Function(String oldTag, String newTag) onRenameTag;
  final Future<void> Function(String tag) onDeleteTag;

  @override
  State<BulkTagsBottomSheet> createState() => _BulkTagsBottomSheetState();
}

class _BulkTagsBottomSheetState extends State<BulkTagsBottomSheet> {
  late final TextEditingController _search;
  late Map<String, bool?> _tagStates;
  late List<String> _allTagsSorted;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController()..addListener(() => setState(() {}));
    _allTagsSorted = _collectTags(widget.allVocabs);
    _tagStates = _initialStates(
      widget.allVocabs,
      widget.selectedIds,
      _allTagsSorted,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static List<String> _collectTags(List<Vocab> items) {
    final set = <String>{};
    for (final v in items) {
      for (final t in v.tags) {
        final x = t.trim();
        if (x.isNotEmpty) set.add(x);
      }
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static Map<String, bool?> _initialStates(
    List<Vocab> allVocabs,
    Set<String> selectedIds,
    List<String> allTags,
  ) {
    final selected =
        allVocabs.where((v) => selectedIds.contains(v.id)).toList();
    final map = <String, bool?>{};
    if (selected.isEmpty) {
      for (final t in allTags) {
        map[t] = false;
      }
      return map;
    }
    final n = selected.length;
    for (final tag in allTags) {
      final count = selected.where((v) => v.tags.contains(tag)).length;
      if (count == 0) {
        map[tag] = false;
      } else if (count == n) {
        map[tag] = true;
      } else {
        map[tag] = null;
      }
    }
    return map;
  }

  List<String> get _filteredTags {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _allTagsSorted;
    return _allTagsSorted
        .where((t) => t.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _createTag() async {
    await unfocusForIncomingDialog();
    if (!mounted) return;
    final input = await showSafeSingleLineInputDialog(
      context,
      title: 'New tag',
      labelText: 'Tag name',
      initialValue: '',
      confirmLabel: 'Add',
      cancelLabel: 'Cancel',
    );
    if (!mounted) return;
    final newTag = (input ?? '').trim();
    if (newTag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag name cannot be empty.')),
      );
      return;
    }
    if (_allTagsSorted.any((t) => t.toLowerCase() == newTag.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag already exists.')),
      );
      return;
    }
    setState(() {
      _allTagsSorted = <String>[..._allTagsSorted, newTag]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (final t in _allTagsSorted) {
        _tagStates.putIfAbsent(t, () => false);
      }
      for (final key in _allTagsSorted) {
        _tagStates[key] = false;
      }
      _tagStates[newTag] = true;
    });
  }

  Future<void> _renameTag(String oldTag) async {
    await unfocusForIncomingDialog();
    if (!mounted) return;
    final next = await showSafeSingleLineInputDialog(
      context,
      title: 'Rename tag',
      labelText: 'New name',
      initialValue: oldTag,
      confirmLabel: 'Save',
      cancelLabel: 'Cancel',
    );
    if (!mounted) return;
    final trimmed = (next ?? '').trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag name cannot be empty.')),
      );
      return;
    }
    if (trimmed.toLowerCase() == oldTag.toLowerCase()) return;
    if (_allTagsSorted.any(
      (t) =>
          t.toLowerCase() == trimmed.toLowerCase() &&
          t.toLowerCase() != oldTag.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag already exists.')),
      );
      return;
    }
    setState(() => _applying = true);
    try {
      await widget.onRenameTag(oldTag, trimmed);
      if (!mounted) return;
      final replaced = _allTagsSorted
          .map((t) => t.toLowerCase() == oldTag.toLowerCase() ? trimmed : t)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final nextStates = <String, bool?>{};
      for (final tag in replaced) {
        if (tag.toLowerCase() == trimmed.toLowerCase()) {
          nextStates[tag] = _tagStates[oldTag] ?? false;
        } else {
          nextStates[tag] = _tagStates[tag] ?? false;
        }
      }
      setState(() {
        _allTagsSorted = replaced;
        _tagStates = nextStates;
      });
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _deleteTagGlobally(String tag) async {
    await unfocusForIncomingDialog();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete tag'),
        content: Text('Remove “$tag” from all saved words?'),
        actions: [
          TextButton(
            onPressed: () => safeNavigatorPop<bool>(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => safeNavigatorPop<bool>(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _applying = true);
    try {
      await widget.onDeleteTag(tag);
      if (!mounted) return;
      setState(() {
        _allTagsSorted = _allTagsSorted
            .where((t) => t.toLowerCase() != tag.toLowerCase())
            .toList(growable: false);
        _tagStates.removeWhere((k, _) => k.toLowerCase() == tag.toLowerCase());
      });
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _onApply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(Map<String, bool?>.from(_tagStates));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.58;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bulk tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _applying ? null : _createTag,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            if (_allTagsSorted.isNotEmpty && _search.text.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _applying
                        ? null
                        : () => setState(() {
                              for (final t in _allTagsSorted) {
                                _tagStates[t] = false;
                              }
                            }),
                    child: const Text('Clear tag selection'),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filter tags',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: _filteredTags.isEmpty
                  ? Center(
                      child: Text(
                        _allTagsSorted.isEmpty
                            ? 'No tags in library yet.'
                            : 'No tags match filter.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];
                        final selected = _tagStates[tag] == true;
                        return ListTile(
                          dense: true,
                          title: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          trailing: PopupMenuButton<String>(
                            enabled: !_applying,
                            icon: const Icon(Icons.more_vert),
                            onSelected: (choice) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (choice == 'rename') {
                                  unawaited(_renameTag(tag));
                                } else {
                                  unawaited(_deleteTagGlobally(tag));
                                }
                              });
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename everywhere'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete everywhere'),
                              ),
                            ],
                          ),
                          onTap: _applying
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      _tagStates[tag] = false;
                                      return;
                                    }
                                    for (final k in _allTagsSorted) {
                                      _tagStates[k] = false;
                                    }
                                    _tagStates[tag] = true;
                                  });
                                },
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed:
                        _applying ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _applying
                        ? null
                        : () async {
                            await _onApply();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: _applying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

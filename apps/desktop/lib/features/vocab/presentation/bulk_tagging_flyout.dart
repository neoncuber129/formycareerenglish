import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:shared_models/shared_models.dart';

/// Win11-style flyout for bulk-editing tags on the current selection.
class BulkTaggingFlyout extends StatefulWidget {
  const BulkTaggingFlyout({
    super.key,
    required this.allVocabs,
    required this.selectedIds,
    required this.onApply,
    required this.onRenameTag,
    required this.onDeleteTag,
    required this.onClose,
  });

  final List<Vocab> allVocabs;
  final Set<String> selectedIds;
  final Future<void> Function(Map<String, bool?> tagStates) onApply;
  final Future<void> Function(String oldTag, String newTag) onRenameTag;
  final Future<void> Function(String tag) onDeleteTag;
  final VoidCallback onClose;

  /// Opens as a [showGeneralDialog] route (stable over parent rebuilds / list reload).
  static Future<void> show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required List<Vocab> allVocabs,
    required Set<String> selectedIds,
    required Future<void> Function(Map<String, bool?> tagStates) onApply,
    required Future<void> Function(String oldTag, String newTag) onRenameTag,
    required Future<void> Function(String tag) onDeleteTag,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x00000000),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _BulkTaggingFlyoutHost(
          anchorKey: anchorKey,
          allVocabs: allVocabs,
          selectedIds: selectedIds,
          onApply: onApply,
          onRenameTag: onRenameTag,
          onDeleteTag: onDeleteTag,
        );
      },
    );
  }

  @override
  State<BulkTaggingFlyout> createState() => _BulkTaggingFlyoutState();
}

class _BulkTaggingFlyoutHost extends StatefulWidget {
  const _BulkTaggingFlyoutHost({
    required this.anchorKey,
    required this.allVocabs,
    required this.selectedIds,
    required this.onApply,
    required this.onRenameTag,
    required this.onDeleteTag,
  });

  final GlobalKey anchorKey;
  final List<Vocab> allVocabs;
  final Set<String> selectedIds;
  final Future<void> Function(Map<String, bool?> tagStates) onApply;
  final Future<void> Function(String oldTag, String newTag) onRenameTag;
  final Future<void> Function(String tag) onDeleteTag;

  @override
  State<_BulkTaggingFlyoutHost> createState() => _BulkTaggingFlyoutHostState();
}

class _BulkTaggingFlyoutHostState extends State<_BulkTaggingFlyoutHost> {
  static const double _flyoutWidth = 300;
  static const int _maxAnchorResolveAttempts = 24;

  final GlobalKey _panelKey = GlobalKey();
  double _left = 0;
  double _top = 0;
  var _allowOutsideDismiss = false;
  var _anchorResolveAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePositionUpdate();
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _allowOutsideDismiss = true);
        }
      });
    });
  }

  void _schedulePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final anchorCtx = widget.anchorKey.currentContext;
      if (anchorCtx == null) {
        _anchorResolveAttempts++;
        if (_anchorResolveAttempts >= _maxAnchorResolveAttempts) {
          Navigator.of(context).pop();
          return;
        }
        _schedulePositionUpdate();
        return;
      }
      _anchorResolveAttempts = 0;
      final box = anchorCtx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        _schedulePositionUpdate();
        return;
      }
      final media = MediaQuery.sizeOf(context);
      final origin = box.localToGlobal(Offset.zero);
      final sz = box.size;
      final panelBox =
          _panelKey.currentContext?.findRenderObject() as RenderBox?;
      final panelHeight = (panelBox != null && panelBox.hasSize)
          ? panelBox.size.height
          : 360.0;
      const gap = 6.0;
      var left = origin.dx + sz.width - _flyoutWidth;
      final belowTop = origin.dy + sz.height + gap;
      final aboveTop = origin.dy - panelHeight - gap;
      left = left.clamp(8.0, media.width - _flyoutWidth - 8.0).toDouble();
      final maxTop = (media.height - panelHeight - 8.0).clamp(
        8.0,
        media.height,
      );
      final preferredTop = belowTop <= maxTop ? belowTop : aboveTop;
      final top = preferredTop.clamp(8.0, maxTop).toDouble();
      setState(() {
        _left = left;
        _top = top;
      });
    });
  }

  void _maybeDismissFromPointer(Offset globalPosition) {
    if (!_allowOutsideDismiss) {
      return;
    }
    final panelCtx = _panelKey.currentContext;
    if (panelCtx == null) {
      Navigator.of(context).pop();
      return;
    }
    final panelBox = panelCtx.findRenderObject() as RenderBox?;
    if (panelBox == null || !panelBox.hasSize) {
      return;
    }
    final panelRect = panelBox.localToGlobal(Offset.zero) & panelBox.size;
    if (panelRect.contains(globalPosition)) {
      return;
    }
    final anchorCtx = widget.anchorKey.currentContext;
    if (anchorCtx != null) {
      final ab = anchorCtx.findRenderObject() as RenderBox?;
      if (ab != null && ab.hasSize) {
        final anchorRect = ab.localToGlobal(Offset.zero) & ab.size;
        if (anchorRect.contains(globalPosition)) {
          return;
        }
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _DismissFlyoutIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DismissFlyoutIntent: CallbackAction<_DismissFlyoutIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) {
                        _maybeDismissFromPointer(e.position);
                      },
                      child: const ColoredBox(color: Color(0x00000000)),
                    ),
                  ),
                  Positioned(
                    left: _left,
                    top: _top,
                    width: _flyoutWidth,
                    child: KeyedSubtree(
                      key: _panelKey,
                      child: BulkTaggingFlyout(
                        allVocabs: widget.allVocabs,
                        selectedIds: widget.selectedIds,
                        onApply: (states) async {
                          try {
                            await widget.onApply(states);
                          } finally {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        onRenameTag: widget.onRenameTag,
                        onDeleteTag: widget.onDeleteTag,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DismissFlyoutIntent extends Intent {
  const _DismissFlyoutIntent();
}

class _BulkTaggingFlyoutState extends State<BulkTaggingFlyout> {
  late final TextEditingController _search;
  late final ScrollController _listScrollController;
  late Map<String, bool?> _tagStates;
  late List<String> _allTagsSorted;
  var _applying = false;

  void _showHint(String text) {
    if (!mounted) {
      return;
    }
    unawaited(
      fluent.displayInfoBar(
        context,
        duration: const Duration(milliseconds: 1400),
        builder: (context, close) => fluent.InfoBar(
          title: Text(text),
          severity: fluent.InfoBarSeverity.info,
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    try {
      final input = await fluent.showDialog<String>(
        context: context,
        builder: (dialogContext) => fluent.ContentDialog(
          title: Text(l10n.bulkTagCreateTitle),
          content: fluent.TextBox(
            controller: controller,
            autofocus: true,
            placeholder: l10n.bulkTagCreatePlaceholder,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            fluent.FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.commonCreate),
            ),
          ],
        ),
      );
      final newTag = (input ?? '').trim();
      if (newTag.isEmpty) {
        _showHint(l10n.bulkTagValidationEmpty);
        return;
      }
      if (_allTagsSorted.any(
        (tag) => tag.toLowerCase() == newTag.toLowerCase(),
      )) {
        _showHint(l10n.bulkTagValidationDuplicate);
        return;
      }
      setState(() {
        _allTagsSorted = <String>[..._allTagsSorted, newTag]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        for (final tag in _allTagsSorted) {
          _tagStates[tag] = false;
        }
        _tagStates[newTag] = true;
      });
    } finally {
      controller.dispose();
    }
  }

  Future<void> _renameTag(String oldTag) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: oldTag);
    try {
      final nextTag = await fluent.showDialog<String>(
        context: context,
        builder: (dialogContext) => fluent.ContentDialog(
          title: Text(l10n.bulkTagRenameTitle),
          content: fluent.TextBox(
            controller: controller,
            autofocus: true,
            placeholder: l10n.bulkTagRenamePlaceholder,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            fluent.FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      );
      final trimmed = (nextTag ?? '').trim();
      if (trimmed.isEmpty) {
        _showHint(l10n.bulkTagValidationEmpty);
        return;
      }
      if (trimmed.toLowerCase() == oldTag.toLowerCase()) {
        return;
      }
      if (_allTagsSorted.any(
        (tag) =>
            tag.toLowerCase() == trimmed.toLowerCase() &&
            tag.toLowerCase() != oldTag.toLowerCase(),
      )) {
        _showHint(l10n.bulkTagValidationDuplicate);
        return;
      }
      setState(() => _applying = true);
      try {
        await widget.onRenameTag(oldTag, trimmed);
        final replaced =
            _allTagsSorted
                .map(
                  (tag) =>
                      tag.toLowerCase() == oldTag.toLowerCase() ? trimmed : tag,
                )
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
        if (mounted) {
          setState(() {
            _allTagsSorted = replaced;
            _tagStates = nextStates;
          });
        }
      } finally {
        if (mounted) {
          setState(() => _applying = false);
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteTag(String tag) async {
    final l10n = context.l10n;
    final confirmed = await fluent.showDialog<bool>(
      context: context,
      builder: (dialogContext) => fluent.ContentDialog(
        title: Text(l10n.bulkTagDeleteTitle),
        content: Text(l10n.bulkTagDeleteBody(tag)),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          fluent.FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _applying = true);
    try {
      await widget.onDeleteTag(tag);
      if (!mounted) {
        return;
      }
      setState(() {
        _allTagsSorted = _allTagsSorted
            .where((value) => value.toLowerCase() != tag.toLowerCase())
            .toList(growable: false);
        _tagStates.removeWhere(
          (key, value) => key.toLowerCase() == tag.toLowerCase(),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _listScrollController = ScrollController();
    _search.addListener(() => setState(() {}));
    _allTagsSorted = _collectTags(widget.allVocabs);
    _tagStates = _initialStates(
      widget.allVocabs,
      widget.selectedIds,
      _allTagsSorted,
    );
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  static List<String> _collectTags(List<Vocab> items) {
    final set = <String>{};
    for (final v in items) {
      set.addAll(v.tags);
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
    final selected = allVocabs
        .where((v) => selectedIds.contains(v.id))
        .toList();
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
    if (q.isEmpty) {
      return _allTagsSorted;
    }
    return _allTagsSorted.where((t) => t.toLowerCase().contains(q)).toList();
  }

  Future<void> _onApply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(Map<String, bool?>.from(_tagStates));
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fluentTheme = fluent.FluentTheme.of(context);
    final resources = fluentTheme.resources;
    final cardBg = resources.cardBackgroundFillColorDefault.withAlpha(255);
    final controlBg = resources.controlFillColorSecondary.withAlpha(255);
    final controlStroke = resources.controlStrokeColorDefault;

    return Material(
      color: const Color(0x00000000),
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 360),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            surfaceTintColor: Colors.transparent,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: controlStroke.withValues(alpha: 0.8),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.bulkTagPanelTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      fluent.Button(
                        onPressed: _applying ? null : _createTag,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: 6),
                            Text(l10n.bulkTagNewBadge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_allTagsSorted.isNotEmpty && _search.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: fluent.Button(
                        onPressed: _applying
                            ? null
                            : () {
                                setState(() {
                                  for (final tag in _allTagsSorted) {
                                    _tagStates[tag] = false;
                                  }
                                });
                              },
                        child: Text(l10n.bulkTagClearSelections),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: fluent.TextBox(
                    controller: _search,
                    placeholder: l10n.bulkTagFilterPlaceholder,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8, right: 4),
                      child: Icon(Icons.search, size: 18),
                    ),
                    suffix: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                    style: theme.textTheme.bodyMedium,
                    decoration: WidgetStatePropertyAll(
                      BoxDecoration(
                        color: controlBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: controlStroke),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredTags.isEmpty
                      ? Center(
                          child: Text(
                            _allTagsSorted.isEmpty
                                ? l10n.bulkTagEmptyLibrary
                                : l10n.bulkTagNoMatchFilter,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: fluentTheme.inactiveColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Scrollbar(
                          controller: _listScrollController,
                          // Avoid frame-timing assertion when flyout just opened
                          // and the ListView has not attached a ScrollPosition yet.
                          thumbVisibility: false,
                          child: ListView.builder(
                            controller: _listScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = _filteredTags[index];
                              final selected = _tagStates[tag] == true;
                              return Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: _applying
                                          ? null
                                          : () {
                                              setState(() {
                                                if (selected) {
                                                  _tagStates[tag] = false;
                                                  return;
                                                }
                                                for (final key
                                                    in _allTagsSorted) {
                                                  _tagStates[key] = false;
                                                }
                                                _tagStates[tag] = true;
                                              });
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tag,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              selected
                                                  ? Icons.check_circle_rounded
                                                  : Icons.circle_outlined,
                                              size: 18,
                                              color: selected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: l10n.bulkTagManageTooltip,
                                    enabled: !_applying,
                                    onSelected: (choice) {
                                      if (choice == 'rename') {
                                        _renameTag(tag);
                                        return;
                                      }
                                      _deleteTag(tag);
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem<String>(
                                        value: 'rename',
                                        child: Text(l10n.bulkTagRename),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text(l10n.bulkTagDelete),
                                      ),
                                    ],
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      fluent.Button(
                        onPressed: _applying ? null : widget.onClose,
                        child: Text(l10n.commonCancel),
                      ),
                      const Spacer(),
                      fluent.FilledButton(
                        onPressed: _applying ? null : _onApply,
                        child: _applying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.bulkTagApply),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

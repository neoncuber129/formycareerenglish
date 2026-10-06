import 'package:app_l10n/app_l10n.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:shared_models/shared_models.dart';

import 'vocab_selection_provider.dart';

const double _kRowExtent = 62;

enum VocabRowContextAction { tag, archive, resetSrs, delete }

typedef VocabRowContextCallback = void Function(VocabRowContextAction action);

/// Virtualized table-like list (fixed row height) with multi-select and native context menu.
class VocabTableView extends ConsumerWidget {
  const VocabTableView({super.key, required this.items, this.onContextCommand});

  final List<Vocab> items;
  final VocabRowContextCallback? onContextCommand;

  bool _shiftDown() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orderedIds = items.map((e) => e.id).toList();
    final selection = ref.watch(vocabSelectionProvider);
    final notifier = ref.read(vocabSelectionProvider.notifier);
    final theme = Theme.of(context);
    final allSelected =
        items.isNotEmpty &&
        selection.selectedIds.length == items.length &&
        items.every((v) => selection.contains(v.id));

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          notifier.selectAll(orderedIds);
        },
        const SingleActivator(LogicalKeyboardKey.escape): notifier.clear,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeader(
              theme: theme,
              l10n: l10n,
              allSelected: allSelected,
              someSelected: selection.selectedIds.isNotEmpty && !allSelected,
              onHeaderCheckbox: () {
                if (allSelected) {
                  notifier.clear();
                } else {
                  notifier.selectAll(orderedIds);
                }
              },
            ),
            Expanded(
              child: fluent.Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: items.length,
                  itemExtent: _kRowExtent,
                  itemBuilder: (context, index) {
                    final v = items[index];
                    final checked = selection.contains(v.id);
                    final res = fluent.FluentTheme.of(context).resources;
                    return ncm.ContextMenuRegion(
                      menuItems: [
                        ncm.MenuItem(
                          title: l10n.vocabCtxMenuTag,
                          action: VocabRowContextAction.tag,
                        ),
                        ncm.MenuItem(
                          title: l10n.vocabCtxMenuArchive,
                          action: VocabRowContextAction.archive,
                        ),
                        ncm.MenuItem(
                          title: l10n.vocabCtxMenuResetSrs,
                          action: VocabRowContextAction.resetSrs,
                        ),
                        ncm.MenuItem(
                          title: l10n.vocabCtxMenuDelete,
                          action: VocabRowContextAction.delete,
                        ),
                      ],
                      onItemSelected: (item) {
                        final action = item.action;
                        if (action is VocabRowContextAction) {
                          onContextCommand?.call(action);
                        }
                      },
                      child: GestureDetector(
                        onSecondaryTapDown: (_) {
                          if (!selection.contains(v.id)) {
                            notifier.selectSingle(v.id);
                          }
                        },
                        child: fluent.HoverButton(
                          cursor: SystemMouseCursors.click,
                          onPressed: () {
                            notifier.onRowTap(
                              v.id,
                              shift: _shiftDown(),
                              orderedVisibleIds: orderedIds,
                            );
                          },
                          builder: (ctx, states) {
                            final hovered = states.contains(
                              fluent.WidgetState.hovered,
                            );
                            final baseFill = res.cardBackgroundFillColorDefault;
                            final selectedAlpha =
                                theme.brightness == Brightness.dark
                                ? 0.42
                                : 0.28;
                            final rowColor = checked
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: selectedAlpha,
                                  )
                                : hovered
                                ? res.subtleFillColorSecondary
                                : baseFill;
                            return ColoredBox(
                              color: rowColor,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Center(
                                      child: fluent.Checkbox(
                                        checked: checked,
                                        onChanged: (_) => notifier.toggle(v.id),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            v.sourceText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                          ),
                                          if (v.translatedText.trim().isNotEmpty)
                                            Text(
                                              v.translatedText.trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 12,
                                                    color: checked
                                                        ? theme
                                                              .colorScheme
                                                              .onSurface
                                                        : theme.colorScheme
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                alpha:
                                                                    theme.brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? 0.96
                                                                    : 0.9,
                                                              ),
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _SourceMetaCell(
                                      vocab: v,
                                      theme: theme,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: _TagsChips(
                                        tags: v.tags,
                                        theme: theme,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Text(
                                        _formatDate(v.nextReviewAt),
                                        style: theme.textTheme.bodySmall,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FluentTagPill extends StatelessWidget {
  const _FluentTagPill({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final res = fluent.FluentTheme.of(context).resources;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: res.controlFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: res.controlStrokeColorDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.theme,
    required this.l10n,
    required this.allSelected,
    required this.someSelected,
    required this.onHeaderCheckbox,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onHeaderCheckbox;

  @override
  Widget build(BuildContext context) {
    final res = fluent.FluentTheme.of(context).resources;
    return ColoredBox(
      color: res.controlFillColorSecondary,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Center(
                child: fluent.Checkbox(
                  checked: allSelected ? true : (someSelected ? null : false),
                  onChanged: (_) => onHeaderCheckbox(),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l10n.vocabColTermMeaning,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(l10n.vocabColSource, style: theme.textTheme.labelLarge),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l10n.vocabColTags, style: theme.textTheme.labelLarge),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  l10n.vocabColNextReview,
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsChips extends StatelessWidget {
  const _TagsChips({required this.tags, required this.theme});

  final List<String> tags;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    const maxVisible = 2;
    final visible = tags.take(maxVisible).toList();
    final extra = tags.length - visible.length;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          for (final tag in visible) ...[
            Flexible(
              child: _FluentTagPill(text: tag, theme: theme),
            ),
            const SizedBox(width: 4),
          ],
          if (extra > 0)
            Text(
              '+$extra',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _SourceMetaCell extends StatelessWidget {
  const _SourceMetaCell({required this.vocab, required this.theme});

  final Vocab vocab;
  final ThemeData theme;

  String _sourceDomain(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.host.trim().isEmpty) {
      return '';
    }
    final host = parsed.host.trim().toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  @override
  Widget build(BuildContext context) {
    final app = vocab.sourceApp.trim();
    final url = vocab.sourceUrl.trim();
    final domain = _sourceDomain(url);
    final primary = app.isNotEmpty ? app : (domain.isNotEmpty ? domain : '—');
    final secondary = app.isNotEmpty && domain.isNotEmpty ? domain : '';
    final tooltip = [
      if (app.isNotEmpty) app,
      if (url.isNotEmpty) url,
    ].join('\n');
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (secondary.isNotEmpty)
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
            ),
          ),
      ],
    );
    if (tooltip.isEmpty) {
      return content;
    }
    return Tooltip(message: tooltip, child: content);
  }
}

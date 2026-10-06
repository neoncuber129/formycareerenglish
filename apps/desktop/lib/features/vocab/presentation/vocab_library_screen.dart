import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../data/vocab_repository_impl.dart';
import 'bulk_tagging_flyout.dart';
import 'contextual_command_bar.dart';
import 'vocab_list_provider.dart';
import 'vocab_selection_provider.dart';
import '../../review/presentation/custom_study_dialog.dart';
import '../../review/presentation/srs_review_screen.dart';
import '../../settings/application/settings_service.dart';
import 'vocab_google_cloud_tts_panel.dart';
import 'vocab_table_view.dart';

/// Desktop vocabulary library with bulk selection and command bar.
class VocabLibraryScreen extends ConsumerStatefulWidget {
  const VocabLibraryScreen({super.key});

  @override
  ConsumerState<VocabLibraryScreen> createState() => _VocabLibraryScreenState();
}

class _VocabLibraryScreenState extends ConsumerState<VocabLibraryScreen> {
  final GlobalKey _tagButtonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;
  String? _selectedSource;
  String? _selectedLanguage;
  _ArchiveFilter _archiveFilter = _ArchiveFilter.active;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startCustomStudy(Set<String> ids) async {
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select words before studying.'),
        ),
      );
      return;
    }
    final settings = ref.read(settingsServiceProvider);
    final initial = await settings.loadCustomStudyDefaults();
    if (!mounted) {
      return;
    }
    final picked = await showCustomStudyOptionsDialog(
      context,
      initial: initial,
      entryCount: ids.length,
    );
    if (!mounted || picked == null) {
      return;
    }
    await settings.saveCustomStudyDefaults(picked);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      material.MaterialPageRoute<void>(
        builder: (_) => SrsReviewScreen(
          selectedVocabIds: ids,
          customStudyOptions: picked,
        ),
      ),
    );
  }

  Future<void> _runBulk(Future<void> Function(List<String> ids) action) async {
    final ids = ref.read(vocabSelectionProvider).selectedIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await action(ids);
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
  }

  void _openBulkTagFlyout(BuildContext context, List<Vocab> items) {
    final sel = ref.read(vocabSelectionProvider).selectedIds;
    if (sel.isEmpty) {
      return;
    }
    BulkTaggingFlyout.show(
      context: context,
      anchorKey: _tagButtonKey,
      allVocabs: items,
      selectedIds: sel,
      onApply: (states) => _applyBulkTags(states),
      onRenameTag: _renameTagGlobally,
      onDeleteTag: _deleteTagGlobally,
    );
  }

  Future<void> _applyBulkTags(Map<String, bool?> states) async {
    final repo = ref.read(vocabRepositoryProvider);
    final ids = ref.read(vocabSelectionProvider).selectedIds.toList();
    if (ids.isEmpty) {
      return;
    }
    final items = await repo.getAllVocab();
    final byId = {for (final v in items) v.id: v};
    final now = DateTime.now();
    String? selectedTag;
    for (final entry in states.entries) {
      if (entry.value == true) {
        selectedTag = entry.key;
        break;
      }
    }
    for (final id in ids) {
      final v = byId[id];
      if (v == null) {
        continue;
      }
      final nextTags = selectedTag == null
          ? const <String>[]
          : <String>[selectedTag];
      await repo.saveVocab(v.copyWith(tags: nextTags, updatedAt: now));
    }
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
  }

  Future<void> _renameTagGlobally(String oldTag, String newTag) async {
    await ref
        .read(vocabRepositoryProvider)
        .renameTagAcrossVocabs(oldTag, newTag);
    ref.invalidate(vocabListProvider);
  }

  Future<void> _deleteTagGlobally(String tag) async {
    await ref.read(vocabRepositoryProvider).deleteTagAcrossVocabs(tag);
    ref.invalidate(vocabListProvider);
  }

  Future<bool> _confirmDeleteVocabs(BuildContext context) async {
    final selectedCount = ref.read(vocabSelectionProvider).count;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vocabDeleteTitle),
        content: Text(
          selectedCount <= 1
              ? l10n.vocabDeleteBodyOne
              : l10n.vocabDeleteBodyMany(selectedCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedTag = null;
      _selectedSource = null;
      _selectedLanguage = null;
      _archiveFilter = _ArchiveFilter.active;
    });
  }

  Future<void> _showVocabTipsDialog(BuildContext context) {
    final l10n = context.l10n;
    return fluent.showDialog<void>(
      context: context,
      builder: (ctx) => fluent.ContentDialog(
        title: Text(l10n.vocabTipsTitle),
        content: Text(l10n.vocabTipsBody),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  String _sourceDomain(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return '';
    }
    final host = parsed.host.trim().toLowerCase();
    if (host.isEmpty) {
      return '';
    }
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _sourceFacet(Vocab vocab) {
    final app = vocab.sourceApp.trim();
    final domain = _sourceDomain(vocab.sourceUrl);
    if (app.isNotEmpty) {
      return app;
    }
    return domain;
  }

  String _sourceFilterLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.length <= 44) {
      return trimmed;
    }
    return '${trimmed.substring(0, 41)}...';
  }

  List<Vocab> _applyFilters(List<Vocab> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items
        .where((vocab) {
          if (_archiveFilter == _ArchiveFilter.active && vocab.isArchived) {
            return false;
          }
          if (_archiveFilter == _ArchiveFilter.archivedOnly &&
              !vocab.isArchived) {
            return false;
          }
          if (_selectedTag != null &&
              !vocab.tags.any(
                (tag) => tag.toLowerCase() == _selectedTag!.toLowerCase(),
              )) {
            return false;
          }
          if (_selectedSource != null && _selectedSource!.trim().isNotEmpty) {
            final facet = _sourceFacet(vocab).toLowerCase();
            if (facet != _selectedSource!.toLowerCase()) {
              return false;
            }
          }
          if (_selectedLanguage != null &&
              _selectedLanguage!.trim().isNotEmpty) {
            final sourceLang = _sourceLanguageFromPair(vocab.languagePair);
            if (sourceLang != _selectedLanguage!.toLowerCase()) {
              return false;
            }
          }
          if (query.isEmpty) {
            return true;
          }
          final content = [
            vocab.sourceText,
            vocab.translatedText,
            vocab.tags.join(' '),
            vocab.sourceApp,
            _sourceDomain(vocab.sourceUrl),
            vocab.sourceUrl,
          ].join(' ').toLowerCase();
          return content.contains(query);
        })
        .toList(growable: false);
  }

  void _handleContextCommand(
    BuildContext context,
    VocabRowContextAction action,
    List<Vocab> items,
  ) {
    switch (action) {
      case VocabRowContextAction.tag:
        _openBulkTagFlyout(context, items);
        break;
      case VocabRowContextAction.archive:
        unawaited(
          _runBulk((ids) async {
            await ref.read(vocabRepositoryProvider).updateVocabsBulk(
              ids,
              <String, dynamic>{'isArchived': true},
            );
          }),
        );
        break;
      case VocabRowContextAction.resetSrs:
        unawaited(
          _runBulk((ids) async {
            await ref.read(vocabRepositoryProvider).resetSrsBulk(ids);
          }),
        );
        break;
      case VocabRowContextAction.delete:
        unawaited(() async {
          final confirmed = await _confirmDeleteVocabs(context);
          if (!confirmed) {
            return;
          }
          await _runBulk((ids) async {
            await ref.read(vocabRepositoryProvider).deleteVocabsBulk(ids);
          });
        }());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asyncVocabs = ref.watch(vocabListProvider);
    final selection = ref.watch(vocabSelectionProvider);

    final vocabTheme = fluent.FluentTheme.of(context);

    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.navVocabulary),
            const SizedBox(height: 4),
            Text(
              l10n.vocabPageSubtitle,
              style: vocabTheme.typography.caption,
            ),
          ],
        ),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            fluent.Button(
              onPressed: () => _showVocabTipsDialog(context),
              child: Text(l10n.commonTips),
            ),
            const SizedBox(width: 8),
            fluent.Button(
              onPressed: () async {
                final ids = ref
                    .read(vocabSelectionProvider)
                    .selectedIds
                    .toSet();
                await _startCustomStudy(ids);
              },
              child: Text(l10n.vocabStudySelected),
            ),
            const SizedBox(width: 8),
            fluent.Button(
              onPressed: () async {
                final items = await ref.read(vocabListProvider.future);
                if (!context.mounted) {
                  return;
                }
                final ids = _applyFilters(items).map((e) => e.id).toSet();
                if (ids.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.vocabNoMatchFilters)),
                  );
                  return;
                }
                await _startCustomStudy(ids);
              },
              child: Text(l10n.vocabStudyFiltered),
            ),
            const SizedBox(width: 8),
            fluent.Button(
              onPressed: () => ref.invalidate(vocabListProvider),
              child: Text(l10n.commonRefresh),
            ),
          ],
        ),
      ),
      content: Builder(
        builder: (context) {
          final ttsGutter =
              DesktopPaneScrollMetrics.scrollPadding(context).left;
          final ttsPad = Padding(
            padding: EdgeInsets.fromLTRB(ttsGutter, 4, ttsGutter, 4),
            child: const VocabGoogleCloudTtsPanel(),
          );
          return asyncVocabs.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ttsPad,
                const Expanded(
                  child: Center(child: fluent.ProgressRing()),
                ),
              ],
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ttsPad,
                Expanded(
                  child: Center(
                    child: fluent.InfoBar(
                      title: Text(l10n.commonErrorPrefix(e.toString())),
                      severity: fluent.InfoBarSeverity.error,
                    ),
                  ),
                ),
              ],
            ),
            data: (List<Vocab> items) {
          final allTags =
              items
                  .expand((v) => v.tags)
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final filteredItems = _applyFilters(items);
          final allSources =
              items
                  .map(_sourceFacet)
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final allLanguages = items
              .map((v) => _sourceLanguageFromPair(v.languagePair))
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final gutter =
              DesktopPaneScrollMetrics.scrollPadding(context).left;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fluent.FluentTheme.of(
                      context,
                    ).resources.cardBackgroundFillColorDefault,
                    border: Border.all(
                      color: fluent.FluentTheme.of(
                        context,
                      ).resources.controlStrokeColorDefault,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 44),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: fluent.TextBox(
                                        controller: _searchController,
                                        onChanged: (_) => setState(() {}),
                                        placeholder: l10n.vocabSearchPlaceholder,
                                        prefix: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 8,
                                            right: 4,
                                          ),
                                          child: Icon(Icons.search, size: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 150,
                                      child: fluent.ComboBox<String>(
                                        isExpanded: true,
                                        value: _selectedLanguage ?? '__all__',
                                        onChanged: (value) => setState(
                                          () => _selectedLanguage =
                                              (value == null || value == '__all__')
                                              ? null
                                              : value,
                                        ),
                                        items: [
                                          fluent.ComboBoxItem<String>(
                                            value: '__all__',
                                            child: Text(l10n.vocabAllLanguages),
                                          ),
                                          ...allLanguages.map(
                                            (lang) => fluent.ComboBoxItem<String>(
                                              value: lang,
                                              child: Text(lang.toUpperCase()),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: fluent.ComboBox<String>(
                                  isExpanded: true,
                                  value: _selectedSource ?? '__all__',
                                  onChanged: (value) => setState(
                                    () => _selectedSource =
                                        (value == null || value == '__all__')
                                        ? null
                                        : value,
                                  ),
                                  items: [
                                    fluent.ComboBoxItem<String>(
                                      value: '__all__',
                                      child: Text(l10n.vocabAllSources),
                                    ),
                                    ...allSources.map(
                                      (source) => fluent.ComboBoxItem<String>(
                                        value: source,
                                        child: Tooltip(
                                          message: source,
                                          child: Text(
                                            _sourceFilterLabel(source),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: fluent.ComboBox<String>(
                                  isExpanded: true,
                                  value: _selectedTag ?? '__all__',
                                  onChanged: (value) => setState(
                                    () => _selectedTag =
                                        (value == null || value == '__all__')
                                        ? null
                                        : value,
                                  ),
                                  items: [
                                    fluent.ComboBoxItem<String>(
                                      value: '__all__',
                                      child: Text(
                                        l10n.vocabAllTags,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                    ...allTags.map(
                                      (tag) => fluent.ComboBoxItem<String>(
                                        value: tag,
                                        child: Text(
                                          tag,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
                                child: fluent.ComboBox<_ArchiveFilter>(
                                  isExpanded: true,
                                  value: _archiveFilter,
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _archiveFilter = value);
                                  },
                                  items: [
                                    fluent.ComboBoxItem(
                                      value: _ArchiveFilter.active,
                                      child: Text(
                                        l10n.vocabFilterActive,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                    fluent.ComboBoxItem(
                                      value: _ArchiveFilter.archivedOnly,
                                      child: Text(
                                        l10n.vocabFilterArchived,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                    fluent.ComboBoxItem(
                                      value: _ArchiveFilter.all,
                                      child: Text(
                                        l10n.vocabFilterAll,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            fluent.HyperlinkButton(
                              onPressed: _clearFilters,
                              child: Text(l10n.vocabClearFilters),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 4),
                child: const VocabGoogleCloudTtsPanel(),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(child: Text(l10n.vocabEmptyLibrary))
                    : VocabTableView(
                        items: filteredItems,
                        onContextCommand: (action) => _handleContextCommand(
                          context,
                          action,
                          filteredItems,
                        ),
                      ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: selection.count > 0
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
                        child: ContextualCommandBar(
                          selectedCount: selection.count,
                          tagButtonKey: _tagButtonKey,
                          onCancel: () =>
                              ref.read(vocabSelectionProvider.notifier).clear(),
                          onTag: () => _openBulkTagFlyout(context, items),
                          onStudySelected: () async {
                            final ids = ref
                                .read(vocabSelectionProvider)
                                .selectedIds
                                .toSet();
                            await _startCustomStudy(ids);
                          },
                          onArchive: () => unawaited(
                            _runBulk((ids) async {
                              await ref
                                  .read(vocabRepositoryProvider)
                                  .updateVocabsBulk(ids, <String, dynamic>{
                                    'isArchived': true,
                                  });
                            }),
                          ),
                          onResetSrs: () => unawaited(
                            _runBulk((ids) async {
                              await ref
                                  .read(vocabRepositoryProvider)
                                  .resetSrsBulk(ids);
                            }),
                          ),
                          onDelete: () => unawaited(() async {
                            final confirmed = await _confirmDeleteVocabs(context);
                            if (!confirmed) {
                              return;
                            }
                            await _runBulk((ids) async {
                              await ref
                                  .read(vocabRepositoryProvider)
                                  .deleteVocabsBulk(ids);
                            });
                          }()),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }
}

enum _ArchiveFilter { active, archivedOnly, all }

String _sourceLanguageFromPair(String pair) =>
    sourceLanguageFromPair(pair, fallback: '');

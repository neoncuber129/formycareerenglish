import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/presentation/mobile_layout.dart';
import '../../../core/presentation/safe_dialog.dart';
import '../../capture/presentation/manual_capture_page.dart';
import '../../review/presentation/custom_study_dialog.dart';
import '../../review/presentation/srs_review_screen.dart';
import '../data/vocab_repository_impl.dart';
import 'bulk_tags_bottom_sheet.dart';
import 'vocab_selection_provider.dart';

class VocabLibraryPage extends ConsumerStatefulWidget {
  const VocabLibraryPage({super.key});

  @override
  ConsumerState<VocabLibraryPage> createState() => _VocabLibraryPageState();
}

class _VocabLibraryPageState extends ConsumerState<VocabLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;
  String? _selectedSource;
  String? _selectedLanguage;
  _ArchiveFilter _archiveFilter = _ArchiveFilter.active;
  bool _selectionMode = false;

  /// Facets derived from the full library; recomputed only when [items] identity changes.
  List<Vocab>? _facetItemsRef;
  List<String> _facetTags = const [];
  List<String> _facetLanguages = const [];
  List<String> _facetSources = const [];

  Timer? _searchDebounce;

  void _ensureFacetCaches(List<Vocab> items) {
    if (identical(_facetItemsRef, items)) return;
    _facetItemsRef = items;
    if (items.isEmpty) {
      _facetTags = const [];
      _facetLanguages = const [];
      _facetSources = const [];
      return;
    }
    _facetTags =
        items
            .expand((v) => v.tags)
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _facetLanguages =
        items
            .map((v) => _sourceLanguageFromPair(v.languagePair))
            .where((lang) => lang.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    _facetSources =
        items
            .map(_sourceFacet)
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
              _sourceLanguageFromPair(vocab.languagePair) !=
                  _selectedLanguage!.toLowerCase()) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final sq = vocab.sourceText.toLowerCase();
          final tq = vocab.translatedText.toLowerCase();
          if (sq.contains(query) || tq.contains(query)) return true;
          for (final tag in vocab.tags) {
            if (tag.toLowerCase().contains(query)) return true;
          }
          final app = vocab.sourceApp.toLowerCase();
          if (app.contains(query)) return true;
          final dom = _sourceDomain(vocab.sourceUrl).toLowerCase();
          if (dom.contains(query)) return true;
          return vocab.sourceUrl.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _selectedTag = null;
      _selectedSource = null;
      _selectedLanguage = null;
      _archiveFilter = _ArchiveFilter.active;
    });
  }

  void _enterSelectionAndToggle(String vocabId) {
    setState(() {
      if (!_selectionMode) {
        _selectionMode = true;
      }
    });
    ref.read(vocabSelectionProvider.notifier).toggle(vocabId);
  }

  void _selectAllFiltered(List<Vocab> filtered) {
    ref.read(vocabSelectionProvider.notifier).selectAll(filtered.map((v) => v.id));
    setState(() => _selectionMode = true);
  }

  _SelectionToggleState _selectionStateFor(
    List<Vocab> filtered,
    Set<String> selected,
  ) {
    if (filtered.isEmpty) return _SelectionToggleState.none;
    final filteredIds = filtered.map((v) => v.id).toSet();
    final selectedInFiltered = selected.where(filteredIds.contains).length;
    if (selectedInFiltered == 0) return _SelectionToggleState.none;
    if (selectedInFiltered == filtered.length) return _SelectionToggleState.all;
    return _SelectionToggleState.partial;
  }

  Future<void> _startCustomStudy(Set<String> ids) async {
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select words to study first.')),
      );
      return;
    }
    final settings = ref.read(settingsServiceProvider);
    final initial = await settings.loadCustomStudyDefaults();
    if (!mounted) return;
    final picked = await showCustomStudyOptionsDialog(
      context,
      initial: initial,
      entryCount: ids.length,
    );
    if (!mounted || picked == null) return;
    await settings.saveCustomStudyDefaults(picked);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SrsReviewScreen(
          selectedVocabIds: Set<String>.from(ids),
          customStudyOptions: picked,
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final ids = ref.read(vocabSelectionProvider).toList();
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved words?'),
        content: Text('Permanently delete ${ids.length} selected word(s)?'),
        actions: [
          TextButton(
            onPressed: () => safeNavigatorPop<bool>(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => safeNavigatorPop<bool>(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(vocabRepositoryProvider).deleteVocabsBulk(ids);
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
    setState(() => _selectionMode = false);
  }

  Future<void> _archiveSelected() async {
    final ids = ref.read(vocabSelectionProvider).toList();
    if (ids.isEmpty) return;
    await ref.read(vocabRepositoryProvider).updateVocabsBulk(
          ids,
          <String, dynamic>{'isArchived': true},
        );
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
    setState(() => _selectionMode = false);
  }

  Future<void> _applyBulkTags(Map<String, bool?> states) async {
    final repo = ref.read(vocabRepositoryProvider);
    final ids = ref.read(vocabSelectionProvider).toList();
    if (ids.isEmpty) return;
    final items = await repo.getAllVocab();
    final byId = {for (final v in items) v.id: v};
    final now = DateTime.now();
    String? selectedTag;
    for (final e in states.entries) {
      if (e.value == true) {
        selectedTag = e.key;
        break;
      }
    }
    for (final id in ids) {
      final v = byId[id];
      if (v == null) continue;
      final nextTags =
          selectedTag == null ? const <String>[] : <String>[selectedTag];
      await repo.saveVocab(v.copyWith(tags: nextTags, updatedAt: now));
    }
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
    if (mounted) setState(() => _selectionMode = false);
  }

  Future<void> _openBulkTags(List<Vocab> allItems) async {
    final sel = ref.read(vocabSelectionProvider);
    if (sel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select words first.')),
      );
      return;
    }
    await unfocusForIncomingDialog();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: BulkTagsBottomSheet(
          allVocabs: allItems,
          selectedIds: sel,
          onApply: _applyBulkTags,
          onRenameTag: (oldTag, newTag) async {
            await ref
                .read(vocabRepositoryProvider)
                .renameTagAcrossVocabs(oldTag, newTag);
            ref.invalidate(vocabListProvider);
          },
          onDeleteTag: (tag) async {
            await ref.read(vocabRepositoryProvider).deleteTagAcrossVocabs(tag);
            ref.invalidate(vocabListProvider);
          },
        ),
      ),
    );
  }

  Future<void> _resetSrsSelected() async {
    final ids = ref.read(vocabSelectionProvider).toList();
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset SRS?'),
        content: Text(
          'Reset scheduling for ${ids.length} word(s) to a fresh interval (due now).',
        ),
        actions: [
          TextButton(
            onPressed: () => safeNavigatorPop<bool>(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => safeNavigatorPop<bool>(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(vocabRepositoryProvider).resetSrsBulk(ids);
    ref.invalidate(vocabListProvider);
    ref.read(vocabSelectionProvider.notifier).clear();
    setState(() => _selectionMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabListProvider);
    final selected = ref.watch(vocabSelectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${selected.length} selected' : 'My words'),
        actions: [
          IconButton(
            tooltip: _selectionMode ? 'Done selecting' : 'Select words',
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) {
                  ref.read(vocabSelectionProvider.notifier).clear();
                }
              });
            },
            icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
          ),
          if (_selectionMode && selected.isNotEmpty)
            IconButton(
              tooltip: 'Study selected',
              onPressed: () => unawaited(_startCustomStudy(selected)),
              icon: const Icon(Icons.school),
            ),
          if (_selectionMode && selected.isNotEmpty)
            PopupMenuButton<_SelectionAction>(
              tooltip: 'Selected actions',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (action) async {
                switch (action) {
                  case _SelectionAction.tags:
                    final list = await ref.read(vocabListProvider.future);
                    if (!mounted) return;
                    await _openBulkTags(list);
                    break;
                  case _SelectionAction.resetSrs:
                    await _resetSrsSelected();
                    break;
                  case _SelectionAction.archive:
                    await _archiveSelected();
                    break;
                  case _SelectionAction.delete:
                    await _deleteSelected();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_SelectionAction>(
                  value: _SelectionAction.tags,
                  child: Text('Bulk tags'),
                ),
                PopupMenuItem<_SelectionAction>(
                  value: _SelectionAction.resetSrs,
                  child: Text('Reset SRS'),
                ),
                PopupMenuItem<_SelectionAction>(
                  value: _SelectionAction.archive,
                  child: Text('Archive'),
                ),
                PopupMenuItem<_SelectionAction>(
                  value: _SelectionAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          if (!_selectionMode) ...[
            IconButton(
              tooltip: 'Study filtered (current filters)',
              onPressed: () async {
                final list = await ref.read(vocabListProvider.future);
                if (!mounted) return;
                final ids = _applyFilters(list).map((e) => e.id).toSet();
                if (ids.isEmpty) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No words match the current filters.'),
                    ),
                  );
                  return;
                }
                await _startCustomStudy(ids);
              },
              icon: const Icon(Icons.filter_alt_outlined),
            ),
            IconButton(
              tooltip: 'Review due words',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SrsReviewScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.school_outlined),
            ),
          ],
        ],
      ),
      body: vocabAsync.when(
        data: (items) {
          final g = MobileLayout.gutter(context);
          _ensureFacetCaches(items);
          final filtered = _applyFilters(items);
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(g + 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No words yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first word or import a backup from Settings.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ManualCapturePage(),
                          ),
                        );
                        if (context.mounted) {
                          ref.invalidate(vocabListProvider);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add word'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(g, 12, g, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 200),
                      () {
                        if (mounted) setState(() {});
                      },
                    );
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search term, meaning, tag, source, or URL',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PopupMenuButton<_ArchiveFilter>(
                        tooltip: 'Archive',
                        onSelected: (value) =>
                            setState(() => _archiveFilter = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _ArchiveFilter.active,
                            child: Text('Active'),
                          ),
                          PopupMenuItem(
                            value: _ArchiveFilter.archivedOnly,
                            child: Text('Archived'),
                          ),
                          PopupMenuItem(
                            value: _ArchiveFilter.all,
                            child: Text('All'),
                          ),
                        ],
                        icon: const Icon(Icons.inventory_2_outlined),
                      ),
                      PopupMenuButton<String?>(
                        tooltip: 'Language',
                        initialValue: _selectedLanguage,
                        onSelected: (value) =>
                            setState(() => _selectedLanguage = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('All languages'),
                          ),
                          ..._facetLanguages.map(
                            (lang) => PopupMenuItem<String?>(
                              value: lang,
                              child: Text(lang.toUpperCase()),
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.language),
                      ),
                      PopupMenuButton<String?>(
                        tooltip: 'Source',
                        initialValue: _selectedSource,
                        onSelected: (value) =>
                            setState(() => _selectedSource = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('All sources'),
                          ),
                          ..._facetSources.map(
                            (source) => PopupMenuItem<String?>(
                              value: source,
                              child: Tooltip(
                                message: source,
                                child: SizedBox(
                                  width: 240,
                                  child: Text(
                                    _sourceFilterLabel(source),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.link),
                      ),
                      PopupMenuButton<String?>(
                        tooltip: 'Tag',
                        initialValue: _selectedTag,
                        onSelected: (value) =>
                            setState(() => _selectedTag = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('All tags'),
                          ),
                          ..._facetTags.map(
                            (tag) => PopupMenuItem<String?>(
                              value: tag,
                              child: Tooltip(
                                message: tag,
                                child: SizedBox(
                                  width: 220,
                                  child: Text(
                                    tag,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.label_outline),
                      ),
                      IconButton(
                        onPressed: _clearFilters,
                        tooltip: 'Clear filters',
                        icon: const Icon(Icons.filter_alt_off),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectionMode)
                Builder(
                  builder: (_) {
                    final toggle = _selectionStateFor(filtered, selected);
                    final allSelected = toggle == _SelectionToggleState.all;
                    final partial = toggle == _SelectionToggleState.partial;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(g, 0, g, 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: allSelected ? true : (partial ? null : false),
                            tristate: true,
                            onChanged: filtered.isEmpty
                                ? null
                                : (checked) {
                                    if (checked == true) {
                                      _selectAllFiltered(filtered);
                                    } else {
                                      ref.read(vocabSelectionProvider.notifier).clear();
                                      setState(() {});
                                    }
                                  },
                          ),
                          Text(
                            'Select all filtered (${filtered.length})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, index) {
                    final vocab = filtered[index];
                    final isSelected = selected.contains(vocab.id);
                    return ListTile(
                      leading: _selectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) =>
                                  ref.read(vocabSelectionProvider.notifier).toggle(vocab.id),
                            )
                          : null,
                      title: Text(vocab.sourceText),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vocab.translatedText),
                          if (vocab.tags.isNotEmpty)
                            Text(
                              'Tags: ${vocab.tags.join(', ')}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          if (_sourceFacet(vocab).isNotEmpty)
                            Text(
                              'Source: ${_sourceFacet(vocab)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                      isThreeLine:
                          vocab.tags.isNotEmpty ||
                          _sourceFacet(vocab).isNotEmpty,
                      trailing: _selectionMode ? null : Text(vocab.languagePair),
                      onLongPress: () => _enterSelectionAndToggle(vocab.id),
                      onTap: _selectionMode
                          ? () => ref.read(vocabSelectionProvider.notifier).toggle(vocab.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
        error: (error, _) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManualCapturePage(),
                  ),
                );
                if (mounted) {
                  ref.invalidate(vocabListProvider);
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add word'),
            ),
    );
  }
}

enum _ArchiveFilter { active, archivedOnly, all }
enum _SelectionAction { tags, resetSrs, archive, delete }
enum _SelectionToggleState { none, partial, all }

String _sourceLanguageFromPair(String pair) =>
    sourceLanguageFromPair(pair, fallback: '');

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

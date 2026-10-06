import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

import '../../../core/backup/mobile_backup_import_service.dart';
import '../../../core/presentation/mobile_layout.dart';
import '../../../core/presentation/safe_dialog.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import 'local_profiles_settings_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsReplaceVocabTitle),
        content: Text(l10n.settingsReplaceVocabBody),
        actions: [
          TextButton(
            onPressed: () => safeNavigatorPop<bool>(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => safeNavigatorPop<bool>(dialogContext, true),
            child: Text(l10n.settingsChooseFile),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) {
      return;
    }

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['db', 'json'],
      allowMultiple: false,
      withData: true,
    );
    if (pick == null || pick.files.isEmpty || !context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(l10n.settingsImporting)),
            ],
          ),
        ),
      ),
    );

    try {
      final service = ref.read(mobileBackupImportServiceProvider);
      final result = await service.importFromPickerFile(pick.files.single);
      ref.invalidate(vocabListProvider);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsImportedCount(result.itemCount, result.sourceKind),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsImportFailed(friendlyBackupImportError(error)),
          ),
        ),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final path = await ref.read(mobileBackupImportServiceProvider).exportSignedJsonWithPicker();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? l10n.settingsExportCancelled
                : l10n.settingsSavedPath(path),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langAsync = ref.watch(languageSettingsProvider);
    final uiTag = ref.watch(uiLocalePreferenceProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          MobileLayout.gutter(context),
          8,
          MobileLayout.gutter(context),
          24,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.uiLanguageSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: uiTag.isEmpty ? '' : uiTag,
                    decoration: InputDecoration(labelText: l10n.uiLanguageLabel),
                    items: kUiLocalePreferenceComboTags
                        .map(
                          (tag) => DropdownMenuItem<String>(
                            value: tag,
                            child: Text(labelForUiLocaleTag(l10n, tag)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(uiLocalePreferenceProvider.notifier).setTag(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.uiLanguageDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const MobileLocalProfilesSettingsCard(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsReviewAudioSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsAutoPlayAudioTitle),
                    value: ref.watch(reviewAutoPlayAudioProvider),
                    onChanged: (v) =>
                        ref.read(reviewAutoPlayAudioProvider.notifier).setEnabled(v),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: Text(l10n.settingsRememberTagTitle),
              value: ref.watch(capturePopupAutoRecentTagProvider),
              onChanged: (v) => ref
                  .read(capturePopupAutoRecentTagProvider.notifier)
                  .setEnabled(v),
            ),
          ),
          langAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: ListTile(
                title: Text(l10n.settingsLanguageLoadError('$e')),
              ),
            ),
            data: (settings) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translationSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: settings.nativeLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.nativeLanguageLabel,
                      ),
                      items: kSupportedLanguages
                          .map(
                            (o) => DropdownMenuItem(
                              value: o.code,
                              child: Text('${o.label} (${o.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(languageSettingsProvider.notifier).setNativeLanguage(v);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsLocalBackupTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _exportBackup(context, ref),
                        child: Text(l10n.settingsBackupNowJson),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _importBackup(context, ref),
                        child: Text(l10n.settingsImportBackup),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settingsBackupFootnote,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.settingsManageTagsTitle),
              subtitle: Text(l10n.settingsManageTagsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openTagManager(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTagManager(BuildContext context, WidgetRef ref) async {
    final items = await ref.read(vocabRepositoryProvider).getAllVocab();
    final allTags = items
        .expand((v) => v.tags)
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final loc = sheetContext.l10n;
        Future<void> handleTagMenuSelection(String value, String tag) async {
          await unfocusForIncomingDialog();
          if (!sheetContext.mounted) return;
          if (value == 'rename') {
            final next = await showSafeSingleLineInputDialog(
              sheetContext,
              title: loc.bulkTagRenameTitle,
              labelText: loc.bulkTagRenamePlaceholder,
              initialValue: tag,
              confirmLabel: loc.commonSave,
              cancelLabel: loc.commonCancel,
            );
            final newTag = (next ?? '').trim();
            if (newTag.isEmpty || newTag.toLowerCase() == tag.toLowerCase()) {
              return;
            }
            await ref.read(vocabRepositoryProvider).renameTagAcrossVocabs(tag, newTag);
          } else {
            await ref.read(vocabRepositoryProvider).deleteTagAcrossVocabs(tag);
          }
          ref.invalidate(vocabListProvider);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
        }

        return SafeArea(
          child: allTags.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(loc.settingsTagManagerEmpty),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allTags.length,
                  itemBuilder: (_, index) {
                    final tag = allTags[index];
                    return ListTile(
                      title: Text(tag),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            unawaited(handleTagMenuSelection(value, tag));
                          });
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(loc.bulkTagRename),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(loc.bulkTagDelete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

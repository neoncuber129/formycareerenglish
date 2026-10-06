import 'dart:async';
import 'dart:io';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/backup/local_backup_service.dart';
import 'package:desktop/core/backup/scheduled_local_backup_service.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../application/settings_service.dart';
import 'local_profiles_settings_section.dart';
import '../../vocab/presentation/vocab_list_provider.dart';

String _backupIntervalLabel(AppLocalizations l10n, int hours) {
  switch (hours) {
    case 1:
      return l10n.backupIntervalHourly;
    case 6:
      return l10n.backupInterval6h;
    case 12:
      return l10n.backupInterval12h;
    case 24:
      return l10n.backupIntervalDaily;
    case 48:
      return l10n.backupInterval2days;
    case 168:
      return l10n.backupIntervalWeekly;
    default:
      return l10n.backupIntervalEveryHours(hours);
  }
}

String _friendlyBackupErrorMessage(AppLocalizations l10n, Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('no backup file found')) {
    return l10n.backupErrNoBackupFile;
  }
  if (raw.contains('backup database file not found')) {
    return l10n.backupErrSqliteMissing;
  }
  if (raw.contains('backup file not found')) {
    return l10n.backupErrFileMissing;
  }
  if (raw.contains('unsupported backup format')) {
    return l10n.backupErrUnsupportedFormat;
  }
  if (raw.contains('checksum mismatch') || raw.contains('invalid drive snapshot')) {
    return l10n.backupErrInvalidCorrupt;
  }
  return l10n.backupErrGeneric(error.toString());
}

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(languageSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settingsTitle),
            const SizedBox(height: 4),
            Text(
              l10n.settingsSubtitle,
              style: fluent.FluentTheme.of(context).typography.caption,
            ),
          ],
        ),
      ),
      content: settingsAsync.when(
        loading: () => const Center(child: fluent.ProgressRing()),
        error: (error, _) => Center(
          child: Padding(
            padding: DesktopPaneScrollMetrics.scrollPadding(context),
            child: fluent.InfoBar(
              title: Text('Error: $error'),
              severity: fluent.InfoBarSeverity.error,
            ),
          ),
        ),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final LanguageSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupService = ref.watch(localBackupServiceProvider);
    final customBackupDir = ref.watch(localBackupCustomDirectoryProvider);
    final autoBackupOn = ref.watch(autoLocalBackupEnabledProvider);
    final autoBackupHours = ref.watch(autoLocalBackupIntervalHoursProvider);

    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final uiTag = ref.watch(uiLocalePreferenceProvider);
    final uiLocaleNotifier = ref.read(uiLocalePreferenceProvider.notifier);
    final uiTextScale = ref.watch(uiTextScalePreferenceProvider);
    final uiTextScaleNotifier =
        ref.read(uiTextScalePreferenceProvider.notifier);
    final controller = ref.read(languageSettingsProvider.notifier);
    final effectiveLanguageSettings = settings;
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final scrollPad = DesktopPaneScrollMetrics.scrollPadding(context);
    final maxBody = DesktopPaneScrollMetrics.maxBodyWidth(context);

    return SingleChildScrollView(
      padding: scrollPad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBody),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopPaneSectionCard(
                icon: FluentIcons.local_language_24_regular,
                title: l10n.uiLanguageSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fluent.InfoLabel(
                      label: l10n.uiLanguageLabel,
                      child: fluent.ComboBox<String>(
                        value: uiTag.isEmpty ? '' : uiTag,
                        isExpanded: true,
                        items: kUiLocalePreferenceComboTags
                            .map(
                              (tag) => fluent.ComboBoxItem<String>(
                                value: tag,
                                child: Text(labelForUiLocaleTag(l10n, tag)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            uiLocaleNotifier.setTag(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.uiLanguageDescription,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
              DesktopPaneSectionCard(
                icon: fluent.FluentIcons.font_size,
                title: l10n.settingsTextScaleSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fluent.InfoLabel(
                      label: l10n.settingsTextScaleLabel,
                      child: fluent.ComboBox<double>(
                        value: uiTextScale,
                        isExpanded: true,
                        items: kUiTextScaleOptions
                            .map(
                              (s) => fluent.ComboBoxItem<double>(
                                value: s,
                                child: Text(
                                  l10n.settingsTextScalePercent(
                                    (s * 100).round(),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            unawaited(uiTextScaleNotifier.setScale(value));
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.settingsTextScaleDescription,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
              DesktopPaneSectionCard(
                icon: FluentIcons.people_team_24_regular,
                title: l10n.localProfilesSectionTitle,
                child: const DesktopLocalProfilesSettingsSection(),
              ),
              SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
              DesktopPaneSectionCard(
                icon: FluentIcons.archive_24_regular,
                title: l10n.backupSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupSectionIntro,
                      style: theme.typography.caption,
                    ),
                    SizedBox(height: 12 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.defaultBackupFolderTitle,
                      style: theme.typography.title?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.defaultBackupFolderDescription,
                      style: theme.typography.caption,
                    ),
                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                    FutureBuilder<String>(
                      key: ValueKey<String>(customBackupDir ?? 'app_default'),
                      future: backupService.backupDirectoryPath(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              l10n.resolvingPath,
                              style: theme.typography.caption,
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.currentPathPrefix(snap.data!),
                            style: theme.typography.caption,
                          ),
                        );
                      },
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        fluent.Button(
                          onPressed: () async {
                            try {
                              final selected = await getDirectoryPath(
                                initialDirectory: customBackupDir,
                                confirmButtonText: l10n.confirmUseFolder,
                              );
                              if (selected == null ||
                                  selected.trim().isEmpty) {
                                return;
                              }
                              final normalized = selected.trim();
                              try {
                                await Directory(normalized).create(
                                  recursive: true,
                                );
                              } on FileSystemException catch (e) {
                                if (!context.mounted) return;
                                await fluent.displayInfoBar(
                                  context,
                                  builder: (ctx, close) => fluent.InfoBar(
                                    title: Text(
                                      l10n.couldNotUseFolder(e.toString()),
                                    ),
                                    severity: fluent.InfoBarSeverity.error,
                                  ),
                                );
                                return;
                              }
                              await ref
                                  .read(
                                    localBackupCustomDirectoryProvider.notifier,
                                  )
                                  .setDirectory(normalized);
                              ref
                                  .read(scheduledLocalBackupServiceProvider)
                                  .requestCheck();
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(l10n.defaultBackupFolderSet(normalized)),
                                  severity: fluent.InfoBarSeverity.success,
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(
                                    _friendlyBackupErrorMessage(l10n, error),
                                  ),
                                  severity: fluent.InfoBarSeverity.error,
                                ),
                              );
                            }
                          },
                          child: Text(l10n.changeDefaultFolder),
                        ),
                        if (customBackupDir != null)
                          fluent.Button(
                            onPressed: () async {
                              await ref
                                  .read(
                                    localBackupCustomDirectoryProvider.notifier,
                                  )
                                  .setDirectory(null);
                              ref
                                  .read(scheduledLocalBackupServiceProvider)
                                  .requestCheck();
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(l10n.usingAppDefaultAgain),
                                  severity: fluent.InfoBarSeverity.info,
                                ),
                              );
                            },
                            child: Text(l10n.useAppDefaultFolder),
                          ),
                      ],
                    ),
                    SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.automaticBackupTitle,
                                style: theme.typography.title?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.automaticBackupDescription,
                                style: theme.typography.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        fluent.ToggleSwitch(
                          checked: autoBackupOn,
                          onChanged: (v) async {
                            await ref
                                .read(autoLocalBackupEnabledProvider.notifier)
                                .setEnabled(v);
                            if (!v || !context.mounted) {
                              return;
                            }
                            try {
                              await ref
                                  .read(scheduledLocalBackupServiceProvider)
                                  .runBackupNow();
                            } catch (error) {
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(
                                    _friendlyBackupErrorMessage(l10n, error),
                                  ),
                                  severity: fluent.InfoBarSeverity.error,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * tf.clamp(0.9, 1.25)),
                    fluent.InfoLabel(
                      label: l10n.repeatEveryLabel,
                      child: fluent.ComboBox<int>(
                        value: autoBackupHours,
                        isExpanded: true,
                        items: kAutoLocalBackupIntervalHoursOptions
                            .map(
                              (h) => fluent.ComboBoxItem<int>(
                                value: h,
                                child: Text(_backupIntervalLabel(l10n, h)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: autoBackupOn
                            ? (value) async {
                                if (value == null) return;
                                await ref
                                    .read(
                                      autoLocalBackupIntervalHoursProvider
                                          .notifier,
                                    )
                                    .setHours(value);
                                ref
                                    .read(scheduledLocalBackupServiceProvider)
                                    .requestCheck();
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 12 * tf.clamp(0.9, 1.25)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        fluent.Button(
                          onPressed: () async {
                            try {
                              final selectedDirectory = await getDirectoryPath(
                                initialDirectory: customBackupDir,
                                confirmButtonText: l10n.saveBackupHere,
                              );
                              if (selectedDirectory == null ||
                                  selectedDirectory.trim().isEmpty) {
                                return;
                              }
                              final path = await backupService
                                  .createBackupAtDirectory(selectedDirectory);
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(l10n.backupCreated(path)),
                                  severity: fluent.InfoBarSeverity.success,
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(_friendlyBackupErrorMessage(l10n, error)),
                                  severity: fluent.InfoBarSeverity.error,
                                ),
                              );
                            }
                          },
                          child: Text(l10n.backupNow),
                        ),
                        fluent.Button(
                          onPressed: () async {
                            try {
                              final chosen = await openFile(
                                acceptedTypeGroups: <XTypeGroup>[
                                  XTypeGroup(
                                    label: l10n.backupFilesFilter,
                                    extensions: const <String>['db', 'json'],
                                  ),
                                ],
                                confirmButtonText: l10n.restoreFromThisFile,
                              );
                              if (chosen == null) {
                                return;
                              }
                              final restored = await backupService.restoreBackupFromPath(
                                chosen.path,
                              );
                              if (!context.mounted) return;
                              ref.invalidate(vocabListProvider);
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(l10n.restoredFrom(restored)),
                                  severity: fluent.InfoBarSeverity.success,
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              await fluent.displayInfoBar(
                                context,
                                builder: (ctx, close) => fluent.InfoBar(
                                  title: Text(_friendlyBackupErrorMessage(l10n, error)),
                                  severity: fluent.InfoBarSeverity.warning,
                                ),
                              );
                            }
                          },
                          child: Text(l10n.restoreFromFile),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.backupFooterNote,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
              DesktopPaneSectionCard(
                icon: FluentIcons.translate_24_regular,
                title: l10n.translationSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fluent.InfoLabel(
                      label: l10n.nativeLanguageLabel,
                      child: fluent.ComboBox<String>(
                        value: effectiveLanguageSettings.nativeLanguage,
                        isExpanded: true,
                        items: kSupportedLanguages
                            .map(
                              (opt) => fluent.ComboBoxItem<String>(
                                value: opt.code,
                                child: Text('${opt.label}  (${opt.code})'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            controller.setNativeLanguage(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.translationNativeHelp,
                      style: theme.typography.caption,
                    ),
                    SizedBox(height: 12 * tf.clamp(0.9, 1.25)),
                    Text(
                      l10n.translationEngineHelp,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

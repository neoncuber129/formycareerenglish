import 'package:app_l10n/app_l10n.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

String labelLocalProfile(AppLocalizations l10n, LocalProfile profile) {
  if (profile.id == LocalProfile.defaultId) {
    return l10n.localProfileDefaultName;
  }
  return profile.displayName;
}

/// Device-local learner profiles — each has its own vocabulary library.
class DesktopLocalProfilesSettingsSection extends ConsumerWidget {
  const DesktopLocalProfilesSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    final state = ref.watch(localProfilesProvider);
    final notifier = ref.read(localProfilesProvider.notifier);

    Future<void> promptNameDialog({
      required String title,
      String initial = '',
      required Future<void> Function(String name) onSubmit,
    }) async {
      final controller = fluent.TextEditingController(text: initial);
      String? outcome;
      try {
        outcome = await fluent.showDialog<String>(
          context: context,
          builder: (dialogContext) {
            return fluent.ContentDialog(
              title: Text(title),
              content: fluent.TextBox(
                controller: controller,
                placeholder: l10n.localProfileNameLabel,
              ),
              actions: [
                fluent.Button(
                  child: Text(l10n.commonCancel),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                fluent.FilledButton(
                  child: Text(l10n.commonSave),
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                ),
              ],
            );
          },
        );
      } finally {
        controller.dispose();
      }
      final name = outcome?.trim() ?? '';
      if (name.isEmpty) {
        return;
      }
      await onSubmit(name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.localProfilesSectionDescription,
          style: theme.typography.caption,
        ),
        const SizedBox(height: 12),
        ...state.profiles.map((profile) {
          final active = profile.id == state.activeProfileId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: fluent.Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelLocalProfile(l10n, profile),
                            style: theme.typography.bodyStrong,
                          ),
                          if (active)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.localProfileActiveBadge,
                                style: theme.typography.caption,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!active)
                      fluent.Button(
                        onPressed: () async {
                          await notifier.setActiveProfile(profile.id);
                        },
                        child: Text(l10n.localProfileUseAction),
                      ),
                    fluent.Button(
                      onPressed: () async {
                        await promptNameDialog(
                          title: l10n.localProfileRenameTitle,
                          initial: profile.displayName,
                          onSubmit: (name) =>
                              notifier.renameProfile(profile.id, name),
                        );
                      },
                      child: Text(l10n.localProfileRenameAction),
                    ),
                    if (profile.id != LocalProfile.defaultId)
                      fluent.Button(
                        onPressed: () async {
                          final ok = await fluent.showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => fluent.ContentDialog(
                              title: Text(l10n.localProfileDeleteConfirmTitle),
                              content: Text(l10n.localProfileDeleteConfirmBody),
                              actions: [
                                fluent.Button(
                                  child: Text(l10n.commonCancel),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                ),
                                fluent.FilledButton(
                                  child: Text(l10n.localProfileDeleteAction),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await notifier.removeProfile(profile.id);
                          }
                        },
                        child: Text(l10n.localProfileDeleteAction),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        fluent.FilledButton(
          onPressed: () async {
            await promptNameDialog(
              title: l10n.localProfileAddTitle,
              onSubmit: notifier.addProfile,
            );
          },
          child: Text(l10n.localProfileAddAction),
        ),
      ],
    );
  }
}

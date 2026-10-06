import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

import '../../../core/presentation/safe_dialog.dart';

String mobileLabelLocalProfile(AppLocalizations l10n, LocalProfile profile) {
  if (profile.id == LocalProfile.defaultId) {
    return l10n.localProfileDefaultName;
  }
  return profile.displayName;
}

class MobileLocalProfilesSettingsCard extends ConsumerWidget {
  const MobileLocalProfilesSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(localProfilesProvider);
    final notifier = ref.read(localProfilesProvider.notifier);

    Future<void> promptName({
      required String title,
      String initial = '',
      required Future<void> Function(String name) onSubmit,
    }) async {
      final controller = TextEditingController(text: initial);
      final outcome = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.localProfileNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => safeNavigatorPop<String>(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => safeNavigatorPop<String>(
                dialogContext,
                controller.text.trim(),
              ),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      );
      controller.dispose();
      final name = outcome?.trim() ?? '';
      if (name.isEmpty) {
        return;
      }
      await onSubmit(name);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.localProfilesSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.localProfilesSectionDescription,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...state.profiles.map((profile) {
              final active = profile.id == state.activeProfileId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(mobileLabelLocalProfile(l10n, profile)),
                subtitle: active ? Text(l10n.localProfileActiveBadge) : null,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (!active)
                      TextButton(
                        onPressed: () =>
                            notifier.setActiveProfile(profile.id),
                        child: Text(l10n.localProfileUseAction),
                      ),
                    TextButton(
                      onPressed: () async {
                        await promptName(
                          title: l10n.localProfileRenameTitle,
                          initial: profile.displayName,
                          onSubmit: (name) =>
                              notifier.renameProfile(profile.id, name),
                        );
                      },
                      child: Text(l10n.localProfileRenameAction),
                    ),
                    if (profile.id != LocalProfile.defaultId)
                      TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(l10n.localProfileDeleteConfirmTitle),
                              content: Text(l10n.localProfileDeleteConfirmBody),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      safeNavigatorPop<bool>(dialogContext, false),
                                  child: Text(l10n.commonCancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      safeNavigatorPop<bool>(dialogContext, true),
                                  child: Text(l10n.localProfileDeleteAction),
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
              );
            }),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await promptName(
                  title: l10n.localProfileAddTitle,
                  onSubmit: notifier.addProfile,
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.localProfileAddAction),
            ),
          ],
        ),
      ),
    );
  }
}

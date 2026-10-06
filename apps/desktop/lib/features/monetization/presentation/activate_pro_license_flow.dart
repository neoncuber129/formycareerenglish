import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the license-key dialog; returns trimmed input when confirmed, or null.
Future<String?> showProLicenseKeyDialog(BuildContext context) async {
  final l10n = context.l10n;
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => fluent.ContentDialog(
        title: Text(l10n.aboutActivateProTitle),
        content: fluent.TextBox(
          controller: controller,
          placeholder: l10n.aboutActivateProPlaceholder,
          autofocus: true,
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          fluent.FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.aboutActivatePro),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

Future<void> activateProWithFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required String key,
}) async {
  final result =
      await ref.read(appStateProvider.notifier).activateProWithKey(key);
  if (!context.mounted) {
    return;
  }
  await fluent.displayInfoBar(
    context,
    builder: (ctx, close) => fluent.InfoBar(
      title: Text(result.message),
      severity: result.success
          ? fluent.InfoBarSeverity.success
          : fluent.InfoBarSeverity.warning,
    ),
    duration: const Duration(seconds: 3),
  );
}

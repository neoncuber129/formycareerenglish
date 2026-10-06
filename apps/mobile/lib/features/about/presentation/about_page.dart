import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/monetization/app_state.dart';
import '../../../core/presentation/mobile_layout.dart';
import '../../../core/presentation/safe_dialog.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  static const String _appName = 'FormyCareer';
  static const String _supportEmail = 'FormyCareersupport@gmail.com';
  static const String _privacyPolicyUrl =
      'https://formycareer.vercel.app/privacy.html';
  static const String _termsOfServiceUrl =
      'https://formycareer.vercel.app/terms.html';
  bool _checking = false;
  bool _activating = false;

  Future<void> _openPolicyUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _checkUpdates() async {
    if (_checking) return;
    final l10n = context.l10n;
    setState(() => _checking = true);
    try {
      await ref.read(appStateProvider.notifier).checkForUpdates();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutUpdateCheckDone)),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _activatePro() async {
    final key = await showDialog<String?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (_) => const _ProLicenseKeyDialog(),
    );
    if (!mounted) return;
    final trimmed = (key ?? '').trim();
    if (trimmed.isEmpty) return;
    if (_activating) return;
    setState(() => _activating = true);
    try {
      final result =
          await ref.read(appStateProvider.notifier).activateProWithKey(trimmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appState = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAbout)),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_appName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(l10n.aboutVersionPrefix(appState.currentVersion)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aboutUpdatesSection,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l10n.aboutLatestVersionLabel(appState.latestVersion)),
                  Text(
                    appState.hasUpdate
                        ? l10n.aboutUpdateAvailable
                        : l10n.aboutUsingLatest,
                  ),
                  if (appState.releaseNotes.isNotEmpty)
                    Text(
                      l10n.aboutReleaseNotesPrefix(appState.releaseNotes),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    appState.isPro ? l10n.aboutPlanPro : l10n.aboutPlanFree,
                  ),
                  if (!appState.isPro) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.aboutProKeyInstructions,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: _checking ? null : _checkUpdates,
                        child: Text(
                          _checking
                              ? l10n.aboutCheckingUpdates
                              : l10n.aboutCheckUpdates,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(appState.downloadUrl);
                          if (uri != null) await launchUrl(uri);
                        },
                        child: Text(l10n.aboutDownloadLatest),
                      ),
                      if (!appState.isPro)
                        FilledButton(
                          onPressed: _activating ? null : _activatePro,
                          child: Text(
                            _activating
                                ? l10n.aboutActivating
                                : l10n.aboutActivatePro,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutWhatProUnlocks,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutOneLicense,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final line in [
                    l10n.aboutProBenefit1,
                    l10n.aboutProBenefit2,
                    l10n.aboutProBenefit3,
                    l10n.aboutProBenefit4,
                    l10n.aboutProBenefit5,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                          Expanded(
                            child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutSupportLegal,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.aboutSupportEmailPrefix(_supportEmail)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: _supportEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.aboutSupportEmailCopied)),
                          );
                        },
                        child: Text(l10n.aboutCopySupportEmail),
                      ),
                      OutlinedButton(
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: _appName,
                          applicationVersion: appState.currentVersion,
                        ),
                        child: Text(l10n.aboutOpenSourceLicenses),
                      ),
                      OutlinedButton(
                        onPressed: () => _openPolicyUrl(_privacyPolicyUrl),
                        child: Text(l10n.aboutPrivacyPolicy),
                      ),
                      OutlinedButton(
                        onPressed: () => _openPolicyUrl(_termsOfServiceUrl),
                        child: Text(l10n.aboutTermsOfService),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProLicenseKeyDialog extends StatefulWidget {
  const _ProLicenseKeyDialog();

  @override
  State<_ProLicenseKeyDialog> createState() => _ProLicenseKeyDialogState();
}

class _ProLicenseKeyDialogState extends State<_ProLicenseKeyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss({String? result}) {
    safeNavigatorPop<String?>(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.aboutActivateProTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.aboutActivateProPlaceholder,
        ),
        onSubmitted: (_) => _dismiss(result: _controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => _dismiss(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => _dismiss(result: _controller.text.trim()),
          child: Text(l10n.aboutActivatePro),
        ),
      ],
    );
  }
}

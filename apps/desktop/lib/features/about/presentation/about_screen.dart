import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/features/monetization/presentation/activate_pro_license_flow.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  static const String _appName = 'FormyCareer';
  static const String _supportEmail = 'FormyCareersupport@gmail.com';

  /// Keep in sync with `adswebsite/privacy.html` / `terms.html` canonical URLs.
  static const String _privacyPolicyUrl =
      'https://formycareer.vercel.app/privacy.html';
  static const String _termsOfServiceUrl =
      'https://formycareer.vercel.app/terms.html';

  bool _isCheckingUpdate = false;
  bool _isActivatingPro = false;

  Future<void> _checkUpdates() async {
    if (_isCheckingUpdate) {
      return;
    }
    final l10n = context.l10n;
    setState(() => _isCheckingUpdate = true);
    try {
      await ref.read(appStateProvider.notifier).checkForUpdates();
      if (!mounted) {
        return;
      }
      await fluent.displayInfoBar(
        context,
        builder: (ctx, close) => fluent.InfoBar(
          title: Text(l10n.aboutUpdateCheckDone),
          severity: fluent.InfoBarSeverity.info,
        ),
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _openPolicyUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _activatePro() async {
    final key = await showProLicenseKeyDialog(context);
    if (!mounted || key == null) {
      return;
    }
    if (_isActivatingPro) {
      return;
    }
    setState(() => _isActivatingPro = true);
    try {
      await activateProWithFeedback(context: context, ref: ref, key: key);
    } finally {
      if (mounted) {
        setState(() => _isActivatingPro = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);
    final appState = ref.watch(appStateProvider);
    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.navAbout),
            const SizedBox(height: 4),
            Text(
              l10n.aboutPageSubtitle,
              style: theme.typography.caption,
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: DesktopPaneScrollMetrics.scrollPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DesktopPaneScrollMetrics.maxBodyWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fluent.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appName,
                          style: theme.typography.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.aboutVersionPrefix(appState.currentVersion),
                          style: theme.typography.bodyStrong,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.aboutTagline,
                          style: theme.typography.body,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                fluent.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutUpdatesSection,
                          style: theme.typography.subtitle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(l10n.aboutLatestVersionLabel(appState.latestVersion)),
                        Text(
                          appState.hasUpdate
                              ? l10n.aboutUpdateAvailable
                              : l10n.aboutUsingLatest,
                          style: theme.typography.caption,
                        ),
                        if (appState.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.aboutReleaseNotesPrefix(
                              appState.releaseNotes,
                            ),
                            style: theme.typography.caption,
                          ),
                        ],
                        if (appState.requiresUpdate) ...[
                          const SizedBox(height: 6),
                          Text(l10n.aboutMinVersionWarning),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          appState.isPro
                              ? l10n.aboutPlanPro
                              : l10n.aboutPlanFree,
                        ),
                        if (!appState.isPro) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.aboutProKeyInstructions,
                            style: theme.typography.caption,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            fluent.Button(
                              onPressed: _isCheckingUpdate
                                  ? null
                                  : _checkUpdates,
                              child: Text(
                                _isCheckingUpdate
                                    ? l10n.aboutCheckingUpdates
                                    : l10n.aboutCheckUpdates,
                              ),
                            ),
                            fluent.Button(
                              onPressed: () async {
                                final uri = Uri.tryParse(appState.downloadUrl);
                                if (uri == null) {
                                  return;
                                }
                                await launchUrl(uri);
                              },
                              child: Text(l10n.aboutDownloadLatest),
                            ),
                            if (!appState.isPro)
                              fluent.Button(
                                onPressed: () async {
                                  final uri =
                                      Uri.tryParse(appState.proWebsiteUrl.trim());
                                  if (uri == null || !uri.hasScheme) {
                                    return;
                                  }
                                  await launchUrl(uri);
                                },
                                child: Text(l10n.aboutVisitProWebsite),
                              ),
                            if (!appState.isPro)
                              fluent.FilledButton(
                                onPressed: _isActivatingPro
                                    ? null
                                    : _activatePro,
                                child: Text(
                                  _isActivatingPro
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
                fluent.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutWhatProUnlocks,
                          style: theme.typography.subtitle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.aboutOneLicense,
                          style: theme.typography.caption,
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
                                Text(
                                  '• ',
                                  style: theme.typography.body,
                                ),
                                Expanded(
                                  child: Text(line, style: theme.typography.body),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                fluent.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutSupportLegal,
                          style: theme.typography.subtitle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(l10n.aboutSupportEmailPrefix(_supportEmail)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            fluent.Button(
                              onPressed: () {
                                Clipboard.setData(
                                  const ClipboardData(text: _supportEmail),
                                );
                                unawaited(
                                  fluent.displayInfoBar(
                                    context,
                                    builder: (ctx, close) => fluent.InfoBar(
                                      title: Text(l10n.aboutSupportEmailCopied),
                                      severity: fluent.InfoBarSeverity.success,
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(l10n.aboutCopySupportEmail),
                            ),
                            fluent.Button(
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: _appName,
                                applicationVersion: appState.currentVersion,
                              ),
                              child: Text(l10n.aboutOpenSourceLicenses),
                            ),
                            fluent.Button(
                              onPressed: () =>
                                  unawaited(_openPolicyUrl(_privacyPolicyUrl)),
                              child: Text(l10n.aboutPrivacyPolicy),
                            ),
                            fluent.Button(
                              onPressed: () =>
                                  unawaited(_openPolicyUrl(_termsOfServiceUrl)),
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
          ),
        ),
      ),
    );
  }
}

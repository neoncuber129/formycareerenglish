import 'dart:io';

import 'package:app_l10n/app_l10n.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/window/native_overlay_window_controller.dart';
import 'package:desktop/features/settings/application/settings_service.dart';

import 'capture_visual_guides_widgets.dart';

double _captureSectionGap(BuildContext context) {
  final tf = DesktopPaneScrollMetrics.layoutTf(context);
  return 16 * tf.clamp(0.9, 1.25);
}

/// Fluent-styled hub for capture, auto-capture settings, and sync tools.
class CaptureDashboardPage extends ConsumerWidget {
  const CaptureDashboardPage({
    super.key,
    required this.hotkeyDiagnostics,
    required this.globalHotkeyAvailable,
    required this.nativeOverlayActive,
    this.overlayStatusMessage,
    required this.autoCaptureToggleShortcutLabel,
    required this.onInfoBar,
  });

  final HotkeyDiagnostics hotkeyDiagnostics;
  final bool globalHotkeyAvailable;
  final bool nativeOverlayActive;
  final String? overlayStatusMessage;
  final String autoCaptureToggleShortcutLabel;

  /// Toast-style message (e.g. sync / export result).
  final void Function(String message, fluent.InfoBarSeverity severity) onInfoBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = context.l10n;
    final pageHPadding =
        DesktopPaneScrollMetrics.scrollPadding(context).left;
    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        padding: pageHPadding,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.navCapture),
            const SizedBox(height: 4),
            Text(
              l10n.capturePageSubtitle,
              style: theme.typography.caption,
            ),
          ],
        ),
        commandBar: fluent.Button(
          onPressed: () => _showCaptureTipDialog(context),
          child: Text(l10n.commonTips),
        ),
      ),
      content: SingleChildScrollView(
        padding: DesktopPaneScrollMetrics.scrollPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  DesktopPaneScrollMetrics.maxBodyWidth(context),
            ),
            child: _CapturePrimaryColumn(
              ref: ref,
              onInfoBar: onInfoBar,
              autoCaptureToggleShortcutLabel:
                  autoCaptureToggleShortcutLabel,
              globalHotkeyAvailable: globalHotkeyAvailable,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showTextCaptureGuide(BuildContext context) {
  final l10n = context.l10n;
  return fluent.showDialog(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      title: Text(l10n.captureDlgTextCaptureTitle),
      content: SingleChildScrollView(
        child: Text(l10n.captureDlgTextCaptureBody),
      ),
      actions: [
        fluent.Button(
          child: Text(l10n.commonClose),
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

Future<void> _showImageCaptureGuide(BuildContext context) =>
    showOcrVisualGuideDialog(context);

Future<void> _showCaptureTipDialog(BuildContext context) {
  final l10n = context.l10n;
  return fluent.showDialog<void>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      title: Text(l10n.captureDlgTipsTitle),
      content: Text(l10n.captureDlgTipsBody),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}

/// Native language target for capture translations (shared with Settings → Translation).
class _CaptureNativeLanguagePicker extends ConsumerWidget {
  const _CaptureNativeLanguagePicker({required this.theme});

  final fluent.FluentThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final asyncSettings = ref.watch(languageSettingsProvider);
    return asyncSettings.when(
      loading: () => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 22,
          height: 22,
          child: fluent.ProgressRing(strokeWidth: 3),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (languageSettings) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fluent.InfoLabel(
            label: l10n.nativeLanguageLabel,
            child: fluent.ComboBox<String>(
              value: languageSettings.nativeLanguage,
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
                  ref
                      .read(languageSettingsProvider.notifier)
                      .setNativeLanguage(value);
                }
              },
            ),
          ),
          SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
          Text(
            l10n.translationNativeHelp,
            style: theme.typography.caption,
          ),
        ],
      ),
    );
  }
}

class _CapturePrimaryColumn extends ConsumerWidget {
  const _CapturePrimaryColumn({
    required this.ref,
    required this.onInfoBar,
    required this.autoCaptureToggleShortcutLabel,
    required this.globalHotkeyAvailable,
  });

  final WidgetRef ref;
  final void Function(String message, fluent.InfoBarSeverity severity) onInfoBar;
  final String autoCaptureToggleShortcutLabel;
  final bool globalHotkeyAvailable;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);
    final autoOn = ref.watch(openCaptureOnTextSelectionProvider);
    final toggleHotkey = ref.watch(autoCaptureToggleHotkeyProvider);
    final sectionGap = _captureSectionGap(context);
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final innerGap = 18 * tf.clamp(0.9, 1.25);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!globalHotkeyAvailable) ...[
          fluent.InfoBar(
            title: Text(l10n.captureHotkeyUnavailable),
            severity: fluent.InfoBarSeverity.warning,
          ),
          SizedBox(height: 10 * tf.clamp(0.85, 1.2)),
        ],
        DesktopPaneSectionCard(
          icon: FluentIcons.cursor_click_24_regular,
          title: l10n.captureAutoCaptureTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.captureAutoCaptureBody,
                          style: theme.typography.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.captureAutoToggleShortcutLine(
                            autoCaptureToggleShortcutLabel,
                          ),
                          style: theme.typography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  fluent.ToggleSwitch(
                    checked: autoOn,
                    onChanged: (v) async {
                      await ref
                          .read(openCaptureOnTextSelectionProvider.notifier)
                          .setEnabled(v);
                      final status =
                          v ? l10n.captureAutoStatusOn : l10n.captureAutoStatusOff;
                      onInfoBar(
                        l10n.captureAutoToast(
                          status,
                          toggleHotkey.displayLabel,
                        ),
                        fluent.InfoBarSeverity.info,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 12 * tf.clamp(0.9, 1.25)),
              _CaptureNativeLanguagePicker(theme: theme),
              SizedBox(height: 14 * tf.clamp(0.9, 1.25)),
              fluent.InfoLabel(
                label: l10n.captureHotkeyToggleLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(toggleHotkey.displayLabel),
                    const SizedBox(width: 10),
                    fluent.Button(
                      child: Text(l10n.capturePressNewShortcut),
                      onPressed: () async {
                        final nextKey = await _showHotkeyCaptureDialog(
                          context,
                        );
                        if (nextKey == null) {
                          return;
                        }
                        await ref
                            .read(autoCaptureToggleHotkeyProvider.notifier)
                            .setKey(nextKey);
                        onInfoBar(
                          l10n.captureHotkeySetToast(nextKey),
                          fluent.InfoBarSeverity.success,
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (autoOn) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.captureActiveBehaviorNote,
                  style: theme.typography.caption,
                ),
              ],
              if (Platform.isMacOS) ...[
                const SizedBox(height: 14),
                _PermissionHelpPanel(onInfoBar: onInfoBar),
              ],
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        DesktopPaneSectionCard(
          icon: FluentIcons.camera_add_24_regular,
          title: l10n.captureVisualGuidesCardTitle,
          child: CaptureVisualGuidesSection(
            theme: theme,
            l10n: l10n,
            onAutoGuide: () => showAutoCaptureVisualGuideDialog(context),
            onOcrGuide: () => showOcrVisualGuideDialog(context),
          ),
        ),
        SizedBox(height: sectionGap),
        DesktopPaneSectionCard(
          icon: FluentIcons.keyboard_24_regular,
          title: l10n.captureShortcutsSectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.captureShortcutsSectionBody,
                style: theme.typography.caption,
              ),
              SizedBox(height: innerGap),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  fluent.FilledButton(
                    onPressed: () => _showTextCaptureGuide(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.cursor_hover_24_regular, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.captureTextFromSelection),
                      ],
                    ),
                  ),
                  fluent.Button(
                    onPressed: () => _showImageCaptureGuide(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.camera_add_24_regular, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.captureImageRegionOcr),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionHelpPanel extends ConsumerStatefulWidget {
  const _PermissionHelpPanel({required this.onInfoBar});

  final void Function(String message, fluent.InfoBarSeverity severity) onInfoBar;

  @override
  ConsumerState<_PermissionHelpPanel> createState() =>
      _PermissionHelpPanelState();
}

class _PermissionHelpPanelState extends ConsumerState<_PermissionHelpPanel> {
  DesktopPermissionStatus? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final status = await ref
        .read(nativeOverlayWindowControllerProvider)
        .getPermissionStatus();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _requestMissingPermissions() async {
    setState(() => _loading = true);
    await ref.read(nativeOverlayWindowControllerProvider).requestMissingPermissions();
    // macOS can apply screen-recording changes after restart, so re-check shortly.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _refreshStatus();
    if (!mounted) {
      return;
    }
    final status = _status;
    if (status == null) {
      return;
    }
    final l10n = context.l10n;
    if (status.allGranted) {
      widget.onInfoBar(
        l10n.capturePermAllGranted,
        fluent.InfoBarSeverity.success,
      );
      return;
    }
    widget.onInfoBar(
      l10n.capturePermSomeMissing,
      fluent.InfoBarSeverity.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);
    final status = _status;
    final accessibility = status?.accessibility ?? false;
    final screenRecording = status?.screenRecording ?? false;
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final inset = (12 * tf).clamp(8.0, 20.0);
    return Container(
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.cardStrokeColorDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.capturePermissionsTitle, style: theme.typography.bodyStrong),
          const SizedBox(height: 6),
          Text(
            l10n.captureAccessibilityGrantedLine(
              accessibility ? l10n.commonGranted : l10n.commonMissing,
            ),
            style: theme.typography.caption,
          ),
          Text(
            l10n.captureScreenRecordingGrantedLine(
              screenRecording ? l10n.commonGranted : l10n.commonMissing,
            ),
            style: theme.typography.caption,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              fluent.Button(
                onPressed: _loading ? null : _refreshStatus,
                child: Text(l10n.capturePermRefresh),
              ),
              const SizedBox(width: 8),
              fluent.FilledButton(
                onPressed: _loading ? null : _requestMissingPermissions,
                child: Text(
                  _loading ? l10n.capturePermChecking : l10n.capturePermRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<String?> _showHotkeyCaptureDialog(BuildContext context) {
  return fluent.showDialog<String>(
    context: context,
    builder: (dialogContext) => const _HotkeyCaptureDialog(),
  );
}

class _HotkeyCaptureDialog extends StatefulWidget {
  const _HotkeyCaptureDialog();

  @override
  State<_HotkeyCaptureDialog> createState() => _HotkeyCaptureDialogState();
}

class _HotkeyCaptureDialogState extends State<_HotkeyCaptureDialog> {
  final FocusNode _focusNode = FocusNode();
  var _hintKind = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return fluent.ContentDialog(
      title: Text(l10n.captureHotkeyDlgTitle),
      content: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) {
            return;
          }
          final isCtrl = HardwareKeyboard.instance.isControlPressed;
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          final key = _hotkeyValueFromLogical(event.logicalKey);
          if (isCtrl && isShift && key != null) {
            Navigator.of(context).pop(key);
            return;
          }
          setState(() {
            _hintKind = 1;
          });
        },
        child: SizedBox(
          width: 360,
          child: Text(
            _hintKind == 0
                ? context.l10n.captureHotkeyDlgHintInitial
                : context.l10n.captureHotkeyDlgHintRetry,
          ),
        ),
      ),
      actions: [
        fluent.Button(
          child: Text(context.l10n.commonCancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

String? _hotkeyValueFromLogical(LogicalKeyboardKey key) {
  final label = key.keyLabel.trim().toUpperCase();
  if (label.length != 1) {
    return null;
  }
  final unit = label.codeUnitAt(0);
  final isLetter = unit >= 0x41 && unit <= 0x5A;
  final isDigit = unit >= 0x30 && unit <= 0x39;
  if (!isLetter && !isDigit) {
    return null;
  }
  return label;
}

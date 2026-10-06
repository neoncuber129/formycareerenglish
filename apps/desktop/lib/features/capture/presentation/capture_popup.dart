import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/monetization/banner_ad_widget.dart';
import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:desktop/features/vocab/data/vocab_repository_impl.dart';
import 'package:desktop/features/settings/application/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/capture_controller.dart';
import '../application/focus_meaning_controller.dart';
import '../domain/focused_span.dart';
import 'capture_popup_layout.dart';
import 'capture_popup_ui_theme.dart';
import 'interactive_source_field.dart';
import 'meaning_panel.dart';

enum CapturePopupMode { text, image }

/// Chooses what source string should be persisted when user taps Save.
///
/// - If focus range is a strict subset of [passage], save [focus.focusedText].
/// - Otherwise (full-passage focus or invalid range), save the full [passage].
String resolvePopupSaveSource({
  required String passage,
  required FocusMeaningState focus,
}) {
  final trimmedPassage = passage.trim();
  final isStrictSubset = isPopupFocusStrictSubset(
    passage: passage,
    focus: focus,
  );
  if (isStrictSubset) {
    return focus.focusedText.trim();
  }
  return trimmedPassage;
}

bool isPopupFocusStrictSubset({
  required String passage,
  required FocusMeaningState focus,
}) {
  final start = focus.focusStart;
  final end = focus.focusEnd;
  final hasValidRange =
      passage.isNotEmpty && start >= 0 && end <= passage.length && start < end;
  return hasValidRange && (end - start) < passage.length;
}

class CapturePopup extends ConsumerStatefulWidget {
  const CapturePopup({
    required this.onClose,
    required this.mode,
    this.cursorPosition,
    this.selectedRegion,
    this.initialSourceText,
    this.nativeLanguage,
    this.sourceLanguages = const <String>[],
    this.initialTagSuggestions = const <String>[],
    this.sourceAppHint,
    this.sourceUrlHint,
    this.onSaveRequested,
    super.key,
  });

  final VoidCallback onClose;
  final CapturePopupMode mode;
  final Offset? cursorPosition;
  final Rect? selectedRegion;
  final String? initialSourceText;
  final String? nativeLanguage;
  final List<String> sourceLanguages;
  final List<String> initialTagSuggestions;
  final String? sourceAppHint;
  final String? sourceUrlHint;
  final Future<CapturePopupSaveResult> Function(
    CapturePopupSaveRequest request,
  )?
  onSaveRequested;

  @override
  ConsumerState<CapturePopup> createState() => _CapturePopupState();
}

class CapturePopupSaveResult {
  const CapturePopupSaveResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class CapturePopupSaveRequest {
  const CapturePopupSaveRequest({
    required this.state,
    required this.passage,
    required this.selectionStart,
    required this.selectionEnd,
    required this.sourceUrl,
  });

  final CaptureState state;
  final String passage;
  final int? selectionStart;
  final int? selectionEnd;
  final String sourceUrl;
}

class _CapturePopupState extends ConsumerState<CapturePopup> {
  bool _visible = false;
  bool _isClosing = false;
  bool _isExternalSaving = false;
  String? _externalMessage;
  bool _lastSaveSucceeded = false;
  TextSelection? _sourceInitialSelection;
  final TextEditingController _meaningEditController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final FocusNode _tagInputFocusNode = FocusNode();
  bool _meaningEdited = false;
  String _lastMeaningSeedKey = '';
  List<String> _draftTags = <String>[];
  List<String> _tagSuggestions = <String>[];
  bool _autoRecentTagEnabled = false;
  bool _showCaptureBanner = false;
  final DateTime _openedAt = DateTime.now();
  bool _firstVisibleLogged = false;
  double? _stablePopupWidth;
  static final List<String> _recentTagHistory = <String>[];

  Future<void> _reserveCapturePopupBannerIfNeeded() async {
    // macOS WebView banner in popup can render as a black block and break
    // perceived popup sizing; keep popup content-only on macOS.
    if (Platform.isMacOS) {
      return;
    }
    final allowed = await ref
        .read(appStateProvider.notifier)
        .tryReserveCapturePopupBannerSlot();
    if (!mounted || !allowed) {
      return;
    }
    setState(() => _showCaptureBanner = true);
  }

  @override
  void initState() {
    super.initState();
    _tagInputFocusNode.addListener(_handleTagInputFocusChanged);
    _visible = true;
    Future<void>.microtask(() async {
      TextSelection? bootSel;
      try {
        final focusNotifier = ref.read(focusMeaningProvider.notifier);
        focusNotifier.reset();
        final controller = ref.read(captureControllerProvider.notifier);
        await _applyCaptureLanguagePreferences(controller);
        unawaited(controller.warmupTranslationEngine());
        controller.prepareSession();
        switch (widget.mode) {
          case CapturePopupMode.text:
            final prefill = widget.initialSourceText?.trim();
            if (prefill != null && prefill.isNotEmpty) {
              await controller.captureWithPrefilledText(prefill);
            } else {
              await controller.captureTextModeAtCursor(
                cursorPosition: widget.cursorPosition,
              );
            }
          case CapturePopupMode.image:
            await controller.captureImageMode(region: widget.selectedRegion);
        }
        if (!mounted) {
          return;
        }
        final passage = ref.read(captureControllerProvider).sourceText;
        if (passage.trim().isEmpty) {
          ref.read(focusMeaningProvider.notifier).reset();
        } else {
          bootSel = await ref
              .read(focusMeaningProvider.notifier)
              .bootstrap(passage);
        }
      } catch (error, stack) {
        debugPrint('CapturePopup session failed: $error\n$stack');
      }
      if (!mounted) {
        return;
      }
      var autoRecentTag = false;
      try {
        autoRecentTag = await ref
            .read(settingsServiceProvider)
            .loadCapturePopupAutoRecentTag();
      } catch (_) {}
      if (!mounted) {
        return;
      }
      setState(() {
        _sourceInitialSelection = bootSel;
        final focusState = ref.read(focusMeaningProvider);
        final captureState = ref.read(captureControllerProvider);
        final seededMeaning = _seedMeaning(focusState, captureState);
        _meaningEditController.text = seededMeaning;
        _autoRecentTagEnabled = autoRecentTag;
        _draftTags = List<String>.from(captureState.tags);
        if (autoRecentTag &&
            _draftTags.isEmpty &&
            _recentTagHistory.isNotEmpty) {
          _draftTags = <String>[_recentTagHistory.first];
        }
        _tagSuggestions = widget.initialTagSuggestions
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false);
      });
      unawaited(_reserveCapturePopupBannerIfNeeded());
      unawaited(_loadTagSuggestions());
    });
  }

  @override
  void dispose() {
    _tagInputFocusNode.removeListener(_handleTagInputFocusChanged);
    _meaningEditController.dispose();
    _tagInputController.dispose();
    _tagInputFocusNode.dispose();
    super.dispose();
  }

  void _handleTagInputFocusChanged() {
    if (!_tagInputFocusNode.hasFocus) {
      _commitPendingTagInput();
    }
  }

  void _commitPendingTagInput() {
    final pending = _tagInputController.text.trim();
    if (pending.isEmpty) {
      return;
    }
    _addTagDraft(pending);
    _tagInputController.clear();
  }

  String _seedMeaning(FocusMeaningState focus, CaptureState capture) {
    final fromFocus = focus.translatedText.trim();
    if (fromFocus.isNotEmpty) {
      return fromFocus;
    }
    // Avoid flashing previous full-line translation when user picks a new span:
    // only reuse capture-level translation if focus still covers whole passage.
    final sourceText = capture.sourceText;
    final coversFullPassage =
        sourceText.isNotEmpty &&
        focus.focusStart == 0 &&
        focus.focusEnd == sourceText.length &&
        focus.focusedText.trim().isNotEmpty &&
        focus.focusedText.trim() == sourceText.trim();
    if (!coversFullPassage) {
      return '';
    }
    return capture.translatedText.trim();
  }

  String _resolveMeaningForSave(FocusMeaningState focus, CaptureState capture) {
    final typed = _meaningEditController.text.trim();
    if (typed.isNotEmpty) {
      return typed;
    }
    return _seedMeaning(focus, capture);
  }

  void _addTagDraft(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return;
    }
    final existing = _draftTags.where(
      (tag) => tag.toLowerCase() == normalized.toLowerCase(),
    );
    final canonical = existing.isNotEmpty ? existing.first : normalized;
    setState(() {
      // Product rule: each word can only have one tag.
      _draftTags = <String>[canonical];
    });
    _rememberRecentTag(canonical);
  }

  void _rememberRecentTag(String tag) {
    final normalized = tag.trim();
    if (normalized.isEmpty) {
      return;
    }
    _recentTagHistory.removeWhere(
      (value) => value.toLowerCase() == normalized.toLowerCase(),
    );
    _recentTagHistory.insert(0, normalized);
    if (_recentTagHistory.length > 20) {
      _recentTagHistory.removeRange(20, _recentTagHistory.length);
    }
  }

  Future<void> _loadTagSuggestions() async {
    List<String> loaded = <String>[];
    try {
      final all = await ref.read(vocabRepositoryProvider).getAllVocab();
      if (!mounted) {
        return;
      }
      final seen = <String>{};
      final ordered = <String>[];
      for (final vocab in all) {
        for (final tag in vocab.tags) {
          final trimmed = tag.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          final key = trimmed.toLowerCase();
          if (seen.add(key)) {
            ordered.add(trimmed);
          }
        }
      }
      ordered.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      loaded = ordered;
    } catch (_) {
      // Overlay isolate may not have repository dependencies initialized.
    }
    if (!mounted) {
      return;
    }
    final merged = <String>[..._tagSuggestions, ...loaded];
    final seen = <String>{};
    final deduped = <String>[];
    for (final tag in merged) {
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        deduped.add(tag);
      }
    }
    deduped.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _tagSuggestions = deduped;
    });
  }

  List<String> _orderedTagSuggestions() {
    final out = <String>[];
    final seen = <String>{};
    for (final recent in _recentTagHistory) {
      final key = recent.toLowerCase();
      if (seen.add(key)) {
        out.add(recent);
      }
    }
    for (final tag in _tagSuggestions) {
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        out.add(tag);
      }
    }
    return out;
  }

  void _removeTagDraft(String tag) {
    setState(() {
      _draftTags = _draftTags
          .where((value) => value.toLowerCase() != tag.toLowerCase())
          .toList(growable: false);
    });
  }

  void _fillRecentTagIfApplicable() {
    if (!_autoRecentTagEnabled || !mounted) {
      return;
    }
    if (_draftTags.isNotEmpty || _recentTagHistory.isEmpty) {
      return;
    }
    setState(() {
      _draftTags = <String>[_recentTagHistory.first];
    });
  }

  Future<void> _setAutoRecentTagEnabled(bool value) async {
    if (!mounted) {
      return;
    }
    setState(() => _autoRecentTagEnabled = value);
    await ref.read(settingsServiceProvider).setCapturePopupAutoRecentTag(value);
    if (!mounted) {
      return;
    }
    if (value) {
      _fillRecentTagIfApplicable();
    }
  }

  /// Keeps [CaptureController] in sync with saved settings. In-app overlay
  /// historically omitted [nativeLanguage]/[sourceLanguages], so the notifier
  /// kept stale defaults and the remote API used the wrong `langpair`.
  Future<void> _applyCaptureLanguagePreferences(
    CaptureController controller,
  ) async {
    var native = widget.nativeLanguage?.trim() ?? '';
    var sources = widget.sourceLanguages;
    if (native.isEmpty || sources.isEmpty) {
      final asyncSettings = ref.read(languageSettingsProvider);
      if (asyncSettings.hasValue) {
        final stored = asyncSettings.requireValue;
        if (native.isEmpty) {
          native = stored.nativeLanguage.trim().toLowerCase();
        }
        if (sources.isEmpty) {
          sources = stored.sourceLanguages;
        }
      }
    }
    if (native.isEmpty || sources.isEmpty) {
      try {
        final stored = await ref
            .read(languageSettingsProvider.future)
            .timeout(const Duration(seconds: 4));
        if (native.isEmpty) {
          native = stored.nativeLanguage.trim().toLowerCase();
        }
        if (sources.isEmpty) {
          sources = stored.sourceLanguages;
        }
      } on TimeoutException catch (_) {
        debugPrint('CapturePopup: language settings load timed out');
      } catch (e) {
        debugPrint('CapturePopup: language settings load failed: $e');
      }
    }
    if (native.isEmpty) {
      native = LanguageSettings.fallback.nativeLanguage;
    }
    final cleaned = sources
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final mergedSources = cleaned.isEmpty
        ? LanguageSettings.fallback.sourceLanguages
        : cleaned;
    controller.updateLanguagePreferences(
      nativeLanguage: native,
      sourceLanguages: mergedSources,
    );
  }

  void _closeNow() {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    widget.onClose();
  }

  Future<void> _handleSave() async {
    _commitPendingTagInput();
    final focus = ref.read(focusMeaningProvider);
    final base = ref.read(captureControllerProvider);
    final passage = base.sourceText;
    final sourceToSave = passage.trim();
    if (sourceToSave.isEmpty) {
      return;
    }
    final translated = _resolveMeaningForSave(focus, base);
    final pair = base.languagePair.trim().isNotEmpty
        ? base.languagePair
        : focus.languagePair;
    await _saveEntry(
      sourceText: sourceToSave,
      translatedText: translated,
      languagePair: pair,
      phonetic: base.phonetic,
      audioUrl: base.audioUrl,
      sourceLanguage: base.sourceLanguage,
      targetLanguage: base.targetLanguage,
      passage: passage,
      selectionStart: 0,
      selectionEnd: passage.length,
      tags: _draftTags,
    );
  }

  Future<void> _handleSaveSelection() async {
    _commitPendingTagInput();
    final focus = ref.read(focusMeaningProvider);
    final passage = ref.read(captureControllerProvider).sourceText;
    final hasSelection = isPopupFocusStrictSubset(
      passage: passage,
      focus: focus,
    );
    if (!focus.canSave || !hasSelection) {
      return;
    }
    await _saveEntry(
      sourceText: focus.focusedText.trim(),
      translatedText: _resolveMeaningForSave(
        focus,
        ref.read(captureControllerProvider),
      ),
      languagePair: focus.languagePair,
      phonetic: focus.phonetic,
      audioUrl: focus.audioUrl,
      sourceLanguage: focus.sourceLanguage,
      targetLanguage: focus.targetLanguage,
      passage: passage,
      selectionStart: focus.focusStart,
      selectionEnd: focus.focusEnd,
      partOfSpeechExtra: focus.partOfSpeech,
      tags: _draftTags,
    );
  }

  Future<void> _selectWholeLine() async {
    final passage = ref.read(captureControllerProvider).sourceText;
    final trimmed = passage.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final selection = TextSelection(
      baseOffset: 0,
      extentOffset: passage.length,
    );
    if (mounted) {
      setState(() {
        _sourceInitialSelection = selection;
      });
    }
    await ref
        .read(focusMeaningProvider.notifier)
        .resolveSpan(
          FocusedSpan(text: passage, start: 0, end: passage.length),
          passage,
        );
  }

  Future<void> _saveEntry({
    required String sourceText,
    required String translatedText,
    required String languagePair,
    required String phonetic,
    required String audioUrl,
    required String sourceLanguage,
    required String targetLanguage,
    required String passage,
    int? selectionStart,
    int? selectionEnd,
    String partOfSpeechExtra = '',
    List<String> tags = const <String>[],
  }) async {
    if (sourceText.trim().isEmpty || translatedText.trim().isEmpty) {
      return;
    }
    if (widget.onSaveRequested == null) {
      final saveResult = await ref
          .read(captureControllerProvider.notifier)
          .saveFocusedFragment(
            sourceText: sourceText,
            translatedText: translatedText,
            languagePair: languagePair,
            passageForContext: passage,
            selectionStart: selectionStart,
            selectionEnd: selectionEnd,
            phoneticExtra: phonetic,
            audioUrlExtra: audioUrl,
            partOfSpeechExtra: partOfSpeechExtra,
            tags: tags,
            sourceApp: widget.sourceAppHint?.trim() ?? '',
            sourceUrl: widget.sourceUrlHint?.trim() ?? '',
          );
      if (!mounted) {
        return;
      }
      final lim = ref.read(appStateProvider).freeDailyVocabSaveLimit;
      setState(() {
        _lastSaveSucceeded = saveResult.success;
        _externalMessage = saveResult.dailySaveQuotaExceeded
            ? context.l10n.captureDailySaveLimitReached(lim)
            : saveResult.success
            ? context.l10n.captureSavedToast
            : saveResult.message;
      });
      return;
    }

    setState(() {
      _isExternalSaving = true;
      _externalMessage = null;
      _lastSaveSucceeded = false;
    });
    final base = ref.read(captureControllerProvider);
    final merged = base.copyWith(
      sourceText: sourceText,
      translatedText: translatedText,
      phonetic: phonetic,
      audioUrl: audioUrl,
      languagePair: languagePair,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      tags: tags,
      sourceApp: widget.sourceAppHint?.trim() ?? '',
    );
    final result = await widget.onSaveRequested!(
      CapturePopupSaveRequest(
        state: merged,
        passage: passage,
        selectionStart: selectionStart,
        selectionEnd: selectionEnd,
        sourceUrl: widget.sourceUrlHint?.trim() ?? '',
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isExternalSaving = false;
      _lastSaveSucceeded = result.success;
      _externalMessage = result.message;
    });
  }

  double _resolveMeasuredPopupWidth({
    required ThemeData theme,
    required TextScaler baseScaler,
    required AppLocalizations l10n,
    required double outerPad,
    required double tf,
    required String passage,
    required FocusMeaningState focus,
    required bool hasWholeLineButton,
    required bool showPassageListen,
    required double textScaleFactor,
  }) {
    final scaler = _CapturePopupRelativeTextScaler(
      baseScaler,
      textScaleFactor,
    );
    return capturePopupResolvePreferredWidth(
      theme: theme,
      textScaler: scaler,
      l10n: l10n,
      outerPad: outerPad,
      tf: tf,
      passage: passage,
      focus: focus,
      sourceText: passage,
      hasWholeLineButton: hasWholeLineButton,
      showPassageListen: showPassageListen,
    );
  }

  /// Keeps the widest width requested so far so bootstrap frames (empty passage,
  /// loading flags, outer-theme mismatch) cannot lock a column narrower than
  /// chrome built under [capturePopupUiThemeData].
  double _resolveStablePopupWidth(double measured) {
    final prev = _stablePopupWidth;
    final next = math.max(prev ?? measured, measured);
    _stablePopupWidth = next;
    return next;
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstVisibleLogged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _firstVisibleLogged) {
          return;
        }
        _firstVisibleLogged = true;
        final firstVisibleMs = DateTime.now().difference(_openedAt).inMilliseconds;
        debugPrint('popup_dbg first_visible_ms=$firstVisibleMs');
      });
    }
    final passage = ref.watch(
      captureControllerProvider.select((s) => s.sourceText),
    );
    final captureTranslated = ref.watch(
      captureControllerProvider.select((s) => s.translatedText),
    );
    final focus = ref.watch(focusMeaningProvider);
    final hasSpecificSelection = isPopupFocusStrictSubset(
      passage: passage,
      focus: focus,
    );
    final showPassageListen =
        passage.isNotEmpty &&
        !focus.isLoading &&
        focus.focusStart >= 0 &&
        focus.focusEnd <= passage.length &&
        focus.focusStart < focus.focusEnd &&
        (focus.focusEnd - focus.focusStart) >= passage.length;

    final captureMessage = ref.watch(
      captureControllerProvider.select((s) => s.message),
    );
    final isSaving =
        ref.watch(captureControllerProvider.select((s) => s.isSaving)) ||
        _isExternalSaving;
    final effectiveMessage = _externalMessage ?? captureMessage;
    final shell = capturePopupShellLayout(context);
    final outerPad = shell.outerPad;
    final tf = capturePopupLayoutFactor(context);
    final mq = MediaQuery.of(context);
    const adaptiveScale = 0.97;
    return MediaQuery(
      data: mq.copyWith(
        textScaler: _CapturePopupRelativeTextScaler(
          mq.textScaler,
          adaptiveScale,
        ),
      ),
      child: Theme(
        data: capturePopupUiThemeData(),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final loc = context.l10n;
            final measuredPopupWidth = _resolveMeasuredPopupWidth(
              theme: theme,
              baseScaler: mq.textScaler,
              l10n: loc,
              outerPad: outerPad,
              tf: tf,
              passage: passage,
              focus: focus,
              hasWholeLineButton: hasSpecificSelection,
              showPassageListen: showPassageListen,
              textScaleFactor: adaptiveScale,
            );
            final popupWidth = _resolveStablePopupWidth(measuredPopupWidth);
            final cs = theme.colorScheme;
            final shellFill = cs.surface;
            final iconS = (16 * tf).clamp(14.0, 28.0);

            final saveAction = FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () => unawaited(
                      hasSpecificSelection
                          ? _handleSaveSelection()
                          : _handleSave(),
                    ),
              icon: Icon(Icons.bookmark_add_outlined, size: iconS),
              label: Text(
                hasSpecificSelection
                    ? loc.captureSavePhrase
                    : loc.captureSaveLine,
              ),
            );

            return TapRegion(
              onTapOutside: (_) {
                _closeNow();
              },
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shellFill,
                      border: Border.all(color: cs.outline),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: popupWidth,
                          maxWidth: popupWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(outerPad),
                          child: Builder(
                            builder: (context) {
                              final gapPanels = 8 * tf.clamp(0.9, 1.2);
                              final seededMeaning = _seedMeaning(
                                focus,
                                ref.read(captureControllerProvider),
                              );
                              final meaningSeedKey = [
                                focus.focusStart,
                                focus.focusEnd,
                                focus.focusedText.trim(),
                                focus.translatedText.trim(),
                                captureTranslated.trim(),
                              ].join('|');
                              final selectionChanged =
                                  _lastMeaningSeedKey != meaningSeedKey;
                              if (selectionChanged) {
                                _lastMeaningSeedKey = meaningSeedKey;
                                _meaningEdited = false;
                                _meaningEditController.text = seededMeaning;
                              } else if (!_meaningEdited &&
                                  seededMeaning.isNotEmpty &&
                                  _meaningEditController.text.trim().isEmpty) {
                                _meaningEditController.text = seededMeaning;
                              }

                              return AnimatedSize(
                                duration: const Duration(
                                  milliseconds: 220,
                                ),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topLeft,
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                          _SourceSectionCard(
                                            passage: passage,
                                            focus: focus,
                                            hasSpecificSelection:
                                                hasSpecificSelection,
                                            showPassageListen:
                                                showPassageListen,
                                            initialSelection:
                                                _sourceInitialSelection,
                                            onWholeLine: () =>
                                                unawaited(_selectWholeLine()),
                                            onClose: _closeNow,
                                          ),
                                          SizedBox(height: gapPanels),
                                          _MeaningSectionCard(
                                            meaningController:
                                                _meaningEditController,
                                            onMeaningChanged: () {
                                              _meaningEdited = true;
                                            },
                                          ),
                                          _PopupSaveCustomizationSection(
                                            tagInputController:
                                                _tagInputController,
                                            tagInputFocusNode:
                                                _tagInputFocusNode,
                                            tags: _draftTags,
                                            suggestions:
                                                _orderedTagSuggestions(),
                                            onAddTag: _addTagDraft,
                                            onRemoveTag: _removeTagDraft,
                                            autoRecentTagEnabled:
                                                _autoRecentTagEnabled,
                                            onAutoRecentTagChanged: (on) =>
                                                unawaited(
                                                  _setAutoRecentTagEnabled(on),
                                                ),
                                            recentTagHistoryAvailable:
                                                _recentTagHistory.isNotEmpty,
                                          ),
                                          SizedBox(
                                            height: 8 * tf.clamp(0.9, 1.2),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: saveAction,
                                          ),
                                          if (effectiveMessage != null &&
                                              effectiveMessage
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            SizedBox(
                                              height: 8 * tf.clamp(0.9, 1.2),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                effectiveMessage,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: _lastSaveSucceeded
                                                          ? Colors.green
                                                          : theme
                                                                .colorScheme
                                                                .error,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                          if (_showCaptureBanner &&
                                              !Platform.isMacOS) ...[
                                            Divider(
                                              height: 16 * tf.clamp(0.9, 1.2),
                                              thickness: 1,
                                            ),
                                            BannerAdWidget(
                                              isPro: ref.watch(
                                                appStateProvider.select(
                                                  (s) => s.isPro,
                                                ),
                                              ),
                                              adUrl: ref.watch(
                                                appStateProvider.select(
                                                  (s) => s.adUrl,
                                                ),
                                              ),
                                              height: (56 * tf).clamp(
                                                48.0,
                                                72.0,
                                              ),
                                            ),
                                          ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CapturePopupRelativeTextScaler extends TextScaler {
  // ignore: prefer_const_constructors_in_immutables — holds non-const [TextScaler].
  _CapturePopupRelativeTextScaler(this._parent, this._factor) : super();

  final TextScaler _parent;
  final double _factor;

  @override
  double scale(double fontSize) => _parent.scale(fontSize) * _factor;

  @override
  @Deprecated(
    'Use scale() instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support.',
  )
  double get textScaleFactor => _parent.textScaleFactor * _factor;

  @override
  bool operator ==(Object other) {
    return other is _CapturePopupRelativeTextScaler &&
        other._parent == _parent &&
        other._factor == _factor;
  }

  @override
  int get hashCode => Object.hash(_parent, _factor);
}

class _SourceSectionCard extends ConsumerWidget {
  const _SourceSectionCard({
    required this.passage,
    required this.focus,
    required this.hasSpecificSelection,
    required this.showPassageListen,
    required this.initialSelection,
    required this.onWholeLine,
    required this.onClose,
  });

  final String passage;
  final FocusMeaningState focus;
  final bool hasSpecificSelection;
  final bool showPassageListen;
  final TextSelection? initialSelection;
  final VoidCallback onWholeLine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tf = capturePopupLayoutFactor(context);
    final iconS = (15 * tf).clamp(13.0, 24.0);
    final sectionFill = capturePopupSectionBackground(context);
    final syncedSelection =
        hasSpecificSelection &&
            focus.focusStart >= 0 &&
            focus.focusEnd <= passage.length &&
            focus.focusStart < focus.focusEnd
        ? TextSelection(
            baseOffset: focus.focusStart,
            extentOffset: focus.focusEnd,
          )
        : null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (2 * tf).clamp(1.0, 4.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              if (hasSpecificSelection)
                TextButton.icon(
                  onPressed: focus.isLoading ? null : onWholeLine,
                  icon: Icon(Icons.wrap_text_rounded, size: iconS),
                  label: Text(l10n.captureWholeLine),
                ),
              if (showPassageListen) ...[
                SizedBox(width: 4 * tf.clamp(0.85, 1.35)),
                MeaningPlayButton(
                  text: passage,
                  language: focus.sourceLanguage.trim().isEmpty
                      ? 'en'
                      : focus.sourceLanguage.trim(),
                  audioUrl: null,
                  tooltip: l10n.captureListenSource,
                  pauseTooltip: l10n.meaningPause,
                ),
              ],
              SizedBox(width: 4 * tf.clamp(0.85, 1.35)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: iconS),
              ),
            ],
          ),
          SizedBox(height: 8 * tf.clamp(0.9, 1.2)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: ColoredBox(
              color: sectionFill,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (8 * tf).clamp(5.0, 14.0),
                  vertical: (7 * tf).clamp(5.0, 12.0),
                ),
                child: _InteractiveSourceSection(
                  initialSelection: initialSelection,
                  selectionOverride: syncedSelection,
                ),
              ),
            ),
          ),
          Divider(
            color: cs.outlineVariant,
            height: (14 * tf).clamp(10.0, 20.0),
          ),
        ],
      ),
    );
  }
}

class _MeaningSectionCard extends StatelessWidget {
  const _MeaningSectionCard({
    required this.meaningController,
    required this.onMeaningChanged,
  });

  final TextEditingController meaningController;
  final VoidCallback onMeaningChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tf = capturePopupLayoutFactor(context);
    final mq = MediaQuery.of(context);
    final meaningViewportMax =
        math.min(420.0, mq.size.height * 0.38).clamp(160.0, 720.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (2 * tf).clamp(1.0, 4.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: meaningViewportMax),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: MeaningPanel(
                editableMeaningController: meaningController,
                onMeaningChanged: onMeaningChanged,
              ),
            ),
          ),
          Divider(
            color: cs.outlineVariant,
            height: (14 * tf).clamp(10.0, 20.0),
          ),
        ],
      ),
    );
  }
}

class _InteractiveSourceSection extends ConsumerWidget {
  const _InteractiveSourceSection({
    required this.initialSelection,
    required this.selectionOverride,
  });

  final TextSelection? initialSelection;
  final TextSelection? selectionOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final passage = ref.watch(
      captureControllerProvider.select((s) => s.sourceText),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (passage.isEmpty) {
      return Text(
        l10n.captureNoTextDetected,
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return InteractiveSourceField(
      key: ValueKey<String>(passage),
      passage: passage,
      initialSelection: initialSelection,
      selectionOverride: selectionOverride,
      onFragmentCommitted: (FocusedSpan span) {
        unawaited(
          ref.read(focusMeaningProvider.notifier).resolveSpan(span, passage),
        );
      },
    );
  }
}

class _PopupSaveCustomizationSection extends StatefulWidget {
  const _PopupSaveCustomizationSection({
    required this.tagInputController,
    required this.tagInputFocusNode,
    required this.tags,
    required this.suggestions,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.autoRecentTagEnabled,
    required this.onAutoRecentTagChanged,
    required this.recentTagHistoryAvailable,
  });

  final TextEditingController tagInputController;
  final FocusNode tagInputFocusNode;
  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final bool autoRecentTagEnabled;
  final ValueChanged<bool> onAutoRecentTagChanged;
  final bool recentTagHistoryAvailable;

  @override
  State<_PopupSaveCustomizationSection> createState() =>
      _PopupSaveCustomizationSectionState();
}

class _PopupSaveCustomizationSectionState
    extends State<_PopupSaveCustomizationSection> {
  final GlobalKey _tagInputAnchorKey = GlobalKey();

  Future<void> _openTagSuggestionsMenu() async {
    final selectable = widget.suggestions
        .where((tag) {
          final key = tag.toLowerCase();
          return !widget.tags.any((picked) => picked.toLowerCase() == key);
        })
        .toList(growable: false);
    if (selectable.isEmpty) {
      return;
    }
    final anchorContext = _tagInputAnchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy,
      ),
      items: selectable
          .map(
            (tag) => PopupMenuItem<String>(
              value: tag,
              child: Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null || selected.trim().isEmpty) {
      return;
    }
    widget.onAddTag(selected);
    widget.tagInputController.clear();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _PopupSaveCustomizationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtleText = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.72),
      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * 0.94,
      height: 1.2,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.tags.isEmpty)
            KeyedSubtree(
              key: _tagInputAnchorKey,
              child: TextField(
                controller: widget.tagInputController,
                focusNode: widget.tagInputFocusNode,
                onTap: () => unawaited(_openTagSuggestionsMenu()),
                onSubmitted: (value) {
                  widget.onAddTag(value);
                  widget.tagInputController.clear();
                },
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.captureAddTagLabel,
                  hintText: l10n.captureTagHint,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onPressed: () => unawaited(_openTagSuggestionsMenu()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          widget.onAddTag(widget.tagInputController.text);
                          widget.tagInputController.clear();
                          widget.tagInputFocusNode.requestFocus();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.tags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () => widget.onRemoveTag(tag),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () =>
                widget.onAutoRecentTagChanged(!widget.autoRecentTagEnabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.captureAutoRecentTag, style: subtleText),
                  ),
                  Transform.scale(
                    scale: 0.72,
                    alignment: Alignment.centerRight,
                    child: Switch.adaptive(
                      value: widget.autoRecentTagEnabled,
                      onChanged: widget.onAutoRecentTagChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.autoRecentTagEnabled &&
              widget.tags.isEmpty &&
              !widget.recentTagHistoryAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.captureNoRecentTagsYet,
                style: subtleText,
              ),
            ),
        ],
      ),
    );
  }
}

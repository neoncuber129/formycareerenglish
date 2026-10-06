import 'dart:async';
import 'dart:ui' as ui;

import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:flutter/material.dart';

import '../domain/focused_span.dart';

/// Read-only text field with native selection; commits a substring after
/// debounced selection changes or immediately on pointer up.
class InteractiveSourceField extends StatefulWidget {
  const InteractiveSourceField({
    required this.passage,
    required this.onFragmentCommitted,
    this.initialSelection,
    this.selectionOverride,
    this.onInteraction,
    super.key,
  });

  final String passage;
  final ValueChanged<FocusedSpan> onFragmentCommitted;
  final TextSelection? initialSelection;
  final TextSelection? selectionOverride;
  final VoidCallback? onInteraction;

  @override
  State<InteractiveSourceField> createState() => _InteractiveSourceFieldState();
}

class _InteractiveSourceFieldState extends State<InteractiveSourceField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _applyingSelection = false;
  bool _pointerSelecting = false;
  TextSelection? _lastEmittedNormalized;
  bool _commitsEnabled = false;
  static const Duration _debounceDuration = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'InteractiveSourceField');
    _controller = TextEditingController(text: widget.passage);
    _applyingSelection = true;
    _controller.selection = const TextSelection.collapsed(offset: 0);
    _applyingSelection = false;
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyInitialSelection(),
    );
  }

  void _applyInitialSelection() {
    if (!mounted) return;
    final sel = widget.selectionOverride ?? widget.initialSelection;
    _applyingSelection = true;
    if (sel != null && sel.isValid) {
      final normalized = TextSelection(
        baseOffset: sel.baseOffset.clamp(0, _controller.text.length),
        extentOffset: sel.extentOffset.clamp(0, _controller.text.length),
      );
      _controller.selection = normalized;
      _lastEmittedNormalized = normalized;
    } else {
      _controller.selection = const TextSelection.collapsed(offset: 0);
    }
    _applyingSelection = false;
    _commitsEnabled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveSourceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage) {
      _applyingSelection = true;
      _controller.text = widget.passage;
      _controller.selection = TextSelection.collapsed(offset: 0);
      _applyingSelection = false;
      _lastEmittedNormalized = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyInitialSelection(),
      );
    } else if (oldWidget.initialSelection != widget.initialSelection ||
        oldWidget.selectionOverride != widget.selectionOverride) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyInitialSelection(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_applyingSelection || !_commitsEnabled) return;
    if (_pointerSelecting) {
      _debounce?.cancel();
      return;
    }
    widget.onInteraction?.call();
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _commitAfterDebounce);
  }

  void _commitAfterDebounce() {
    if (!mounted) return;
    _normalizeCollapsedToWord();
    _emitFragmentNow();
  }

  void _normalizeCollapsedToWord() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || text.isEmpty) return;
    if (!sel.isCollapsed) return;
    final expanded = expandWordSelection(text, sel.extentOffset);
    if (expanded.baseOffset == sel.baseOffset &&
        expanded.extentOffset == sel.extentOffset) {
      return;
    }
    _applyingSelection = true;
    _controller.selection = expanded;
    _applyingSelection = false;
  }

  void _emitFragmentNow() {
    if (!_commitsEnabled) return;
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || text.isEmpty) return;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    if (start >= end) return;
    final fragment = text.substring(start, end);
    final normalized = TextSelection(baseOffset: start, extentOffset: end);
    if (_lastEmittedNormalized?.baseOffset == normalized.baseOffset &&
        _lastEmittedNormalized?.extentOffset == normalized.extentOffset) {
      return;
    }
    _lastEmittedNormalized = normalized;
    widget.onFragmentCommitted(
      FocusedSpan(text: fragment, start: start, end: end),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerSelecting = true;
    _debounce?.cancel();
    _focusNode.requestFocus();
  }

  void _onPointerUp(PointerEvent event) {
    _pointerSelecting = false;
    _focusNode.requestFocus();
    widget.onInteraction?.call();
    _debounce?.cancel();
    _normalizeCollapsedToWord();
    _emitFragmentNow();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerSelecting = false;
    _debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final selectionFill = capturePopupSourceSelectionFill(context);
    final selectionHandle = capturePopupSourceSelectionHandle(context);
    return DefaultSelectionStyle.merge(
      selectionColor: selectionFill,
      cursorColor: selectionHandle,
      child: Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: selectionFill,
            selectionHandleColor: selectionHandle,
            cursorColor: selectionHandle,
          ),
        ),
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: TextField(
            focusNode: _focusNode,
            autofocus: true,
            controller: _controller,
            readOnly: true,
            maxLines: null,
            minLines: 1,
            enableInteractiveSelection: true,
            style: (tt.bodyLarge ?? tt.bodyMedium)?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.justify,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            cursorWidth: 0,
            showCursor: false,
            selectionHeightStyle: ui.BoxHeightStyle.max,
            selectionWidthStyle: ui.BoxWidthStyle.max,
            selectionControls: materialTextSelectionControls,
          ),
        ),
      ),
    );
  }
}

/// Expands [offset] to a Unicode "word" span; collapsed if no letter run.
TextSelection expandWordSelection(String text, int offset) {
  if (text.isEmpty) {
    return const TextSelection.collapsed(offset: 0);
  }
  final o = offset.clamp(0, text.length);
  final regex = RegExp(r"\p{L}+(?:['-]\p{L}+)?", unicode: true);
  for (final m in regex.allMatches(text)) {
    if (o >= m.start && o <= m.end) {
      return TextSelection(baseOffset: m.start, extentOffset: m.end);
    }
  }
  return TextSelection.collapsed(offset: o);
}

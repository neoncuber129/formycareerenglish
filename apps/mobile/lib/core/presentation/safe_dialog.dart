import 'package:flutter/material.dart';

/// Drops focus from the current field, then waits until after the next frame.
///
/// Call before [showDialog] when another [TextField] (e.g. in a bottom sheet)
/// may still own the IME; otherwise Android often cancels keyboard show with
/// `ImeTracker ... onCancelled at PHASE_CLIENT_APPLY_ANIMATION`.
Future<void> unfocusForIncomingDialog() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await WidgetsBinding.instance.endOfFrame;
}

/// Unfocus IME then [Navigator.pop] on the next frame — avoids Android UI
/// hangs when closing dialogs that had a focused [TextField].
void safeNavigatorPop<T>(BuildContext context, [T? result]) {
  FocusManager.instance.primaryFocus?.unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).pop<T>(result);
    }
  });
}

/// Single-line [AlertDialog] whose [TextEditingController] is owned by [State]
/// and closed only via [safeNavigatorPop].
Future<String?> showSafeSingleLineInputDialog(
  BuildContext context, {
  required String title,
  String? labelText,
  String? hintText,
  String initialValue = '',
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<String?>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (_) => _SafeSingleLineInputAlert(
      title: title,
      labelText: labelText,
      hintText: hintText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _SafeSingleLineInputAlert extends StatefulWidget {
  const _SafeSingleLineInputAlert({
    required this.title,
    this.labelText,
    this.hintText,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String? labelText;
  final String? hintText;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_SafeSingleLineInputAlert> createState() =>
      _SafeSingleLineInputAlertState();
}

class _SafeSingleLineInputAlertState extends State<_SafeSingleLineInputAlert> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
        onSubmitted: (_) =>
            safeNavigatorPop(context, _controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => safeNavigatorPop<String?>(context, null),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () =>
              safeNavigatorPop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

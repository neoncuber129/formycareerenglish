import 'package:app_l10n/app_l10n.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:shared_models/shared_models.dart';

/// Configure a custom study session before opening [SrsReviewScreen].
Future<CustomStudyOptions?> showCustomStudyOptionsDialog(
  fluent.BuildContext context, {
  required CustomStudyOptions initial,
  required int entryCount,
}) {
  return fluent.showDialog<CustomStudyOptions>(
    context: context,
    builder: (ctx) => _CustomStudyDialogBody(
      initial: initial,
      entryCount: entryCount,
    ),
  );
}

class _CustomStudyDialogBody extends StatefulWidget {
  const _CustomStudyDialogBody({
    required this.initial,
    required this.entryCount,
  });

  final CustomStudyOptions initial;
  final int entryCount;

  @override
  State<_CustomStudyDialogBody> createState() => _CustomStudyDialogBodyState();
}

class _CustomStudyDialogBodyState extends State<_CustomStudyDialogBody> {
  late final TextEditingController _maxController;
  late bool _orderRandom;
  late bool _cram;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _maxController = TextEditingController(
      text: i.maxCards != null && i.maxCards! > 0 ? '${i.maxCards}' : '',
    );
    _orderRandom = i.order == CustomStudyOrder.random;
    _cram = !i.respectScheduling;
  }

  @override
  void dispose() {
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return fluent.ContentDialog(
      title: Text(l10n.customStudyTitle),
      content: fluent.Column(
        mainAxisSize: fluent.MainAxisSize.min,
        crossAxisAlignment: fluent.CrossAxisAlignment.start,
        children: [
          Text(l10n.customStudyEntriesCount(widget.entryCount)),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: l10n.customStudyMaxLabel,
            child: fluent.TextBox(
              controller: _maxController,
              placeholder: l10n.customStudyMaxPlaceholder,
            ),
          ),
          const SizedBox(height: 8),
          fluent.ToggleSwitch(
            content: Text(l10n.customStudyRandomOrder),
            checked: _orderRandom,
            onChanged: (v) => setState(() => _orderRandom = v),
          ),
          fluent.ToggleSwitch(
            content: Text(l10n.customStudyCram),
            checked: _cram,
            onChanged: (v) => setState(() => _cram = v),
          ),
        ],
      ),
      actions: [
        fluent.Button(
          child: Text(l10n.commonCancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        fluent.FilledButton(
          child: Text(l10n.customStudyStart),
          onPressed: () {
            final raw = _maxController.text.trim();
            int? maxCards;
            if (raw.isNotEmpty) {
              maxCards = int.tryParse(raw);
              if (maxCards != null && maxCards <= 0) {
                maxCards = null;
              }
            }
            Navigator.of(context).pop(
              CustomStudyOptions(
                maxCards: maxCards,
                order: _orderRandom
                    ? CustomStudyOrder.random
                    : CustomStudyOrder.dueOrder,
                respectScheduling: !_cram,
              ),
            );
          },
        ),
      ],
    );
  }
}

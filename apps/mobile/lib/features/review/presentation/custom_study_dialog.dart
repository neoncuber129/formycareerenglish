import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

Future<CustomStudyOptions?> showCustomStudyOptionsDialog(
  BuildContext context, {
  required CustomStudyOptions initial,
  required int entryCount,
}) {
  return showDialog<CustomStudyOptions>(
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
    return AlertDialog(
      title: const Text('Custom study'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entries matching your selection: ${widget.entryCount}'),
            const SizedBox(height: 12),
            TextField(
              controller: _maxController,
              decoration: const InputDecoration(
                labelText: 'Max cards (empty = all)',
                hintText: 'e.g. 50',
              ),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('Random order'),
              value: _orderRandom,
              onChanged: (v) => setState(() => _orderRandom = v),
            ),
            SwitchListTile(
              title: const Text('Cram (do not save scheduling)'),
              value: _cram,
              onChanged: (v) => setState(() => _cram = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
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
          child: const Text('Start'),
        ),
      ],
    );
  }
}

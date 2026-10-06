import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../application/review_controller.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(reviewControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final controller = ref.read(reviewControllerProvider.notifier);
    final card = state.currentCard;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard Review')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.hasFinished
              ? Center(
                  child: Text(
                    'Completed ${state.answeredCount}/${state.totalCards} cards.',
                  ),
                )
              : state.cards.isEmpty
                  ? const Center(child: Text('No cards due right now.'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.sourceOptions.isNotEmpty) ...[
                            DropdownButtonFormField<String?>(
                              initialValue: state.sourceFilter,
                              decoration: const InputDecoration(
                                labelText: 'Source filter',
                                border: OutlineInputBorder(),
                              ),
                              items: <DropdownMenuItem<String?>>[
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All sources'),
                                ),
                                ...state.sourceOptions.map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s,
                                    child: Text(
                                      s,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  unawaited(controller.setSourceFilter(v)),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            'Progress: ${state.answeredCount}/${state.cards.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Card(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!state.isFlipped) ...[
                                      if (card != null &&
                                          card.originalSentence
                                              .trim()
                                              .isNotEmpty) ...[
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: formatClozeSentence(
                                            sentence:
                                                card.originalSentence.trim(),
                                            term: card.sourceText.trim(),
                                            baseStyle: Theme.of(context)
                                                .textTheme
                                                .headlineSmall!,
                                            clozeStyle: Theme.of(context)
                                                .textTheme
                                                .headlineSmall!
                                                .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                            ),
                                          ),
                                        ),
                                        if (countClozeMatches(
                                              card.originalSentence.trim(),
                                              card.sourceText.trim(),
                                            ) >
                                            0) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Cloze from saved sentence',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ] else
                                        Text(
                                          card?.sourceText ?? '',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                    ] else ...[
                                      Text(
                                        card?.translatedText ?? '',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      if (card != null &&
                                          card.phonetic.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          card.phonetic,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ],
                                      if (card != null &&
                                          card.partOfSpeech
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          card.partOfSpeech,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ],
                                      if (card != null &&
                                          card.imageAnchor
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        _ReviewImagePreview(path: card.imageAnchor),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!state.isFlipped)
                            ElevatedButton(
                              onPressed: controller.toggleFlip,
                              child: const Text('Tap to reveal'),
                            ),
                          if (state.isFlipped)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        controller.answer(ReviewGrade.again),
                                    child: const Text('Again'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        controller.answer(ReviewGrade.good),
                                    child: const Text('Good'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        controller.answer(ReviewGrade.easy),
                                    child: const Text('Easy'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
    );
  }
}

class _ReviewImagePreview extends StatelessWidget {
  const _ReviewImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          height: 160,
          fit: BoxFit.contain,
        ),
      );
    }
    return Text(
      'Image not available on this device.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

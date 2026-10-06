import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../../../core/presentation/mobile_layout.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import '../application/gtx_translation.dart';

class ManualCapturePage extends ConsumerStatefulWidget {
  const ManualCapturePage({super.key, this.initialSourceText});

  final String? initialSourceText;

  @override
  ConsumerState<ManualCapturePage> createState() => _ManualCapturePageState();
}

class _ManualCapturePageState extends ConsumerState<ManualCapturePage> {
  final _sourceCtrl = TextEditingController();
  final _transCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _sourceAppCtrl = TextEditingController(text: 'Mobile capture');
  final _translator = GtxTranslation();
  bool _busy = false;
  String _message = '';
  /// Set after a successful **Translate** (auto-detect → pair for save / TTS).
  String? _pairSourceCode;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialSourceText?.trim();
    if (seed != null && seed.isNotEmpty) {
      _sourceCtrl.text = seed;
    }
  }

  @override
  void dispose() {
    _translator.dispose();
    _sourceCtrl.dispose();
    _transCtrl.dispose();
    _tagsCtrl.dispose();
    _sourceAppCtrl.dispose();
    super.dispose();
  }

  String _pairFor(String sourceCode, String nativeCode) {
    final s = sourceCode.trim().toLowerCase();
    final n = nativeCode.trim().toLowerCase();
    if (s.isEmpty || n.isEmpty) {
      return 'en-vi';
    }
    return '$s-$n';
  }

  Future<void> _translate(LanguageSettings lang) async {
    final text = _sourceCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _message = 'Enter source text first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = '';
    });
    final target = lang.nativeLanguage;
    final result = await _translator.translateLineDetailed(
      text: text,
      sourceLanguage: 'auto',
      targetLanguage: target,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.translatedText.isEmpty) {
        _message = 'Translation failed. Check network or language pair.';
      } else {
        _transCtrl.text = result.translatedText;
        _pairSourceCode = pairSourceCodeFromGoogleDetect(result.detectedSource);
        _message = '';
      }
    });
  }

  Future<void> _save(LanguageSettings lang) async {
    final source = _sourceCtrl.text.trim();
    final trans = _transCtrl.text.trim();
    if (source.isEmpty || trans.isEmpty) {
      setState(() => _message = 'Source and translation are required.');
      return;
    }
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final pair = _pairFor(
        _pairSourceCode ?? 'en',
        lang.nativeLanguage,
      );
      final tagRaw = _tagsCtrl.text.split(',');
      final tags = tagRaw
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .take(1)
          .toList();
      final vocab = Vocab.initial(
        id: const Uuid().v4(),
        sourceText: source,
        translatedText: trans,
        languagePair: pair,
        sourceApp: _sourceAppCtrl.text.trim(),
        tags: tags,
      );
      await ref.read(vocabRepositoryProvider).saveVocab(vocab);
      ref.invalidate(vocabListProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Save failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langAsync = ref.watch(languageSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add word')),
      body: langAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Settings error: $e')),
        data: (lang) {
          final g = MobileLayout.gutter(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(g, 16, g, 28),
            children: [
              Text(
                'Type text, tap Translate, then save.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceCtrl,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Source text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : () => _translate(lang),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate),
                label: const Text('Translate'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _transCtrl,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Translation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tag (one, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceAppCtrl,
                decoration: const InputDecoration(
                  labelText: 'Source label',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pair: ${_pairSourceCode ?? '—'} → ${lang.nativeLanguage}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _save(lang),
                child: const Text('Save word'),
              ),
            ],
          );
        },
      ),
    );
  }
}

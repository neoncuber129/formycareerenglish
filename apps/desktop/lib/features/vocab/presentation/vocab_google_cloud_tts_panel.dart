import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/features/vocab/application/google_cloud_tts_credentials_store.dart';
import 'package:desktop/features/vocab/application/google_cloud_tts_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final googleCloudTtsServiceProvider = Provider<GoogleCloudTtsService>((ref) {
  final s = GoogleCloudTtsService();
  ref.onDispose(s.close);
  return s;
});

final googleCloudTtsCredentialsStoreProvider =
    Provider<GoogleCloudTtsCredentialsStore>((ref) {
      return GoogleCloudTtsCredentialsStore();
    });

typedef _VoicePreset = ({String label, String voiceName, String languageCode});

const List<_VoicePreset> _kVoicePresets = <_VoicePreset>[
  (label: 'English (US) · Neural2 J', voiceName: 'en-US-Neural2-J', languageCode: 'en-US'),
  (label: 'English (US) · Neural2 F', voiceName: 'en-US-Neural2-F', languageCode: 'en-US'),
  (label: 'English (GB) · Neural2 B', voiceName: 'en-GB-Neural2-B', languageCode: 'en-GB'),
  (label: 'Tiếng Việt · Neural2 A', voiceName: 'vi-VN-Neural2-A', languageCode: 'vi-VN'),
  (label: '日本語 · Neural2 B', voiceName: 'ja-JP-Neural2-B', languageCode: 'ja-JP'),
  (label: '한국어 · Neural2 A', voiceName: 'ko-KR-Neural2-A', languageCode: 'ko-KR'),
  (label: '中文（简体）· Neural2 C', voiceName: 'cmn-CN-Neural2-C', languageCode: 'cmn-CN'),
];

/// Google Cloud Text-to-Speech panel for long-form synthesis and MP3 export.
class VocabGoogleCloudTtsPanel extends ConsumerStatefulWidget {
  const VocabGoogleCloudTtsPanel({super.key});

  @override
  ConsumerState<VocabGoogleCloudTtsPanel> createState() =>
      _VocabGoogleCloudTtsPanelState();
}

class _VocabGoogleCloudTtsPanelState extends ConsumerState<VocabGoogleCloudTtsPanel> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customVoiceController = TextEditingController();
  final TextEditingController _customLangController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  int _presetIndex = 0;
  bool _useCustomVoice = false;
  double _speakingRate = 1.0;
  bool _loadingKey = true;
  bool _busy = false;
  String? _lastError;
  Uint8List? _lastAudio;

  @override
  void initState() {
    super.initState();
    unawaited(_loadApiKey());
    _customVoiceController.text = 'en-US-Neural2-J';
    _customLangController.text = 'en-US';
  }

  Future<void> _loadApiKey() async {
    final store = ref.read(googleCloudTtsCredentialsStoreProvider);
    final key = await store.loadApiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingKey = false;
      if (key != null && key.isNotEmpty && !store.hasBuildTimeApiKey) {
        _apiKeyController.text = key;
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _textController.dispose();
    _customVoiceController.dispose();
    _customLangController.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<String?> _resolveApiKey(AppLocalizations l10n) async {
    final store = ref.read(googleCloudTtsCredentialsStoreProvider);
    if (store.hasBuildTimeApiKey) {
      return store.loadApiKey();
    }
    final typed = _apiKeyController.text.trim();
    if (typed.isNotEmpty) {
      return typed;
    }
    final stored = await store.loadApiKey();
    return stored?.trim();
  }

  ({String voiceName, String languageCode}) _voiceSelection() {
    if (_useCustomVoice) {
      return (
        voiceName: _customVoiceController.text.trim(),
        languageCode: _customLangController.text.trim(),
      );
    }
    final p = _kVoicePresets[_presetIndex.clamp(0, _kVoicePresets.length - 1)];
    return (voiceName: p.voiceName, languageCode: p.languageCode);
  }

  Future<void> _saveApiKeyPressed() async {
    final l10n = context.l10n;
    final store = ref.read(googleCloudTtsCredentialsStoreProvider);
    if (store.hasBuildTimeApiKey) {
      return;
    }
    setState(() => _lastError = null);
    try {
      await store.saveApiKey(_apiKeyController.text);
      if (!mounted) {
        return;
      }
      await fluent.displayInfoBar(
        context,
        builder: (ctx, close) => fluent.InfoBar(
          title: Text(l10n.vocabTtsApiKeySaved),
          severity: fluent.InfoBarSeverity.success,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _lastError = e.toString());
    }
  }

  Future<void> _synthesizeToMemory(AppLocalizations l10n) async {
    setState(() {
      _lastError = null;
      _busy = true;
    });
    try {
      final apiKey = await _resolveApiKey(l10n);
      if (apiKey == null || apiKey.isEmpty) {
        setState(() => _lastError = l10n.vocabTtsNeedApiKey);
        return;
      }
      final text = _textController.text;
      if (text.trim().isEmpty) {
        setState(() => _lastError = l10n.vocabTtsNeedText);
        return;
      }
      final voice = _voiceSelection();
      if (voice.voiceName.isEmpty || voice.languageCode.isEmpty) {
        setState(() => _lastError = l10n.vocabTtsVoiceInvalid);
        return;
      }
      final service = ref.read(googleCloudTtsServiceProvider);
      final bytes = await service.synthesizeMp3(
        apiKey: apiKey,
        text: text,
        voiceName: voice.voiceName,
        languageCode: voice.languageCode,
        speakingRate: _speakingRate,
      );
      if (!mounted) {
        return;
      }
      setState(() => _lastAudio = bytes);
    } on GoogleCloudTtsException catch (e) {
      if (mounted) {
        setState(() => _lastError = l10n.vocabTtsError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastError = l10n.vocabTtsError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _playPressed() async {
    final l10n = context.l10n;
    await _synthesizeToMemory(l10n);
    final audio = _lastAudio;
    if (!mounted || audio == null) {
      return;
    }
    try {
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(audio, mimeType: 'audio/mpeg'),
        ),
      );
      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _lastError = l10n.vocabTtsError(e.toString()));
      }
    }
  }

  Future<void> _downloadPressed() async {
    final l10n = context.l10n;
    await _synthesizeToMemory(l10n);
    final audio = _lastAudio;
    if (!mounted || audio == null) {
      return;
    }
    try {
      final location = await getSaveLocation(
        suggestedName: 'speech.mp3',
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(
            label: 'MP3',
            extensions: <String>['mp3'],
          ),
        ],
        confirmButtonText: l10n.vocabTtsSaveMp3,
      );
      if (location == null) {
        return;
      }
      final path = location.path;
      final file = File(path);
      await file.writeAsBytes(audio, flush: true);
      if (!mounted) {
        return;
      }
      await fluent.displayInfoBar(
        context,
        builder: (ctx, close) => fluent.InfoBar(
          title: Text(l10n.vocabTtsSavedFile(path)),
          severity: fluent.InfoBarSeverity.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _lastError = l10n.vocabTtsError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);
    final store = ref.watch(googleCloudTtsCredentialsStoreProvider);
    final text = _textController.text;
    final utf8Bytes = utf8.encode(text).length;
    final segments = text.trim().isEmpty
        ? 0
        : chunkUtf8Text(text, maxBytes: GoogleCloudTtsService.maxUtf8BytesPerChunk)
              .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.resources.cardBackgroundFillColorDefault,
          border: Border.all(color: theme.resources.controlStrokeColorDefault),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.vocabTtsSectionTitle,
                style: theme.typography.subtitle,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.vocabTtsSectionBody,
                style: theme.typography.caption,
              ),
              const SizedBox(height: 10),
              if (_loadingKey)
                const Center(child: fluent.ProgressRing())
              else ...[
                if (store.hasBuildTimeApiKey)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.vocabTtsApiKeyFromBuild,
                      style: theme.typography.caption,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: fluent.TextBox(
                          controller: _apiKeyController,
                          placeholder: l10n.vocabTtsApiKeyPlaceholder,
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      fluent.Button(
                        onPressed: _busy ? null : _saveApiKeyPressed,
                        child: Text(l10n.vocabTtsSaveApiKey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                fluent.TextBox(
                  controller: _textController,
                  placeholder: l10n.vocabTtsTextPlaceholder,
                  maxLines: 6,
                  minLines: 4,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.vocabTtsStats(utf8Bytes, segments),
                  style: theme.typography.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(l10n.vocabTtsVoiceLabel),
                    const SizedBox(width: 8),
                    Expanded(
                      child: fluent.ComboBox<int>(
                        isExpanded: true,
                        value: _useCustomVoice ? -1 : _presetIndex,
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v == null) {
                                  return;
                                }
                                setState(() {
                                  if (v < 0) {
                                    _useCustomVoice = true;
                                  } else {
                                    _useCustomVoice = false;
                                    _presetIndex = v;
                                  }
                                });
                              },
                        items: [
                          ...List<fluent.ComboBoxItem<int>>.generate(
                            _kVoicePresets.length,
                            (i) => fluent.ComboBoxItem<int>(
                              value: i,
                              child: Text(
                                _kVoicePresets[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          fluent.ComboBoxItem<int>(
                            value: -1,
                            child: Text(l10n.vocabTtsVoiceCustom),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_useCustomVoice) ...[
                  const SizedBox(height: 8),
                  fluent.TextBox(
                    controller: _customVoiceController,
                    placeholder: l10n.vocabTtsCustomVoicePlaceholder,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  fluent.TextBox(
                    controller: _customLangController,
                    placeholder: l10n.vocabTtsCustomLangPlaceholder,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(l10n.vocabTtsSpeakingRate),
                    Expanded(
                      child: Slider(
                        value: _speakingRate,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: _speakingRate.toStringAsFixed(2),
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _speakingRate = v),
                      ),
                    ),
                  ],
                ),
                if (_lastError != null) ...[
                  const SizedBox(height: 6),
                  fluent.InfoBar(
                    title: Text(
                      _lastError!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    severity: fluent.InfoBarSeverity.error,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    fluent.FilledButton(
                      onPressed: _busy ? null : () => unawaited(_playPressed()),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: fluent.ProgressRing(strokeWidth: 2),
                            )
                          : Text(l10n.vocabTtsGeneratePlay),
                    ),
                    fluent.Button(
                      onPressed: _busy ? null : () => unawaited(_downloadPressed()),
                      child: Text(l10n.vocabTtsSaveMp3),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

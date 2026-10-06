import 'package:flutter/services.dart';

class PopupSaveRequest {
  const PopupSaveRequest({
    required this.requestId,
    required this.sourceText,
    required this.translatedText,
    required this.languagePair,
    this.passage = '',
    this.selectionStart,
    this.selectionEnd,
    this.sourceUrl = '',
    this.tags = const <String>[],
    this.sourceApp = '',
  });

  final int requestId;
  final String sourceText;
  final String translatedText;
  final String languagePair;

  /// Full passage for sentence extraction; empty => use [sourceText] only.
  final String passage;
  final int? selectionStart;
  final int? selectionEnd;

  /// Optional page URL from the host that opened the popup (native bridge).
  final String sourceUrl;
  final List<String> tags;
  final String sourceApp;

  static PopupSaveRequest? fromEvent(Object? event) {
    if (event is! Map<Object?, Object?>) {
      return null;
    }
    final requestId = event['requestId'];
    final sourceText = event['sourceText'];
    final translatedText = event['translatedText'];
    final languagePair = event['languagePair'];
    if (requestId is! int ||
        sourceText is! String ||
        translatedText is! String ||
        languagePair is! String) {
      return null;
    }
    final passageRaw = event['passage'];
    final passage = passageRaw is String && passageRaw.trim().isNotEmpty
        ? passageRaw
        : sourceText;
    final selStart = event['selectionStart'];
    final selEnd = event['selectionEnd'];
    final sourceUrlRaw = event['sourceUrl'];
    final sourceUrl = sourceUrlRaw is String ? sourceUrlRaw.trim() : '';
    final sourceAppRaw = event['sourceApp'];
    final sourceApp = sourceAppRaw is String ? sourceAppRaw.trim() : '';
    final tagsRaw = event['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final value in tagsRaw) {
        if (value is String && value.trim().isNotEmpty) {
          tags.add(value.trim());
        }
      }
    }
    return PopupSaveRequest(
      requestId: requestId,
      sourceText: sourceText,
      translatedText: translatedText,
      languagePair: languagePair,
      passage: passage,
      selectionStart: selStart is int ? selStart : null,
      selectionEnd: selEnd is int ? selEnd : null,
      sourceUrl: sourceUrl,
      tags: tags,
      sourceApp: sourceApp,
    );
  }
}

class PopupSaveBridge {
  const PopupSaveBridge();

  static const EventChannel _events = EventChannel(
    'formycareer/popup_bridge_events',
  );
  static const MethodChannel _channel = MethodChannel(
    'formycareer/popup_bridge',
  );

  Stream<PopupSaveRequest> requests() {
    return _events
        .receiveBroadcastStream()
        .map(PopupSaveRequest.fromEvent)
        .where((request) => request != null)
        .cast<PopupSaveRequest>();
  }

  Future<void> completeSaveRequest({
    required int requestId,
    required bool success,
    required String message,
  }) {
    return _channel.invokeMethod<void>('completeSaveRequest', <String, Object>{
      'requestId': requestId,
      'success': success,
      'message': message,
    });
  }
}

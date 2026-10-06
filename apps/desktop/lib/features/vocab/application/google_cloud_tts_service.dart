import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Calls Google Cloud Text-to-Speech REST API (`text:synthesize`).
///
/// Long input is split into chunks under the API UTF-8 byte limit; MP3 segments
/// are concatenated (valid for sequential playback).
class GoogleCloudTtsService {
  GoogleCloudTtsService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const int _maxUtf8BytesPerRequest = 4800;

  static final Uri _endpoint = Uri.parse(
    'https://texttospeech.googleapis.com/v1/text:synthesize',
  );

  /// Maximum UTF-8 bytes per synthesize request (matches Cloud TTS limits).
  static int get maxUtf8BytesPerChunk => _maxUtf8BytesPerRequest;

  /// Returns merged MP3 bytes for [text].
  Future<Uint8List> synthesizeMp3({
    required String apiKey,
    required String text,
    required String voiceName,
    required String languageCode,
    double speakingRate = 1.0,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }

    final chunks = chunkUtf8Text(trimmed, maxBytes: _maxUtf8BytesPerRequest);
    final merged = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      final segment = await _synthesizeChunk(
        apiKey: apiKey.trim(),
        text: chunk,
        voiceName: voiceName.trim(),
        languageCode: languageCode.trim(),
        speakingRate: speakingRate,
      );
      merged.add(segment);
    }
    return merged.takeBytes();
  }

  Future<Uint8List> _synthesizeChunk({
    required String apiKey,
    required String text,
    required String voiceName,
    required String languageCode,
    required double speakingRate,
  }) async {
    final uri = _endpoint.replace(queryParameters: {'key': apiKey});
    final body = jsonEncode(<String, dynamic>{
      'input': <String, String>{'text': text},
      'voice': <String, String>{
        'languageCode': languageCode,
        'name': voiceName,
      },
      'audioConfig': <String, dynamic>{
        'audioEncoding': 'MP3',
        'speakingRate': speakingRate.clamp(0.25, 4.0),
      },
    });

    final response = await _http.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _parseErrorMessage(response.body) ?? response.body;
      throw GoogleCloudTtsException(
        statusCode: response.statusCode,
        message: message,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GoogleCloudTtsException(
        statusCode: 500,
        message: 'Unexpected synthesize response',
      );
    }
    final audioContent = decoded['audioContent'];
    if (audioContent is! String || audioContent.isEmpty) {
      throw const GoogleCloudTtsException(
        statusCode: 500,
        message: 'Missing audioContent in response',
      );
    }

    return base64Decode(audioContent);
  }

  String? _parseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          final msg = err['message'];
          if (msg is String && msg.trim().isNotEmpty) {
            return msg.trim();
          }
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  void close() {
    _http.close();
  }
}

/// Splits [text] into segments whose UTF-8 encoding length is at most [maxBytes].
/// Tries to end chunks at newlines or sentence punctuation when possible.
List<String> chunkUtf8Text(String text, {required int maxBytes}) {
  var remaining = text.trim();
  if (remaining.isEmpty) {
    return const <String>[];
  }
  final out = <String>[];
  while (remaining.isNotEmpty) {
    final runes = remaining.runes.toList();
    var byteLen = 0;
    var endCharOffset = 0;
    for (var r = 0; r < runes.length; r++) {
      final ch = String.fromCharCode(runes[r]);
      final nextBytes = utf8.encode(ch).length;
      if (byteLen + nextBytes > maxBytes && endCharOffset > 0) {
        break;
      }
      if (byteLen + nextBytes > maxBytes && endCharOffset == 0) {
        byteLen += nextBytes;
        endCharOffset += ch.length;
        break;
      }
      byteLen += nextBytes;
      endCharOffset += ch.length;
    }
    var chunk = remaining.substring(0, endCharOffset);
    chunk = _preferBoundarySplit(chunk);
    out.add(chunk);
    remaining = remaining.substring(chunk.length).trimLeft();
  }
  return out;
}

String _preferBoundarySplit(String chunk) {
  if (chunk.length < 24) {
    return chunk;
  }
  const separators = <String>['\n\n', '\n', '. ', '。', '! ', '? ', '; '];
  for (final sep in separators) {
    final idx = chunk.lastIndexOf(sep);
    if (idx >= chunk.length * 0.25 && idx + sep.length < chunk.length) {
      return chunk.substring(0, idx + sep.length).trimRight();
    }
  }
  return chunk;
}

class GoogleCloudTtsException implements Exception {
  const GoogleCloudTtsException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'GoogleCloudTtsException($statusCode): $message';
}

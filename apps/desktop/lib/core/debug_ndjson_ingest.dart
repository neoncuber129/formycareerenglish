import 'dart:convert';
import 'dart:io';

Future<void> emitDebugSessionNdjson(Map<String, Object?> payload) async {
  const uriString =
      'http://127.0.0.1:7866/ingest/8639d9c4-d1e1-4f19-9835-35266c94f783';
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(uriString));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.headers.set('X-Debug-Session-Id', '4ff1f3');
    req.add(utf8.encode(jsonEncode(payload)));
    await req.close();
  } catch (_) {
  } finally {
    client.close(force: true);
  }
}

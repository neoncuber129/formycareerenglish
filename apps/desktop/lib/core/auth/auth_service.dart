import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accountEmail,
    required this.deviceId,
  });

  final String accessToken;
  final String accountEmail;
  final String deviceId;
}

class AuthService {
  AuthService({FlutterSecureStorage? secureStorage, http.Client? httpClient})
    : _secure = secureStorage ?? const FlutterSecureStorage(),
      _http = httpClient ?? http.Client();

  final FlutterSecureStorage _secure;
  final http.Client _http;
  bool _initialized = false;

  /// When false (default): no Google OAuth browser flow and no Drive-backed sync.
  /// Re-enable with `--dart-define=ENABLE_GOOGLE_OAUTH=true`.
  static const bool oauthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_OAUTH', defaultValue: false);

  static const String _clientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );
  static const String _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const String _clientSecret = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_SECRET',
  );
  static const String _userInfoEndpoint = 'https://www.googleapis.com/oauth2/v2/userinfo';
  static const List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  static const _kAccessToken = 'fmc.auth.access_token';
  static const _kRefreshToken = 'fmc.auth.refresh_token';
  static const _kAccessExpiry = 'fmc.auth.access_expiry';
  static const _kAccountEmail = 'fmc.auth.account_email';
  static const _kDeviceId = 'fmc.auth.device_id';
  static bool get oauthClientIdConfigured =>
      oauthEnabled && _clientId.trim().isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (!oauthEnabled) {
      _initialized = true;
      return;
    }
    if (_clientId.trim().isEmpty) {
      throw StateError('GOOGLE_OAUTH_CLIENT_ID is missing.');
    }
    _initialized = true;
  }

  Future<AuthSession?> ensureAuthenticated() async {
    if (!oauthEnabled) {
      return null;
    }
    await _ensureInitialized();
    final accessToken = await _secure.read(key: _kAccessToken);
    final expiryRaw = await _secure.read(key: _kAccessExpiry);
    final refreshToken = await _secure.read(key: _kRefreshToken);
    final accountEmail = await _secure.read(key: _kAccountEmail);

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        expiryRaw != null &&
        DateTime.tryParse(expiryRaw)?.isAfter(
              DateTime.now().toUtc().add(const Duration(minutes: 1)),
            ) ==
            true &&
        accountEmail != null &&
        accountEmail.isNotEmpty) {
      return AuthSession(
        accessToken: accessToken,
        accountEmail: accountEmail,
        deviceId: await _getOrCreateDeviceId(),
      );
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final refreshed = await _refreshAccessToken(refreshToken);
      if (refreshed != null) {
        return AuthSession(
          accessToken: refreshed.$1,
          accountEmail: accountEmail ?? '',
          deviceId: await _getOrCreateDeviceId(),
        );
      }
    }

    return null;
  }

  Future<AuthSession?> trySilentReauthenticate() async {
    if (!oauthEnabled) {
      return null;
    }
    await _ensureInitialized();
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kAccessExpiry);
    final refreshToken = await _secure.read(key: _kRefreshToken);
    final accountEmail = await _secure.read(key: _kAccountEmail);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final refreshed = await _refreshAccessToken(refreshToken);
      if (refreshed != null) {
        return AuthSession(
          accessToken: refreshed.$1,
          accountEmail: accountEmail ?? '',
          deviceId: await _getOrCreateDeviceId(),
        );
      }
    }
    return null;
  }

  Future<AuthSession?> signInInteractive() async {
    if (!oauthEnabled) {
      throw StateError('Google sign-in is disabled.');
    }
    await _ensureInitialized();
    debugPrint('AuthService: start interactive sign-in');
    final localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${localServer.port}/oauth2callback';
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _buildCodeChallenge(codeVerifier);
    final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    final opened = await launchUrl(authUri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await localServer.close(force: true);
      throw StateError('Cannot open browser for Google sign-in.');
    }
    debugPrint('AuthService: browser opened, waiting callback at $redirectUri');
    debugPrint('AuthService: auth url $authUri');

    final code = await _waitForAuthCode(localServer);
    if (code == null || code.isEmpty) {
      throw StateError('OAuth callback did not return authorization code.');
    }
    debugPrint('AuthService: authorization code received');

    final tokenResponse = await _exchangeAuthCode(
      code: code,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
    );

    final accessToken = (tokenResponse['access_token'] as String? ?? '').trim();
    if (accessToken.isEmpty) {
      throw StateError('OAuth token response missing access_token: $tokenResponse');
    }
    debugPrint('AuthService: access token received');

    final expiresIn = (tokenResponse['expires_in'] as num?)?.toInt() ?? 3600;
    final expiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    await _secure.write(key: _kAccessToken, value: accessToken);
    await _secure.write(key: _kAccessExpiry, value: expiry.toIso8601String());

    final refresh = (tokenResponse['refresh_token'] as String?)?.trim();
    if (refresh != null && refresh.isNotEmpty) {
      await _secure.write(key: _kRefreshToken, value: refresh);
    }

    final email =
        await _fetchAccountEmail(accessToken) ??
        _extractEmailFromIdToken((tokenResponse['id_token'] as String?)?.trim());
    final resolvedEmail = (email ?? '').trim().isEmpty
        ? 'Google account connected'
        : email!.trim();
    if (resolvedEmail == 'Google account connected') {
      debugPrint('AuthService: sign-in succeeded but email unavailable.');
    }
    await _secure.write(key: _kAccountEmail, value: resolvedEmail);
    debugPrint('AuthService: account stored as "$resolvedEmail"');

    return AuthSession(
      accessToken: accessToken,
      accountEmail: resolvedEmail,
      deviceId: await _getOrCreateDeviceId(),
    );
  }

  Future<void> signOut() async {
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
    await _secure.delete(key: _kAccessExpiry);
    await _secure.delete(key: _kAccountEmail);
  }

  Future<String?> currentAccountEmail() async {
    if (!oauthEnabled) {
      return null;
    }
    final saved = (await _secure.read(key: _kAccountEmail))?.trim();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final session = await ensureAuthenticated();
    return session?.accountEmail.isNotEmpty == true
        ? session!.accountEmail
        : null;
  }

  Future<bool> isSignedIn() async => (await ensureAuthenticated()) != null;

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getString(_kDeviceId) ?? '').trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    final created = const Uuid().v4();
    await prefs.setString(_kDeviceId, created);
    return created;
  }

  Future<Map<String, dynamic>> _exchangeAuthCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    if (_clientId.trim().isEmpty) {
      throw StateError('GOOGLE_OAUTH_CLIENT_ID is missing.');
    }
    final body = <String, String>{
      'code': code,
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': codeVerifier,
    };
    if (_clientSecret.trim().isNotEmpty) {
      body['client_secret'] = _clientSecret;
    }
    debugPrint('AuthService: exchanging auth code for token...');
    final response = await _http
        .post(
          Uri.parse(_tokenEndpoint),
          body: body,
        )
        .timeout(const Duration(seconds: 20));
    debugPrint('AuthService: token endpoint status=${response.statusCode}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('AuthService: token endpoint body=${response.body}');
      throw StateError('OAuth token exchange failed: ${response.body}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return map;
  }

  Future<(String, DateTime)?> _refreshAccessToken(String refreshToken) async {
    if (_clientId.trim().isEmpty) {
      return null;
    }
    final body = <String, String>{
      'client_id': _clientId,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    };
    if (_clientSecret.trim().isNotEmpty) {
      body['client_secret'] = _clientSecret;
    }
    final response = await _http.post(
      Uri.parse(_tokenEndpoint),
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = (map['access_token'] as String? ?? '').trim();
    if (accessToken.isEmpty) {
      return null;
    }
    final expiresIn = (map['expires_in'] as num?)?.toInt() ?? 3600;
    final expiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    await _secure.write(key: _kAccessToken, value: accessToken);
    await _secure.write(key: _kAccessExpiry, value: expiry.toIso8601String());
    return (accessToken, expiry);
  }

  Future<String?> _waitForAuthCode(HttpServer server) async {
    final deadline = DateTime.now().toUtc().add(const Duration(minutes: 2));
    try {
      await for (final request in server) {
        final now = DateTime.now().toUtc();
        if (now.isAfter(deadline)) {
          debugPrint('AuthService: timeout waiting for OAuth callback.');
          return null;
        }
        final path = request.uri.path;
        final normalizedPath = path.endsWith('/') && path.length > 1
            ? path.substring(0, path.length - 1)
            : path;
        final code = request.uri.queryParameters['code'];
        final error = request.uri.queryParameters['error'];
        debugPrint('AuthService: callback request path=$path query=${request.uri.query}');
        request.response.headers.contentType = ContentType.html;
        if (normalizedPath == '/oauth2callback' && code != null && code.isNotEmpty) {
          request.response.write(
            '<html><body><h3>Google sign-in completed.</h3>'
            '<p>You can close this tab and return to the app.</p></body></html>',
          );
          await request.response.close();
          return code;
        }
        if (normalizedPath == '/oauth2callback' && error != null && error.isNotEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(
            '<html><body><h3>Google sign-in failed.</h3>'
            '<p>${htmlEscape.convert(error)}</p></body></html>',
          );
          await request.response.close();
          return null;
        }
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          '<html><body>Waiting for OAuth callback...</body></html>',
        );
        await request.response.close();
      }
      return null;
    } on TimeoutException {
      debugPrint('AuthService: timeout waiting for OAuth callback.');
      return null;
    } finally {
      try {
        await server.close(force: true);
      } catch (_) {}
    }
  }

  Future<String?> _fetchAccountEmail(String accessToken) async {
    final response = await _http.get(
      Uri.parse(_userInfoEndpoint),
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('AuthService: userinfo failed ${response.statusCode}: ${response.body}');
      return null;
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['email'] as String?)?.trim();
  }

  String? _extractEmailFromIdToken(String? idToken) {
    final raw = (idToken ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    final parts = raw.split('.');
    if (parts.length < 2) {
      return null;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
      return (payload['email'] as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List<String>.generate(
      64,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _buildCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier)).bytes;
    return base64UrlEncode(digest).replaceAll('=', '');
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentAccountEmailProvider = FutureProvider<String?>((ref) async {
  return ref.watch(authServiceProvider).currentAccountEmail();
});

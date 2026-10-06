import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  /// When false (default): no Google Sign-In / Drive OAuth.
  /// Re-enable with `--dart-define=ENABLE_GOOGLE_OAUTH=true`.
  static const bool oauthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_OAUTH', defaultValue: false);

  static const String _clientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_SERVER_CLIENT_ID',
  );
  static const String _clientSecret = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_SECRET',
  );
  static const String _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const List<String> _scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  static const _kAccessToken = 'fmc.auth.access_token';
  static const _kRefreshToken = 'fmc.auth.refresh_token';
  static const _kAccessExpiry = 'fmc.auth.access_expiry';
  static const _kAccountEmail = 'fmc.auth.account_email';
  static const _kDeviceId = 'fmc.auth.device_id';

  /// Android requires a non-null [serverClientId] for `GoogleSignIn.initialize`.
  /// When unset, skip the plugin entirely so local-only builds do not throw.
  bool get isGoogleDriveOAuthConfigured =>
      oauthEnabled && _serverClientId.trim().isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (!oauthEnabled || !isGoogleDriveOAuthConfigured) {
      _initialized = true;
      return;
    }
    try {
      await _google.initialize(
        clientId: _clientId.trim().isEmpty ? null : _clientId,
        serverClientId: _serverClientId,
      );
    } on UnimplementedError {
      throw UnsupportedError(
        'Google Sign-In is not supported on this runtime yet.',
      );
    }
    _initialized = true;
  }

  Future<AuthSession?> ensureAuthenticated() async {
    if (!oauthEnabled) {
      return null;
    }
    final fromStorage = await _sessionFromSecureStorageOnly();
    if (fromStorage != null) {
      return fromStorage;
    }
    if (!isGoogleDriveOAuthConfigured) {
      await _ensureInitialized();
      return null;
    }
    await _ensureInitialized();
    return _lightweightAuthSession();
  }

  Future<AuthSession?> _sessionFromSecureStorageOnly() async {
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
    if (!isGoogleDriveOAuthConfigured) {
      return null;
    }
    await _ensureInitialized();
    return _lightweightAuthSession();
  }

  Future<AuthSession?> signInInteractive() async {
    if (!isGoogleDriveOAuthConfigured) {
      return null;
    }
    await _ensureInitialized();
    final account = await _google.authenticate(scopeHint: _scopes);
    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );
    final bearer = headers?['Authorization'] ?? '';
    if (!bearer.startsWith('Bearer ')) {
      return null;
    }
    final token = bearer.substring('Bearer '.length).trim();
    if (token.isEmpty) {
      return null;
    }
    await _secure.write(key: _kAccessToken, value: token);
    await _secure.write(key: _kAccountEmail, value: account.email);
    await _secure.write(
      key: _kAccessExpiry,
      value: DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 50))
          .toIso8601String(),
    );

    final serverAuth = await account.authorizationClient.authorizeServer(_scopes);
    if (serverAuth != null) {
      final refresh = await _exchangeAuthCode(serverAuth.serverAuthCode);
      if (refresh != null && refresh.isNotEmpty) {
        await _secure.write(key: _kRefreshToken, value: refresh);
      }
    }

    return AuthSession(
      accessToken: token,
      accountEmail: account.email,
      deviceId: await _getOrCreateDeviceId(),
    );
  }

  Future<void> signOut() async {
    if (oauthEnabled && isGoogleDriveOAuthConfigured) {
      await _ensureInitialized();
      await _google.signOut();
    }
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
    await _secure.delete(key: _kAccessExpiry);
    await _secure.delete(key: _kAccountEmail);
  }

  Future<String?> currentAccountEmail() async {
    if (!oauthEnabled) {
      return null;
    }
    return _secure.read(key: _kAccountEmail);
  }

  Future<bool> isSignedIn() async => (await ensureAuthenticated()) != null;

  Future<AuthSession?> _lightweightAuthSession() async {
    final lightweight = _google.attemptLightweightAuthentication();
    final account = lightweight == null ? null : await lightweight;
    if (account == null) {
      return null;
    }
    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: false,
    );
    final bearer = headers?['Authorization'] ?? '';
    if (!bearer.startsWith('Bearer ')) {
      return null;
    }
    final token = bearer.substring('Bearer '.length).trim();
    if (token.isEmpty) {
      return null;
    }
    await _secure.write(key: _kAccessToken, value: token);
    await _secure.write(
      key: _kAccessExpiry,
      value: DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 50))
          .toIso8601String(),
    );
    await _secure.write(key: _kAccountEmail, value: account.email);
    return AuthSession(
      accessToken: token,
      accountEmail: account.email,
      deviceId: await _getOrCreateDeviceId(),
    );
  }

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

  Future<String?> _exchangeAuthCode(String code) async {
    if (_clientId.trim().isEmpty) {
      return null;
    }
    final response = await _http.post(
      Uri.parse(_tokenEndpoint),
      body: <String, String>{
        'code': code,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'authorization_code',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return (map['refresh_token'] as String?)?.trim();
  }

  Future<(String, DateTime)?> _refreshAccessToken(String refreshToken) async {
    if (_clientId.trim().isEmpty) {
      return null;
    }
    final response = await _http.post(
      Uri.parse(_tokenEndpoint),
      body: <String, String>{
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
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
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentAccountEmailProvider = FutureProvider<String?>((ref) async {
  return ref.watch(authServiceProvider).currentAccountEmail();
});

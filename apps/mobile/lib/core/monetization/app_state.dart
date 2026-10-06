import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

int _compareSemVer(String a, String b) {
  List<int> parse(String input) {
    final cleaned = input.trim().split('+').first;
    final parts = cleaned.split('.');
    return List<int>.generate(3, (index) {
      if (index >= parts.length) {
        return 0;
      }
      return int.tryParse(parts[index]) ?? 0;
    });
  }

  final va = parse(a);
  final vb = parse(b);
  for (var i = 0; i < 3; i++) {
    final cmp = va[i].compareTo(vb[i]);
    if (cmp != 0) {
      return cmp;
    }
  }
  return 0;
}

String todayLocalDateKey() {
  final n = DateTime.now();
  final y = n.year.toString().padLeft(4, '0');
  final m = n.month.toString().padLeft(2, '0');
  final d = n.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _parseConfigPositiveInt(
  dynamic raw, {
  required int fallback,
  int min = 1,
  int max = 100000,
}) {
  if (raw is num) {
    return raw.round().clamp(min, max);
  }
  if (raw is String) {
    final v = int.tryParse(raw.trim());
    if (v != null) {
      return v.clamp(min, max);
    }
  }
  return fallback;
}

class ProActivationResult {
  const ProActivationResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AppState {
  const AppState({
    required this.isPro,
    required this.isInitialized,
    required this.isAdsEnabled,
    required this.adUrl,
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.licenseVerifyUrl,
    required this.proProvider,
    required this.gumroadProductPermalink,
    required this.gumroadVerifyUrl,
    required this.gumroadUseIncrementUsesCount,
    required this.lemonLicenseProxyUrl,
    required this.lemonLicenseProxyAuthToken,
    required this.lemonVerifyUrl,
    required this.lemonActivateUrl,
    required this.lemonInstanceName,
    required this.lemonStoreName,
    required this.lemonExpectedStoreId,
    required this.lemonExpectedProductId,
    required this.lemonExpectedVariantId,
    required this.freeDailyReviewGradesUsed,
    required this.freeDailyReviewLimit,
  });

  /// Fallback before remote prefs/config load (see [desktop-app-config.json]).
  static const int defaultFreeDailyReviewLimit = 100;

  final bool isPro;
  final bool isInitialized;
  final bool isAdsEnabled;
  final String adUrl;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final bool forceUpdate;
  final String releaseNotes;
  final String licenseVerifyUrl;
  final String proProvider;
  final String gumroadProductPermalink;
  final String gumroadVerifyUrl;
  final bool gumroadUseIncrementUsesCount;
  final String lemonLicenseProxyUrl;
  final String lemonLicenseProxyAuthToken;
  final String lemonVerifyUrl;
  final String lemonActivateUrl;
  final String lemonInstanceName;
  final String lemonStoreName;
  final String lemonExpectedStoreId;
  final String lemonExpectedProductId;
  final String lemonExpectedVariantId;

  /// SRS grades counted today toward [freeDailyReviewLimit] for Free tier (local calendar).
  final int freeDailyReviewGradesUsed;

  /// Max SRS grades per local day on Free tier (`freeDailyReviewLimit` in remote app config).
  final int freeDailyReviewLimit;

  int get freeReviewsRemainingToday => isPro
      ? freeDailyReviewLimit
      : (freeDailyReviewLimit - freeDailyReviewGradesUsed).clamp(
          0,
          freeDailyReviewLimit,
        );

  bool get hasUpdate => _compareSemVer(currentVersion, latestVersion) < 0;

  bool get requiresUpdate =>
      forceUpdate || _compareSemVer(currentVersion, minSupportedVersion) < 0;

  AppState copyWith({
    bool? isPro,
    bool? isInitialized,
    bool? isAdsEnabled,
    String? adUrl,
    String? currentVersion,
    String? latestVersion,
    String? minSupportedVersion,
    String? downloadUrl,
    bool? forceUpdate,
    String? releaseNotes,
    String? licenseVerifyUrl,
    String? proProvider,
    String? gumroadProductPermalink,
    String? gumroadVerifyUrl,
    bool? gumroadUseIncrementUsesCount,
    String? lemonLicenseProxyUrl,
    String? lemonLicenseProxyAuthToken,
    String? lemonVerifyUrl,
    String? lemonActivateUrl,
    String? lemonInstanceName,
    String? lemonStoreName,
    String? lemonExpectedStoreId,
    String? lemonExpectedProductId,
    String? lemonExpectedVariantId,
    int? freeDailyReviewGradesUsed,
    int? freeDailyReviewLimit,
  }) {
    return AppState(
      isPro: isPro ?? this.isPro,
      isInitialized: isInitialized ?? this.isInitialized,
      isAdsEnabled: isAdsEnabled ?? this.isAdsEnabled,
      adUrl: adUrl ?? this.adUrl,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      licenseVerifyUrl: licenseVerifyUrl ?? this.licenseVerifyUrl,
      proProvider: proProvider ?? this.proProvider,
      gumroadProductPermalink:
          gumroadProductPermalink ?? this.gumroadProductPermalink,
      gumroadVerifyUrl: gumroadVerifyUrl ?? this.gumroadVerifyUrl,
      gumroadUseIncrementUsesCount:
          gumroadUseIncrementUsesCount ?? this.gumroadUseIncrementUsesCount,
      lemonLicenseProxyUrl: lemonLicenseProxyUrl ?? this.lemonLicenseProxyUrl,
      lemonLicenseProxyAuthToken:
          lemonLicenseProxyAuthToken ?? this.lemonLicenseProxyAuthToken,
      lemonVerifyUrl: lemonVerifyUrl ?? this.lemonVerifyUrl,
      lemonActivateUrl: lemonActivateUrl ?? this.lemonActivateUrl,
      lemonInstanceName: lemonInstanceName ?? this.lemonInstanceName,
      lemonStoreName: lemonStoreName ?? this.lemonStoreName,
      lemonExpectedStoreId: lemonExpectedStoreId ?? this.lemonExpectedStoreId,
      lemonExpectedProductId:
          lemonExpectedProductId ?? this.lemonExpectedProductId,
      lemonExpectedVariantId:
          lemonExpectedVariantId ?? this.lemonExpectedVariantId,
      freeDailyReviewGradesUsed:
          freeDailyReviewGradesUsed ?? this.freeDailyReviewGradesUsed,
      freeDailyReviewLimit: freeDailyReviewLimit ?? this.freeDailyReviewLimit,
    );
  }
}

class AppStateController extends Notifier<AppState> {
  static const String isProKey = 'isPro';
  static const String isAdsEnabledKey = 'adsEnabled';
  static const String adUrlKey = 'adUrl';
  static const String latestVersionKey = 'latestVersion';
  static const String minSupportedVersionKey = 'minSupportedVersion';
  static const String downloadUrlKey = 'downloadUrl';
  static const String forceUpdateKey = 'forceUpdate';
  static const String releaseNotesKey = 'releaseNotes';
  static const String licenseVerifyUrlKey = 'licenseVerifyUrl';
  static const String proProviderKey = 'proProvider';
  static const String gumroadProductPermalinkKey = 'gumroadProductPermalink';
  static const String gumroadVerifyUrlKey = 'gumroadVerifyUrl';
  static const String gumroadUseIncrementUsesCountKey =
      'gumroadUseIncrementUsesCount';
  static const String lemonLicenseProxyUrlKey = 'lemonLicenseProxyUrl';
  static const String lemonLicenseProxyAuthTokenKey =
      'lemonLicenseProxyAuthToken';
  static const String lemonVerifyUrlKey = 'lemonVerifyUrl';
  static const String lemonActivateUrlKey = 'lemonActivateUrl';
  static const String lemonInstanceNameKey = 'lemonInstanceName';
  static const String lemonStoreNameKey = 'lemonStoreName';
  static const String lemonExpectedStoreIdKey = 'lemonExpectedStoreId';
  static const String lemonExpectedProductIdKey = 'lemonExpectedProductId';
  static const String lemonExpectedVariantIdKey = 'lemonExpectedVariantId';

  /// Stable device label suffix for Lemon `instance_name` (activation slots).
  static const String lemonSqueezyInstanceFingerprintKey =
      'lemonSqueezyInstanceFingerprint';

  /// Last successfully activated license key (trimmed) on this install.
  static const String lemonLastLicenseKeyKey = 'lemonLastLicenseKey';

  /// Lemon license key instance UUID from activate response (reuse validate).
  static const String lemonLicenseInstanceIdKey = 'lemonLicenseInstanceId';
  static const String validProKeysKey = 'validProKeys';
  static const String dailyReviewDateKey = 'dailyReviewDate';
  static const String dailyReviewCountKey = 'dailyReviewCount';
  static const String freeDailyReviewLimitKey = 'freeDailyReviewLimit';
  static const String _defaultAdUrl = 'https://formycareer.vercel.app';
  static const String _defaultProProvider = 'lemonsqueezy';
  static const String _defaultGumroadVerifyUrl =
      'https://api.gumroad.com/v2/licenses/verify';
  static const String _defaultLemonVerifyUrl =
      'https://api.lemonsqueezy.com/v1/licenses/validate';
  static const String _defaultLemonActivateUrl =
      'https://api.lemonsqueezy.com/v1/licenses/activate';
  static const String _adConfigUrl = String.fromEnvironment(
    'MOBILE_AD_CONFIG_URL',
    defaultValue: 'https://formycareer.vercel.app/desktop-ad-config.json',
  );
  static const String _appConfigUrl = String.fromEnvironment(
    'MOBILE_APP_CONFIG_URL',
    defaultValue: 'https://formycareer.vercel.app/desktop-app-config.json',
  );

  @override
  AppState build() {
    unawaited(initialize());
    return const AppState(
      isPro: false,
      isInitialized: false,
      isAdsEnabled: true,
      adUrl: _defaultAdUrl,
      currentVersion: '0.0.0',
      latestVersion: '0.0.0',
      minSupportedVersion: '0.0.0',
      downloadUrl: 'https://formycareer.vercel.app',
      forceUpdate: false,
      releaseNotes: '',
      licenseVerifyUrl: '',
      proProvider: _defaultProProvider,
      gumroadProductPermalink: '',
      gumroadVerifyUrl: _defaultGumroadVerifyUrl,
      gumroadUseIncrementUsesCount: false,
      lemonLicenseProxyUrl: '',
      lemonLicenseProxyAuthToken: '',
      lemonVerifyUrl: _defaultLemonVerifyUrl,
      lemonActivateUrl: _defaultLemonActivateUrl,
      lemonInstanceName: 'FormyCareer Mobile',
      lemonStoreName: 'Lemon Squeezy',
      lemonExpectedStoreId: '',
      lemonExpectedProductId: '',
      lemonExpectedVariantId: '',
      freeDailyReviewGradesUsed: 0,
      freeDailyReviewLimit: AppState.defaultFreeDailyReviewLimit,
    );
  }

  Future<int> _syncDailyQuotaFromPrefs(SharedPreferences prefs) async {
    final today = todayLocalDateKey();
    final storedDate = prefs.getString(dailyReviewDateKey) ?? '';
    var count = prefs.getInt(dailyReviewCountKey) ?? 0;
    if (storedDate != today) {
      count = 0;
      await prefs.setString(dailyReviewDateKey, today);
      await prefs.setInt(dailyReviewCountKey, 0);
    }
    return count;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final package = await PackageInfo.fromPlatform();
    state = state.copyWith(
      isPro: prefs.getBool(isProKey) ?? false,
      isAdsEnabled: prefs.getBool(isAdsEnabledKey) ?? true,
      adUrl: prefs.getString(adUrlKey) ?? _defaultAdUrl,
      currentVersion: package.version,
      latestVersion: prefs.getString(latestVersionKey) ?? package.version,
      minSupportedVersion:
          prefs.getString(minSupportedVersionKey) ?? package.version,
      downloadUrl:
          prefs.getString(downloadUrlKey) ?? 'https://formycareer.vercel.app',
      forceUpdate: prefs.getBool(forceUpdateKey) ?? false,
      releaseNotes: prefs.getString(releaseNotesKey) ?? '',
      licenseVerifyUrl: prefs.getString(licenseVerifyUrlKey) ?? '',
      proProvider: prefs.getString(proProviderKey) ?? _defaultProProvider,
      gumroadProductPermalink:
          prefs.getString(gumroadProductPermalinkKey) ?? '',
      gumroadVerifyUrl:
          prefs.getString(gumroadVerifyUrlKey) ?? _defaultGumroadVerifyUrl,
      gumroadUseIncrementUsesCount:
          prefs.getBool(gumroadUseIncrementUsesCountKey) ?? false,
      lemonLicenseProxyUrl: prefs.getString(lemonLicenseProxyUrlKey) ?? '',
      lemonLicenseProxyAuthToken:
          prefs.getString(lemonLicenseProxyAuthTokenKey) ?? '',
      lemonVerifyUrl:
          prefs.getString(lemonVerifyUrlKey) ?? _defaultLemonVerifyUrl,
      lemonActivateUrl:
          prefs.getString(lemonActivateUrlKey) ?? _defaultLemonActivateUrl,
      lemonInstanceName:
          prefs.getString(lemonInstanceNameKey) ?? 'FormyCareer Mobile',
      lemonStoreName: prefs.getString(lemonStoreNameKey) ?? 'Lemon Squeezy',
      lemonExpectedStoreId: prefs.getString(lemonExpectedStoreIdKey) ?? '',
      lemonExpectedProductId: prefs.getString(lemonExpectedProductIdKey) ?? '',
      lemonExpectedVariantId: prefs.getString(lemonExpectedVariantIdKey) ?? '',
      freeDailyReviewGradesUsed: await _syncDailyQuotaFromPrefs(prefs),
      freeDailyReviewLimit:
          prefs.getInt(freeDailyReviewLimitKey) ??
          AppState.defaultFreeDailyReviewLimit,
      isInitialized: true,
    );
    unawaited(refreshRemoteConfig());
  }

  /// Free tier: one SRS grade per successful call, max [AppState.freeDailyReviewLimit]/local day.
  /// Pro: always allows without counting.
  Future<bool> tryConsumeDailyReviewGrade() async {
    if (state.isPro) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    var count = await _syncDailyQuotaFromPrefs(prefs);
    if (count >= state.freeDailyReviewLimit) {
      state = state.copyWith(freeDailyReviewGradesUsed: count);
      return false;
    }
    count++;
    await prefs.setInt(dailyReviewCountKey, count);
    state = state.copyWith(freeDailyReviewGradesUsed: count);
    return true;
  }

  Future<void> activatePro() async {
    if (state.isPro) {
      return;
    }
    state = state.copyWith(isPro: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isProKey, true);
  }

  Future<ProActivationResult> activateProWithKey(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      return const ProActivationResult(
        success: false,
        message: 'Please enter a valid license key.',
      );
    }
    await checkForUpdates();

    final prefs = await SharedPreferences.getInstance();
    final validKeySet =
        (prefs.getStringList(validProKeysKey) ?? const <String>[])
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();
    if (validKeySet.contains(normalized.toLowerCase())) {
      await activatePro();
      return const ProActivationResult(
        success: true,
        message: 'Pro activated successfully.',
      );
    }

    final provider = state.proProvider.trim().toLowerCase();
    if (provider == 'gumroad') {
      final result = await _verifyGumroadLicense(normalized);
      if (!result.success) {
        return result;
      }
      await activatePro();
      return result;
    }

    if (provider == 'lemonsqueezy') {
      final result = await _verifyLemonSqueezyLicense(normalized);
      if (!result.success) {
        return result;
      }
      await activatePro();
      return result;
    }

    if (provider == 'custom') {
      final apiResult = await _verifyProKeyWithApi(normalized);
      if (apiResult != null) {
        if (!apiResult.success) {
          return apiResult;
        }
        await activatePro();
        return apiResult;
      }
    }
    return const ProActivationResult(
      success: false,
      message: 'License key is invalid. Please check and try again.',
    );
  }

  Future<ProActivationResult> _verifyGumroadLicense(String licenseKey) async {
    final permalink = state.gumroadProductPermalink.trim();
    if (permalink.isEmpty) {
      return const ProActivationResult(
        success: false,
        message:
            'Gumroad product is not configured yet. Please contact support.',
      );
    }
    final verifyUri = Uri.tryParse(state.gumroadVerifyUrl);
    if (verifyUri == null || verifyUri.host.isEmpty) {
      return const ProActivationResult(
        success: false,
        message: 'Gumroad verification endpoint is invalid.',
      );
    }
    try {
      final response = await http
          .post(
            verifyUri,
            headers: const <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{
              'product_permalink': permalink,
              'license_key': licenseKey,
              'increment_uses_count': state.gumroadUseIncrementUsesCount
                  ? 'true'
                  : 'false',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message:
              'Cannot verify Gumroad license now. Please try again shortly.',
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'Gumroad response is invalid.',
        );
      }
      final success = decoded['success'] == true;
      if (!success) {
        return const ProActivationResult(
          success: false,
          message: 'License key is invalid or not active.',
        );
      }
      return const ProActivationResult(
        success: true,
        message: 'Pro activated successfully.',
      );
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach Gumroad now. Please try again later.',
      );
    }
  }

  /// Stable label for Lemon `instance_name`: OS machine id when available
  /// (Windows MachineGuid, macOS system GUID, Linux /etc/machine-id), else a
  /// persisted UUID so reinstall still maps to one logical device only when
  /// the OS id path fails.
  Future<String> _buildLemonInstanceName(SharedPreferences prefs) async {
    final base = state.lemonInstanceName.trim();
    final label = base.isEmpty ? 'FormyCareer Mobile' : base;
    final suffix = await _lemonActivationMachineSuffix(prefs);
    return '$label · $suffix';
  }

  Future<String> _lemonActivationMachineSuffix(SharedPreferences prefs) async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        final id = w.deviceId.trim();
        if (id.isNotEmpty) {
          return id.replaceAll(RegExp(r'[{}]'), '').toLowerCase();
        }
        final host = w.computerName.trim();
        if (host.isNotEmpty) {
          return 'pc-$host';
        }
      } else if (Platform.isMacOS) {
        final m = await plugin.macOsInfo;
        final g = m.systemGUID?.trim() ?? '';
        if (g.isNotEmpty) {
          return g.replaceAll(RegExp(r'[{}]'), '').toLowerCase();
        }
      } else if (Platform.isLinux) {
        final l = await plugin.linuxInfo;
        final mid = l.machineId?.trim() ?? '';
        if (mid.isNotEmpty) {
          return mid;
        }
      }
    } catch (_) {
      // Registry / platform channel unavailable.
    }
    var fp = prefs.getString(lemonSqueezyInstanceFingerprintKey);
    if (fp == null || fp.isEmpty) {
      fp = const Uuid().v4();
      await prefs.setString(lemonSqueezyInstanceFingerprintKey, fp);
    }
    return 'app-$fp';
  }

  /// Validate an existing Lemon instance on this device (no new activation slot).
  Future<ProActivationResult> _lemonValidateWithInstance(
    String licenseKey,
    String instanceId,
  ) async {
    final verifyUri = Uri.tryParse(state.lemonVerifyUrl);
    if (verifyUri == null || verifyUri.host.isEmpty) {
      return const ProActivationResult(
        success: false,
        message: 'Lemon Squeezy verification endpoint is invalid.',
      );
    }
    try {
      final verifyResponse = await http
          .post(
            verifyUri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{
              'license_key': licenseKey,
              'instance_id': instanceId,
            },
          )
          .timeout(const Duration(seconds: 8));
      if (verifyResponse.statusCode < 200 || verifyResponse.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message:
              'Cannot verify Lemon Squeezy license now. Please try again shortly.',
        );
      }
      final dynamic verifyDecoded = jsonDecode(verifyResponse.body);
      if (verifyDecoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'Lemon Squeezy response is invalid.',
        );
      }
      final valid = verifyDecoded['valid'] == true;
      if (!valid) {
        return const ProActivationResult(
          success: false,
          message: 'License key is invalid or not active.',
        );
      }
      return const ProActivationResult(
        success: true,
        message: 'Pro activated successfully.',
      );
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach Lemon Squeezy now. Please try again later.',
      );
    }
  }

  Future<ProActivationResult> _lemonActivateDirect(
    String licenseKey,
    String instanceName,
  ) async {
    final activateUri = Uri.tryParse(state.lemonActivateUrl);
    if (activateUri == null || activateUri.host.isEmpty) {
      return const ProActivationResult(
        success: false,
        message: 'Lemon Squeezy activation endpoint is invalid.',
      );
    }
    try {
      final response = await http
          .post(
            activateUri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{
              'license_key': licenseKey,
              'instance_name': instanceName,
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message: 'Cannot activate license now. Please try again shortly.',
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'Lemon Squeezy activation response is invalid.',
        );
      }
      if (decoded['activated'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(lemonLastLicenseKeyKey, licenseKey);
        final inst = decoded['instance'];
        if (inst is Map<String, dynamic> && inst['id'] != null) {
          await prefs.setString(
            lemonLicenseInstanceIdKey,
            inst['id'].toString(),
          );
        }
        return const ProActivationResult(
          success: true,
          message: 'Pro activated successfully.',
        );
      }
      final err = decoded['error'];
      final msg = err is String && err.trim().isNotEmpty
          ? err.trim()
          : 'License could not be activated.';
      return ProActivationResult(success: false, message: msg);
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach Lemon Squeezy now. Please try again later.',
      );
    }
  }

  Future<ProActivationResult?> _lemonTryReuseStoredInstance(
    String licenseKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = (prefs.getString(lemonLastLicenseKeyKey) ?? '').trim();
    final savedInst = (prefs.getString(lemonLicenseInstanceIdKey) ?? '').trim();
    if (savedKey != licenseKey || savedInst.isEmpty) {
      return null;
    }
    final r = await _lemonValidateWithInstance(licenseKey, savedInst);
    return r.success ? r : null;
  }

  Future<ProActivationResult> _verifyLemonSqueezyLicense(
    String licenseKey,
  ) async {
    final proxyUri = Uri.tryParse(state.lemonLicenseProxyUrl.trim());
    if (proxyUri != null && proxyUri.host.isNotEmpty) {
      return _verifyLemonSqueezyViaProxy(licenseKey, proxyUri);
    }

    final verifyUri = Uri.tryParse(state.lemonVerifyUrl);
    if (verifyUri == null || verifyUri.host.isEmpty) {
      return const ProActivationResult(
        success: false,
        message: 'Lemon Squeezy verification endpoint is invalid.',
      );
    }
    final early = await _lemonTryReuseStoredInstance(licenseKey);
    if (early != null) {
      return early;
    }
    final prefs = await SharedPreferences.getInstance();
    try {
      final verifyResponse = await http
          .post(
            verifyUri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{'license_key': licenseKey},
          )
          .timeout(const Duration(seconds: 8));
      if (verifyResponse.statusCode < 200 || verifyResponse.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message:
              'Cannot verify Lemon Squeezy license now. Please try again shortly.',
        );
      }
      final dynamic verifyDecoded = jsonDecode(verifyResponse.body);
      if (verifyDecoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'Lemon Squeezy response is invalid.',
        );
      }
      final valid = verifyDecoded['valid'] == true;
      final license = verifyDecoded['license_key'];
      final status = license is Map<String, dynamic>
          ? (license['status'] as String?)?.toLowerCase()
          : null;
      final licenseStoreId = _readNumericIdAsString(
        license,
        primaryKey: 'store_id',
        secondaryKey: 'storeId',
      );
      final licenseProductId = _readNumericIdAsString(
        license,
        primaryKey: 'product_id',
        secondaryKey: 'productId',
      );
      final licenseVariantId = _readNumericIdAsString(
        license,
        primaryKey: 'variant_id',
        secondaryKey: 'variantId',
      );
      if (!valid || status == 'disabled' || status == 'expired') {
        return const ProActivationResult(
          success: false,
          message: 'License key is invalid or not active.',
        );
      }
      final expectedStoreId = state.lemonExpectedStoreId.trim();
      if (expectedStoreId.isNotEmpty &&
          licenseStoreId.isNotEmpty &&
          licenseStoreId != expectedStoreId) {
        return const ProActivationResult(
          success: false,
          message: 'This license does not belong to this store.',
        );
      }
      final expectedProductId = state.lemonExpectedProductId.trim();
      if (expectedProductId.isNotEmpty &&
          licenseProductId.isNotEmpty &&
          licenseProductId != expectedProductId) {
        return const ProActivationResult(
          success: false,
          message: 'This license is not valid for this product.',
        );
      }
      final expectedVariantId = state.lemonExpectedVariantId.trim();
      if (expectedVariantId.isNotEmpty &&
          licenseVariantId.isNotEmpty &&
          licenseVariantId != expectedVariantId) {
        return const ProActivationResult(
          success: false,
          message: 'This license is not valid for this edition.',
        );
      }
      final instanceName = await _buildLemonInstanceName(prefs);
      return _lemonActivateDirect(licenseKey, instanceName);
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach Lemon Squeezy now. Please try again later.',
      );
    }
  }

  Future<ProActivationResult> _verifyLemonSqueezyViaProxy(
    String licenseKey,
    Uri proxyUri,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = (prefs.getString(lemonLastLicenseKeyKey) ?? '').trim();
      final savedInst = (prefs.getString(lemonLicenseInstanceIdKey) ?? '')
          .trim();
      final instanceName = await _buildLemonInstanceName(prefs);
      final token = state.lemonLicenseProxyAuthToken.trim();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final payload = <String, dynamic>{
        'licenseKey': licenseKey,
        'instanceName': instanceName,
        if (savedKey == licenseKey && savedInst.isNotEmpty)
          'instanceId': savedInst,
      };
      final response = await http
          .post(proxyUri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        return const ProActivationResult(
          success: false,
          message:
              'License verification is misconfigured. Please contact support.',
        );
      }
      if (response.statusCode == 400) {
        try {
          final dynamic d = jsonDecode(response.body);
          if (d is Map<String, dynamic> && d['message'] is String) {
            return ProActivationResult(
              success: false,
              message: d['message'] as String,
            );
          }
        } catch (_) {}
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message:
              'Cannot verify Lemon Squeezy license now. Please try again shortly.',
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'License verification response is invalid.',
        );
      }
      final isValid = decoded['valid'] == true;
      final message = decoded['message'] is String
          ? decoded['message'] as String
          : (isValid
                ? 'Pro activated successfully.'
                : 'License key is invalid. Please check and try again.');
      if (isValid) {
        final idRaw = decoded['instanceId'];
        if (idRaw is String && idRaw.trim().isNotEmpty) {
          await prefs.setString(lemonLastLicenseKeyKey, licenseKey);
          await prefs.setString(lemonLicenseInstanceIdKey, idRaw.trim());
        }
      }
      return ProActivationResult(success: isValid, message: message);
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach license server. Please try again later.',
      );
    }
  }

  Future<ProActivationResult?> _verifyProKeyWithApi(
    String normalizedKey,
  ) async {
    final verifyUri = Uri.tryParse(state.licenseVerifyUrl);
    if (verifyUri == null || verifyUri.host.isEmpty) {
      return null;
    }
    try {
      final response = await http
          .post(
            verifyUri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, String>{'licenseKey': normalizedKey}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ProActivationResult(
          success: false,
          message: 'License server is unavailable. Please try again later.',
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProActivationResult(
          success: false,
          message: 'License verification response is invalid.',
        );
      }
      final isValid = decoded['valid'] == true;
      final message = decoded['message'] is String
          ? decoded['message'] as String
          : (isValid
                ? 'Pro activated successfully.'
                : 'License key is invalid. Please check and try again.');
      return ProActivationResult(success: isValid, message: message);
    } catch (_) {
      return const ProActivationResult(
        success: false,
        message: 'Cannot reach license server. Please try again later.',
      );
    }
  }

  Future<void> refreshRemoteConfig() async {
    await Future.wait<void>([refreshAdConfig(), checkForUpdates()]);
  }

  Future<void> checkForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(Uri.parse(_appConfigUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final latestVersion =
          decoded['latestVersion'] is String && decoded['latestVersion'] != ''
          ? decoded['latestVersion'] as String
          : state.latestVersion;
      final minSupportedVersion =
          decoded['minSupportedVersion'] is String &&
              decoded['minSupportedVersion'] != ''
          ? decoded['minSupportedVersion'] as String
          : state.minSupportedVersion;
      final downloadUrl =
          decoded['downloadUrl'] is String &&
              Uri.tryParse(decoded['downloadUrl'] as String) != null
          ? decoded['downloadUrl'] as String
          : state.downloadUrl;
      final forceUpdate = decoded['forceUpdate'] is bool
          ? decoded['forceUpdate'] as bool
          : state.forceUpdate;
      final releaseNotes = decoded['releaseNotes'] is String
          ? decoded['releaseNotes'] as String
          : state.releaseNotes;
      final licenseVerifyUrl =
          decoded['licenseVerifyUrl'] is String &&
              Uri.tryParse(decoded['licenseVerifyUrl'] as String) != null
          ? decoded['licenseVerifyUrl'] as String
          : state.licenseVerifyUrl;
      final proProvider =
          decoded['proProvider'] is String &&
              (decoded['proProvider'] == 'gumroad' ||
                  decoded['proProvider'] == 'lemonsqueezy' ||
                  decoded['proProvider'] == 'custom')
          ? decoded['proProvider'] as String
          : state.proProvider;
      final gumroadProductPermalink =
          decoded['gumroadProductPermalink'] is String
          ? decoded['gumroadProductPermalink'] as String
          : state.gumroadProductPermalink;
      final gumroadVerifyUrl =
          decoded['gumroadVerifyUrl'] is String &&
              Uri.tryParse(decoded['gumroadVerifyUrl'] as String) != null
          ? decoded['gumroadVerifyUrl'] as String
          : state.gumroadVerifyUrl;
      final gumroadUseIncrementUsesCount =
          decoded['gumroadUseIncrementUsesCount'] is bool
          ? decoded['gumroadUseIncrementUsesCount'] as bool
          : state.gumroadUseIncrementUsesCount;
      var lemonLicenseProxyUrl = state.lemonLicenseProxyUrl;
      if (decoded['lemonLicenseProxyUrl'] is String) {
        final raw = (decoded['lemonLicenseProxyUrl'] as String).trim();
        if (raw.isEmpty) {
          lemonLicenseProxyUrl = '';
        } else {
          final parsed = Uri.tryParse(raw);
          if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
            lemonLicenseProxyUrl = raw;
          }
        }
      }
      final lemonLicenseProxyAuthToken =
          decoded['lemonLicenseProxyAuthToken'] is String
          ? decoded['lemonLicenseProxyAuthToken'] as String
          : state.lemonLicenseProxyAuthToken;
      final lemonVerifyUrl =
          decoded['lemonVerifyUrl'] is String &&
              Uri.tryParse(decoded['lemonVerifyUrl'] as String) != null
          ? decoded['lemonVerifyUrl'] as String
          : state.lemonVerifyUrl;
      final lemonActivateUrl =
          decoded['lemonActivateUrl'] is String &&
              Uri.tryParse(decoded['lemonActivateUrl'] as String) != null
          ? decoded['lemonActivateUrl'] as String
          : state.lemonActivateUrl;
      final lemonInstanceName = decoded['lemonInstanceName'] is String
          ? decoded['lemonInstanceName'] as String
          : state.lemonInstanceName;
      final lemonStoreName = decoded['lemonStoreName'] is String
          ? decoded['lemonStoreName'] as String
          : state.lemonStoreName;
      final lemonExpectedStoreId = decoded['lemonExpectedStoreId'] is String
          ? decoded['lemonExpectedStoreId'] as String
          : state.lemonExpectedStoreId;
      final lemonExpectedProductId = decoded['lemonExpectedProductId'] is String
          ? decoded['lemonExpectedProductId'] as String
          : state.lemonExpectedProductId;
      final lemonExpectedVariantId = decoded['lemonExpectedVariantId'] is String
          ? decoded['lemonExpectedVariantId'] as String
          : state.lemonExpectedVariantId;
      final validProKeys = decoded['validProKeys'] is List
          ? (decoded['validProKeys'] as List)
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : const <String>[];
      final nextFreeDailyReviewLimit = _parseConfigPositiveInt(
        decoded['freeDailyReviewLimit'],
        fallback: state.freeDailyReviewLimit,
        min: 1,
        max: 2000,
      );
      state = state.copyWith(
        latestVersion: latestVersion,
        minSupportedVersion: minSupportedVersion,
        downloadUrl: downloadUrl,
        forceUpdate: forceUpdate,
        releaseNotes: releaseNotes,
        licenseVerifyUrl: licenseVerifyUrl,
        proProvider: proProvider,
        gumroadProductPermalink: gumroadProductPermalink,
        gumroadVerifyUrl: gumroadVerifyUrl,
        gumroadUseIncrementUsesCount: gumroadUseIncrementUsesCount,
        lemonLicenseProxyUrl: lemonLicenseProxyUrl,
        lemonLicenseProxyAuthToken: lemonLicenseProxyAuthToken,
        lemonVerifyUrl: lemonVerifyUrl,
        lemonActivateUrl: lemonActivateUrl,
        lemonInstanceName: lemonInstanceName,
        lemonStoreName: lemonStoreName,
        lemonExpectedStoreId: lemonExpectedStoreId,
        lemonExpectedProductId: lemonExpectedProductId,
        lemonExpectedVariantId: lemonExpectedVariantId,
        freeDailyReviewLimit: nextFreeDailyReviewLimit,
      );
      await prefs.setString(latestVersionKey, latestVersion);
      await prefs.setString(minSupportedVersionKey, minSupportedVersion);
      await prefs.setString(downloadUrlKey, downloadUrl);
      await prefs.setBool(forceUpdateKey, forceUpdate);
      await prefs.setString(releaseNotesKey, releaseNotes);
      await prefs.setString(licenseVerifyUrlKey, licenseVerifyUrl);
      await prefs.setString(proProviderKey, proProvider);
      await prefs.setString(
        gumroadProductPermalinkKey,
        gumroadProductPermalink,
      );
      await prefs.setString(gumroadVerifyUrlKey, gumroadVerifyUrl);
      await prefs.setBool(
        gumroadUseIncrementUsesCountKey,
        gumroadUseIncrementUsesCount,
      );
      await prefs.setString(lemonLicenseProxyUrlKey, lemonLicenseProxyUrl);
      await prefs.setString(
        lemonLicenseProxyAuthTokenKey,
        lemonLicenseProxyAuthToken,
      );
      await prefs.setString(lemonVerifyUrlKey, lemonVerifyUrl);
      await prefs.setString(lemonActivateUrlKey, lemonActivateUrl);
      await prefs.setString(lemonInstanceNameKey, lemonInstanceName);
      await prefs.setString(lemonStoreNameKey, lemonStoreName);
      await prefs.setString(lemonExpectedStoreIdKey, lemonExpectedStoreId);
      await prefs.setString(lemonExpectedProductIdKey, lemonExpectedProductId);
      await prefs.setString(lemonExpectedVariantIdKey, lemonExpectedVariantId);
      await prefs.setStringList(validProKeysKey, validProKeys);
      await prefs.setInt(freeDailyReviewLimitKey, nextFreeDailyReviewLimit);
    } catch (_) {
      // Keep cached settings when remote config is unavailable.
    }
  }

  Future<void> refreshAdConfig() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(Uri.parse(_adConfigUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final dynamic rawEnabled = decoded['enabled'];
      final dynamic rawAdUrl = decoded['adUrl'];
      final isEnabled = rawEnabled is bool ? rawEnabled : state.isAdsEnabled;
      final nextAdUrl = rawAdUrl is String && Uri.tryParse(rawAdUrl) != null
          ? rawAdUrl
          : state.adUrl;
      state = state.copyWith(isAdsEnabled: isEnabled, adUrl: nextAdUrl);
      await prefs.setBool(isAdsEnabledKey, isEnabled);
      await prefs.setString(adUrlKey, nextAdUrl);
    } catch (_) {
      // Keep current state when remote config is unavailable.
    }
  }
}

String _readNumericIdAsString(
  dynamic source, {
  required String primaryKey,
  required String secondaryKey,
}) {
  if (source is! Map<String, dynamic>) {
    return '';
  }
  final dynamic value = source[primaryKey] ?? source[secondaryKey];
  if (value == null) {
    return '';
  }
  if (value is num) {
    return value.toInt().toString();
  }
  final text = value.toString().trim();
  return text;
}

final appStateProvider = NotifierProvider<AppStateController, AppState>(
  AppStateController.new,
);

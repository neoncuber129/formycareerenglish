import 'dart:async';
import 'dart:io';

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

import 'core/theme/desktop_text_scale.dart';
import 'core/window/popup_native_frame_sync.dart';
import 'features/capture/presentation/capture_popup.dart';

void _overlayLog(String stage, [Object? detail]) {
  try {
    final line =
        '[overlay][${DateTime.now().toIso8601String()}] $stage${detail == null ? '' : ' :: $detail'}\n';
    File('overlay-debug.log').writeAsStringSync(line, mode: FileMode.append);
  } catch (_) {}
}

ThemeData _overlayLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0067C0),
      brightness: Brightness.light,
    ),
    visualDensity: VisualDensity.standard,
  );
}

Future<void> runOverlayApp() async {
  _overlayLog('runOverlayApp entered');
  WidgetsFlutterBinding.ensureInitialized();
  _overlayLog('binding ensured');
  runApp(const ProviderScope(child: OverlayPopupApp()));
  _overlayLog('runApp called');
}

class OverlayPopupCommand {
  const OverlayPopupCommand({
    required this.requestId,
    required this.mode,
    required this.cursorPosition,
    required this.selectedRegion,
    required this.selectedText,
    required this.sourceApp,
    required this.sourceUrl,
    required this.tagSuggestions,
    required this.nativeLanguage,
    required this.sourceLanguages,
  });

  final int requestId;
  final CapturePopupMode mode;
  final Offset? cursorPosition;
  final Rect? selectedRegion;
  final String? selectedText;
  final String? sourceApp;
  final String? sourceUrl;
  final List<String> tagSuggestions;
  final String? nativeLanguage;
  final List<String> sourceLanguages;

  static OverlayPopupCommand? fromEvent(Object? event) {
    if (event is! Map<Object?, Object?>) {
      return null;
    }
    final requestId = event['requestId'];
    final modeValue = event['mode'];
    if (requestId is! int || modeValue is! String) {
      return null;
    }
    final cursorX = event['cursorX'];
    final cursorY = event['cursorY'];
    final regionLeft = event['regionLeft'];
    final regionTop = event['regionTop'];
    final regionWidth = event['regionWidth'];
    final regionHeight = event['regionHeight'];
    final selectedTextValue = event['selectedText'];
    final sourceAppValue = event['sourceApp'];
    final sourceUrlValue = event['sourceUrl'];
    final tagSuggestionsValue = event['tagSuggestions'];
    final nativeLanguageValue = event['nativeLanguage'];
    final sourceLanguagesValue = event['sourceLanguages'];
    final List<String> sourceLangs = <String>[];
    if (sourceLanguagesValue is List) {
      for (final entry in sourceLanguagesValue) {
        if (entry is String && entry.trim().isNotEmpty) {
          sourceLangs.add(entry.trim());
        }
      }
    }
    final List<String> tagSuggestions = <String>[];
    if (tagSuggestionsValue is List) {
      for (final entry in tagSuggestionsValue) {
        if (entry is String && entry.trim().isNotEmpty) {
          tagSuggestions.add(entry.trim());
        }
      }
    }
    return OverlayPopupCommand(
      requestId: requestId,
      mode: modeValue == 'image'
          ? CapturePopupMode.image
          : CapturePopupMode.text,
      cursorPosition: cursorX is num && cursorY is num
          ? Offset(cursorX.toDouble(), cursorY.toDouble())
          : null,
      selectedRegion:
          regionLeft is num &&
              regionTop is num &&
              regionWidth is num &&
              regionHeight is num
          ? Rect.fromLTWH(
              regionLeft.toDouble(),
              regionTop.toDouble(),
              regionWidth.toDouble(),
              regionHeight.toDouble(),
            )
          : null,
      selectedText: selectedTextValue is String ? selectedTextValue : null,
      sourceApp: sourceAppValue is String ? sourceAppValue : null,
      sourceUrl: sourceUrlValue is String ? sourceUrlValue : null,
      tagSuggestions: tagSuggestions,
      nativeLanguage: nativeLanguageValue is String
          ? nativeLanguageValue
          : null,
      sourceLanguages: sourceLangs,
    );
  }
}

class OverlayPopupApp extends ConsumerWidget {
  const OverlayPopupApp({super.key});

  static Color get transparencyColor =>
      Platform.isWindows ? const Color(0xFFFF00FF) : Colors.transparent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiTag = ref.watch(uiLocalePreferenceProvider);
    final uiTextScale = ref.watch(uiTextScalePreferenceProvider);
    final locale = localeFromUiPreferenceTag(uiTag);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _overlayLightTheme(),
      themeMode: ThemeMode.light,
      builder: (context, child) => attachDesktopCombinedTextScaler(
        context,
        child,
        userTextScaleMultiplier: uiTextScale,
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(color: transparencyColor, child: const OverlayPopupHost()),
    );
  }
}

class OverlayPopupHost extends StatefulWidget {
  const OverlayPopupHost({super.key});

  @override
  State<OverlayPopupHost> createState() => _OverlayPopupHostState();
}

class _OverlayPopupHostState extends State<OverlayPopupHost>
    with WidgetsBindingObserver {
  static const EventChannel _eventChannel = EventChannel(
    'formycareer/popup_window_events',
  );
  static const MethodChannel _controlChannel = MethodChannel(
    'formycareer/popup_window_control',
  );
  static const Duration _barrierPointerGrace = Duration(milliseconds: 450);
  static const Duration _commandSettleDelay = Duration(milliseconds: 120);
  static const Duration _commandBurstWindow = Duration(milliseconds: 220);

  StreamSubscription<Object?>? _subscription;
  OverlayPopupCommand? _command;
  OverlayPopupCommand? _pendingCommand;
  Timer? _pendingCommandTimer;
  DateTime _ignoreBarrierPointerUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastCommandReceivedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _overlayLog('OverlayPopupHost.initState subscribing');
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      _overlayLog('event received', event.runtimeType);
      final command = OverlayPopupCommand.fromEvent(event);
      if (command == null || !mounted) {
        return;
      }
      final now = DateTime.now();
      final shouldSettle =
          _lastCommandReceivedAt != null &&
          now.difference(_lastCommandReceivedAt!) < _commandBurstWindow;
      _lastCommandReceivedAt = now;
      if (!shouldSettle) {
        _pendingCommandTimer?.cancel();
        _pendingCommand = null;
        setState(() {
          _command = command;
          _ignoreBarrierPointerUntil = DateTime.now().add(_barrierPointerGrace);
        });
        return;
      }
      _pendingCommand = command;
      _pendingCommandTimer?.cancel();
      _pendingCommandTimer = Timer(_commandSettleDelay, () {
        if (!mounted || _pendingCommand == null) {
          return;
        }
        setState(() {
          _command = _pendingCommand;
          _pendingCommand = null;
          _ignoreBarrierPointerUntil = DateTime.now().add(_barrierPointerGrace);
        });
      });
    });
    _overlayLog('OverlayPopupHost subscription done');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _pendingCommandTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_command == null) {
      return;
    }
    // On macOS floating/non-activating windows can briefly report inactive
    // during handoff; closing on inactive causes blink-and-dismiss.
    final closeOnInactive = !Platform.isMacOS;
    if ((closeOnInactive && state == AppLifecycleState.inactive) ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_closePopupWindow());
    }
  }

  Future<void> _closePopupWindow() async {
    _pendingCommandTimer?.cancel();
    _pendingCommand = null;
    setState(() {
      _command = null;
    });
    try {
      await _controlChannel.invokeMethod<void>('hidePopupWindow');
    } catch (_) {}
  }

  Future<CapturePopupSaveResult> _saveThroughMainBridge(
    CapturePopupSaveRequest request,
  ) async {
    final state = request.state;
    try {
      final response = await _controlChannel
          .invokeMethod<Object>('saveCapturedWord', <String, Object>{
            'sourceText': state.sourceText,
            'translatedText': state.translatedText,
            'languagePair': state.languagePair,
            'passage': request.passage,
            if (request.selectionStart != null)
              'selectionStart': request.selectionStart!,
            if (request.selectionEnd != null) 'selectionEnd': request.selectionEnd!,
            'sourceUrl': request.sourceUrl,
            'tags': state.tags,
            'sourceApp': state.sourceApp,
          });
      if (response is Map<Object?, Object?>) {
        final success = response['success'] == true;
        final message = response['message'];
        return CapturePopupSaveResult(
          success: success,
          message: message is String
              ? message
              : (success ? 'Saved ✓' : 'Save failed'),
        );
      }
    } catch (_) {}
    return const CapturePopupSaveResult(
      success: false,
      message: 'Save bridge failed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OverlayPopupApp.transparencyColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(color: OverlayPopupApp.transparencyColor),
          ),
          if (_command != null)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {
                  if (DateTime.now().isBefore(_ignoreBarrierPointerUntil)) {
                    return;
                  }
                  unawaited(_closePopupWindow());
                },
              ),
            ),
          if (_command != null)
            Positioned(
              left: 0,
              top: 0,
              child: PopupNativeFrameSync(
                key: ValueKey<int>(_command!.requestId),
                child: CapturePopup(
                  key: ValueKey<int>(_command!.requestId),
                  onClose: () => unawaited(_closePopupWindow()),
                  mode: _command!.mode,
                  cursorPosition: _command!.cursorPosition,
                  selectedRegion: _command!.selectedRegion,
                  initialSourceText: _command!.selectedText,
                  sourceAppHint: _command!.sourceApp,
                  sourceUrlHint: _command!.sourceUrl,
                  initialTagSuggestions: _command!.tagSuggestions,
                  nativeLanguage: _command!.nativeLanguage,
                  sourceLanguages: _command!.sourceLanguages,
                  onSaveRequested: _saveThroughMainBridge,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

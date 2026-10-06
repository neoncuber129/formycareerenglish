import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    required this.isPro,
    this.height = 72,
    this.adUrl = const String.fromEnvironment(
      'DESKTOP_BANNER_AD_URL',
      defaultValue: 'https://formycareer.vercel.app',
    ),
    super.key,
  });

  final bool isPro;
  final double height;
  final String adUrl;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  WebViewController? _macController;
  WebviewController? _windowsController;
  StreamSubscription<String>? _windowsUrlSub;
  StreamSubscription<WebErrorStatus>? _windowsErrorSub;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isPro) {
      unawaited(_initializeWebView());
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPro && !oldWidget.isPro) {
      _disposeControllers();
      setState(() {
        _errorMessage = null;
      });
      return;
    }
    if (!widget.isPro && oldWidget.isPro) {
      setState(() {
        _errorMessage = null;
      });
      unawaited(_initializeWebView());
    }
  }

  Future<void> _initializeWebView() async {
    final uri = Uri.tryParse(widget.adUrl);
    if (uri == null || uri.host.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid ad URL';
      });
      return;
    }

    if (Platform.isMacOS) {
      await _initMacController(uri);
      return;
    }

    if (Platform.isWindows) {
      await _initWindowsController(uri);
      return;
    }

    setState(() {
      _errorMessage = 'Desktop ads are only supported on Windows/macOS';
    });
  }

  Future<void> _initMacController(Uri adUri) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            debugPrint('Banner macOS error: ${error.description}');
            setState(() {
              _errorMessage = 'Ad failed to load';
            });
          },
          onNavigationRequest: (request) {
            final next = Uri.tryParse(request.url);
            if (!_isAllowedNavigation(next)) {
              debugPrint('Banner blocked external navigation: ${request.url}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(adUri);

    if (!mounted) {
      return;
    }
    setState(() => _macController = controller);
  }

  Future<void> _initWindowsController(Uri adUri) async {
    final controller = WebviewController();
    try {
      await WebviewController.initializeEnvironment();
      await controller.initialize();
      await controller.setBackgroundColor(Colors.transparent);

      _windowsUrlSub = controller.url.listen((url) {
        final next = Uri.tryParse(url);
        if (_isAllowedNavigation(next)) {
          return;
        }
        debugPrint('Banner blocked external navigation on Windows: $url');
        unawaited(controller.loadUrl(adUri.toString()));
      });
      _windowsErrorSub = controller.onLoadError.listen((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Ad failed to load';
        });
      });

      await controller.loadUrl(adUri.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _windowsController = controller;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('Banner Windows initialization failed: $error');
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Ad failed to initialize';
      });
    }
  }

  bool _isAllowedNavigation(Uri? uri) {
    if (uri == null) {
      return false;
    }
    final root = Uri.tryParse(widget.adUrl);
    if (root == null || root.host.isEmpty) {
      return false;
    }
    return uri.host == root.host;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    unawaited(_windowsUrlSub?.cancel() ?? Future<void>.value());
    unawaited(_windowsErrorSub?.cancel() ?? Future<void>.value());
    _windowsUrlSub = null;
    _windowsErrorSub = null;
    unawaited(_windowsController?.dispose() ?? Future<void>.value());
    _windowsController = null;
    _macController = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPro) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildWebView(),
            if (_errorMessage != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    unawaited(_initializeWebView());
                  },
                  child: const Text('Retry ad'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    if (Platform.isMacOS) {
      if (_macController == null) {
        return const SizedBox.shrink();
      }
      return WebViewWidget(controller: _macController!);
    }

    if (Platform.isWindows) {
      if (_windowsController == null) {
        return const SizedBox.shrink();
      }
      return Webview(_windowsController!);
    }

    return const SizedBox.shrink();
  }
}

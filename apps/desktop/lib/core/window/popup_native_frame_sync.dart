import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reports the laid-out logical size of [child] to the native popup HWND via
/// `formycareer/popup_window_control` so the Win32 frame can match Flutter when
/// capture content height/width changes (e.g. word selection).
class PopupNativeFrameSync extends StatefulWidget {
  const PopupNativeFrameSync({super.key, required this.child});

  final Widget child;

  @override
  State<PopupNativeFrameSync> createState() => _PopupNativeFrameSyncState();
}

class _PopupNativeFrameSyncState extends State<PopupNativeFrameSync> {
  static const MethodChannel _channel = MethodChannel(
    'formycareer/popup_window_control',
  );

  /// Wait for short layout bursts (AnimatedSize, text wraps) to settle before
  /// pushing frame updates to native host, reducing visible resize flicker.
  static const Duration _postAnimatedSizeSettle = Duration(milliseconds: 140);
  static const double _minResizeDeltaPx = 8;

  final GlobalKey _measureKey = GlobalKey();
  Size? _lastReported;
  bool _scheduled = false;
  bool _reportedAtLeastOnce = false;
  Timer? _debouncedRemeasure;
  Timer? _metricsWindowTimer;
  Timer? _openingLayoutTimer;
  DateTime? _firstReportAt;
  int _resizeCountFirst2s = 0;
  double _maxDeltaFirst2s = 0;

  void _resetReportingForNewSession() {
    _debouncedRemeasure?.cancel();
    _debouncedRemeasure = null;
    _openingLayoutTimer?.cancel();
    _openingLayoutTimer = null;
    _lastReported = null;
    _reportedAtLeastOnce = false;
    _firstReportAt = null;
    _metricsWindowTimer?.cancel();
    _metricsWindowTimer = null;
    _resizeCountFirst2s = 0;
    _maxDeltaFirst2s = 0;
  }

  void _tryReportSize() {
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final s = box.size;
    final prev = _lastReported;
    if (_lastReported != null &&
        (s.width - _lastReported!.width).abs() < _minResizeDeltaPx &&
        (s.height - _lastReported!.height).abs() < _minResizeDeltaPx) {
      return;
    }
    final delta = prev == null
        ? 0.0
        : (s.width - prev.width).abs() + (s.height - prev.height).abs();
    _lastReported = s;
    _reportedAtLeastOnce = true;
    _firstReportAt ??= DateTime.now();
    if (_metricsWindowTimer == null) {
      _metricsWindowTimer = Timer(const Duration(seconds: 2), () {
        final startedAt = _firstReportAt;
        if (startedAt != null) {
          final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
          debugPrint(
            'popup_dbg resize_count_first_2s=$_resizeCountFirst2s '
            'max_size_delta_first_2s=${_maxDeltaFirst2s.toStringAsFixed(1)} '
            'window_ms=$elapsedMs',
          );
        }
      });
    }
    if (DateTime.now().difference(_firstReportAt!) <= const Duration(seconds: 2)) {
      _resizeCountFirst2s += 1;
      if (delta > _maxDeltaFirst2s) {
        _maxDeltaFirst2s = delta;
      }
    }
    unawaited(
      _channel
          .invokeMethod<void>('setPopupFrameSize', <String, Object>{
            'width': s.width,
            'height': s.height,
          })
          .catchError((_) {}),
    );
  }

  void _scheduleOpeningLayoutFollowUps() {
    _openingLayoutTimer?.cancel();
    _openingLayoutTimer = Timer(const Duration(milliseconds: 260), () {
      _openingLayoutTimer = null;
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _tryReportSize();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleOpeningLayoutFollowUps();
  }

  @override
  void didUpdateWidget(covariant PopupNativeFrameSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _resetReportingForNewSession();
      _scheduleOpeningLayoutFollowUps();
    }
  }

  void _scheduleReport({bool immediate = false}) {
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
      });
    }
    if (immediate) {
      _debouncedRemeasure?.cancel();
      _debouncedRemeasure = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _tryReportSize();
      });
      return;
    }
    _debouncedRemeasure?.cancel();
    _debouncedRemeasure = Timer(_postAnimatedSizeSettle, () {
      _debouncedRemeasure = null;
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _tryReportSize();
      });
    });
  }

  @override
  void dispose() {
    _debouncedRemeasure?.cancel();
    _openingLayoutTimer?.cancel();
    _metricsWindowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleReport(immediate: !_reportedAtLeastOnce);
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleReport();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _measureKey, child: widget.child),
      ),
    );
  }
}

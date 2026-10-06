import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegionSelectorOverlay extends StatefulWidget {
  const RegionSelectorOverlay({
    required this.onSelected,
    required this.onCancel,
    super.key,
  });

  final ValueChanged<Rect> onSelected;
  final VoidCallback onCancel;

  @override
  State<RegionSelectorOverlay> createState() => _RegionSelectorOverlayState();
}

class _RegionSelectorOverlayState extends State<RegionSelectorOverlay> {
  Offset? _start;
  Offset? _current;
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rect = _selectionRect();
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _start = details.globalPosition;
            _current = details.globalPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _current = details.globalPosition;
          });
        },
        onPanEnd: (_) {
          final selected = _selectionRect();
          if (selected != null &&
              selected.width >= 8 &&
              selected.height >= 8) {
            widget.onSelected(selected);
            return;
          }
          widget.onCancel();
        },
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Stack(
            children: [
              if (rect != null)
                Positioned.fromRect(
                  rect: rect,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              const Positioned(
                left: 16,
                top: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Drag to select region. Esc to cancel.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect? _selectionRect() {
    final start = _start;
    final current = _current;
    if (start == null || current == null) {
      return null;
    }
    return Rect.fromPoints(start, current);
  }
}


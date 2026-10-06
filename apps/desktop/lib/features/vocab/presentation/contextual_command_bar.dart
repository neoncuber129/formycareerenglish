import 'package:app_l10n/app_l10n.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// Win11-style floating command strip with acrylic-like blur (in-window).
class ContextualCommandBar extends StatefulWidget {
  const ContextualCommandBar({
    super.key,
    required this.selectedCount,
    this.tagButtonKey,
    this.onCancel,
    this.onTag,
    this.onStudySelected,
    this.onArchive,
    this.onResetSrs,
    this.onDelete,
  });

  final int selectedCount;

  /// When set, attached to the Tag control for [BulkTaggingFlyout] positioning.
  final GlobalKey? tagButtonKey;
  final VoidCallback? onCancel;
  final VoidCallback? onTag;
  final VoidCallback? onStudySelected;
  final VoidCallback? onArchive;
  final VoidCallback? onResetSrs;
  final VoidCallback? onDelete;

  @override
  State<ContextualCommandBar> createState() => _ContextualCommandBarState();
}

class _ContextualCommandBarState extends State<ContextualCommandBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    if (widget.selectedCount > 0) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ContextualCommandBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCount > 0 && oldWidget.selectedCount == 0) {
      _controller.forward();
    } else if (widget.selectedCount == 0 && oldWidget.selectedCount > 0) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseFill = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F3F3);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        ignoring: widget.selectedCount == 0,
        child: Opacity(
          opacity: widget.selectedCount == 0 ? 0 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        widget.selectedCount == 1
                            ? l10n.cmdOneItemSelected
                            : l10n.cmdManyItemsSelected(widget.selectedCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: widget.selectedCount == 0
                            ? null
                            : widget.onCancel,
                        child: Text(l10n.cmdCancelEsc),
                      ),
                      const Spacer(),
                      _CommandIconButton(
                        anchorKey: widget.tagButtonKey,
                        icon: FluentIcons.tag_24_regular,
                        label: l10n.commonTag,
                        onPressed: widget.onTag,
                      ),
                      const SizedBox(width: 4),
                      _CommandIconButton(
                        icon: FluentIcons.book_24_regular,
                        label: l10n.commonStudy,
                        onPressed: widget.onStudySelected,
                      ),
                      const SizedBox(width: 4),
                      _CommandIconButton(
                        icon: FluentIcons.archive_24_regular,
                        label: l10n.commonArchive,
                        onPressed: widget.onArchive,
                      ),
                      const SizedBox(width: 4),
                      _CommandIconButton(
                        icon: FluentIcons.arrow_reset_24_regular,
                        label: l10n.commonResetSrs,
                        onPressed: widget.onResetSrs,
                      ),
                      const SizedBox(width: 4),
                      _CommandIconButton(
                        icon: FluentIcons.delete_24_regular,
                        label: l10n.commonDelete,
                        onPressed: widget.onDelete,
                        foreground: const Color(0xFFC42B1C),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandIconButton extends StatefulWidget {
  const _CommandIconButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.foreground,
    this.anchorKey,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? foreground;
  final GlobalKey? anchorKey;

  @override
  State<_CommandIconButton> createState() => _CommandIconButtonState();
}

class _CommandIconButtonState extends State<_CommandIconButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = widget.foreground ?? theme.colorScheme.onSurface;
    final bg = _pressed
        ? fg.withValues(alpha: 0.12)
        : _hover
        ? fg.withValues(alpha: 0.08)
        : Colors.transparent;

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final anchor = widget.anchorKey;
    if (anchor != null) {
      child = KeyedSubtree(key: anchor, child: child);
    }
    return child;
  }
}

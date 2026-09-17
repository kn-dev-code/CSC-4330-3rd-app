import 'dart:async';

import 'package:flutter/material.dart';

class TopNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(milliseconds: 1900),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopNotificationCard(
        message: message,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (entry.mounted) entry.remove();
          if (identical(_currentEntry, entry)) _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _TopNotificationCard extends StatefulWidget {
  const _TopNotificationCard({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_TopNotificationCard> createState() => _TopNotificationCardState();
}

class _TopNotificationCardState extends State<_TopNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _expand;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _expand = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: widget.onAction == null,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SizeTransition(
              sizeFactor: _expand,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null &&
                            widget.onAction != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              widget.onAction!();
                              _dismiss();
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                            ),
                            child: Text(widget.actionLabel!),
                          ),
                        ],
                      ],
                    ),
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

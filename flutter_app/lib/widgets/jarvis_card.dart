import 'package:flutter/material.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

class JarvisCard extends StatefulWidget {
  const JarvisCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  State<JarvisCard> createState() => _JarvisCardState();
}

class _JarvisCardState extends State<JarvisCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = widget.padding ?? const EdgeInsets.all(16);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: JarvisTheme.animDuration,
        curve: JarvisTheme.animCurve,
        margin: const EdgeInsets.only(bottom: 12),
        transform: _hovered
            ? Matrix4.translationValues(0.0, -2.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _hovered
              ? theme.cardColor.withValues(alpha: 0.85)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ),
              ),
            Padding(
              padding: effectivePadding,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

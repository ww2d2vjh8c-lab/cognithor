import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

/// A glassmorphism card with frosted blur, gradient highlight, and smooth
/// border radius.  Falls back to a regular semi-transparent card on platforms
/// that do not support [BackdropFilter] (e.g. HTML renderer on web).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = JarvisTheme.cardRadius,
    this.blur = 10.0,
    this.opacity,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double borderRadius;
  final double blur;

  /// Background opacity override.  When `null` the widget picks a sensible
  /// default for dark / light mode.
  final double? opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Backdrop filters are not supported on the web HTML renderer and can cause
  /// issues on some older desktop embedders.
  static bool get _supportsBlur => !kIsWeb;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = opacity ?? (isDark ? 0.35 : 0.55);

    final bgColor = isDark
        ? JarvisTheme.surface.withValues(alpha: bgOpacity)
        : Colors.white.withValues(alpha: bgOpacity);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.45);

    final highlightGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: isDark ? 0.07 : 0.25),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: 1),
    );

    Widget content = Container(
      decoration: ShapeDecoration(
        shape: shape,
        color: bgColor,
        gradient: highlightGradient,
      ),
      padding: padding ?? const EdgeInsets.all(JarvisTheme.spacing),
      child: child,
    );

    if (_supportsBlur && blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

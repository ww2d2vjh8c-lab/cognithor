import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

/// A subtle animated gradient background placed behind [child].
///
/// In dark mode two radial accent-colored glows rotate slowly (60 s full
/// rotation) at very low opacity. In light mode a faint blue tint is used
/// instead.
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient layer
            CustomPaint(
              painter: _GradientPainter(
                angle: _controller.value * 2 * math.pi,
                isDark: isDark,
              ),
            ),
            // Main content
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _GradientPainter extends CustomPainter {
  _GradientPainter({
    required this.angle,
    required this.isDark,
  });

  final double angle;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDark(canvas, size);
    } else {
      _paintLight(canvas, size);
    }
  }

  void _paintDark(Canvas canvas, Size size) {
    final accentColor = JarvisTheme.accent;

    // Top-right glow — slowly orbits.
    final center1 = Offset(
      size.width * 0.75 + math.cos(angle) * size.width * 0.1,
      size.height * 0.2 + math.sin(angle) * size.height * 0.05,
    );
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.05),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center1, radius: size.width * 0.6),
      );
    canvas.drawRect(Offset.zero & size, paint1);

    // Bottom-left glow — counter-orbits.
    final center2 = Offset(
      size.width * 0.25 + math.cos(angle + math.pi) * size.width * 0.1,
      size.height * 0.8 + math.sin(angle + math.pi) * size.height * 0.05,
    );
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.03),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center2, radius: size.width * 0.5),
      );
    canvas.drawRect(Offset.zero & size, paint2);
  }

  void _paintLight(Canvas canvas, Size size) {
    // Very subtle blue tint that drifts.
    const blue = Color(0xFF448AFF);
    final center = Offset(
      size.width * 0.5 + math.cos(angle) * size.width * 0.15,
      size.height * 0.3 + math.sin(angle) * size.height * 0.08,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          blue.withValues(alpha: 0.04),
          blue.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.7),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GradientPainter oldDelegate) =>
      angle != oldDelegate.angle || isDark != oldDelegate.isDark;
}

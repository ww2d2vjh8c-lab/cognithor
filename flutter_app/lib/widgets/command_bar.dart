import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/providers/navigation_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/glass_panel.dart';

class CommandBar extends StatelessWidget {
  const CommandBar({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return SizedBox(
      height: 40,
      child: GlassPanel(
        tint: nav.sectionColor,
        borderRadius: 0,
        blur: 10,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left: Section icon + name
            Icon(Icons.circle, size: 8, color: nav.sectionColor),
            const SizedBox(width: 8),
            Text(
              nav.sectionName,
              style: TextStyle(
                color: nav.sectionColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            // Center: Search hint
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search,
                        size: 14, color: JarvisTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text('Search...',
                        style: TextStyle(
                            color: JarvisTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text('Ctrl+K',
                        style: TextStyle(
                            color: JarvisTheme.textTertiary,
                            fontSize: 10,
                            fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Right: Status + model
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: JarvisTheme.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: JarvisTheme.green.withValues(alpha: 0.4),
                      blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('Running',
                style: TextStyle(
                    color: JarvisTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

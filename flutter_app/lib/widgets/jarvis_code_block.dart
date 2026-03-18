import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

class JarvisCodeBlock extends StatelessWidget {
  const JarvisCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.maxLines,
  });

  final String code;
  final String? language;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
        border: Border.all(color: JarvisTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: JarvisTheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(JarvisTheme.cardRadius),
              ),
            ),
            child: Row(
              children: [
                if (language != null)
                  Text(
                    language!,
                    style: TextStyle(
                      color: JarvisTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: JarvisTheme.iconSizeSm,
                    color: JarvisTheme.textSecondary,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          // Code body
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              maxLines: maxLines,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

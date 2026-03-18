import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jarvis_ui/providers/chat_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  final MessageRole role;
  final String text;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;
    final isSystem = role == MessageRole.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? JarvisTheme.accent.withAlpha(30)
              : isSystem
                  ? JarvisTheme.red.withAlpha(25)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? JarvisTheme.accent.withAlpha(64)
                : isSystem
                    ? JarvisTheme.red.withAlpha(64)
                    : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: _buildContent(context, isUser, isSystem)),
            if (isStreaming) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: JarvisTheme.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser, bool isSystem) {
    // User and system messages: plain text
    if (isUser || isSystem) {
      return SelectableText(
        text,
        style: TextStyle(
          color: isSystem
              ? JarvisTheme.red
              : Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }

    // Assistant messages: Markdown rendering
    return MarkdownBody(
      data: text,
      selectable: true,
      shrinkWrap: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.5,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: JarvisTheme.accent,
          backgroundColor: const Color(0xFF1E1E2E),
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: JarvisTheme.border),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        h1: TextStyle(
          color: JarvisTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: JarvisTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: JarvisTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: JarvisTheme.accent, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(color: JarvisTheme.accent),
        a: TextStyle(color: JarvisTheme.accent),
        strong: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontStyle: FontStyle.italic,
        ),
        tableHead: TextStyle(
          color: JarvisTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        tableBorder: TableBorder.all(color: JarvisTheme.border),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
      ),
    );
  }
}

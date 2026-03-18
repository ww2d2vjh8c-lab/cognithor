import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        decoration: _bubbleDecoration(context, isUser, isSystem),
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

  BoxDecoration _bubbleDecoration(
      BuildContext context, bool isUser, bool isSystem) {
    if (isUser) {
      // User: subtle accent gradient
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JarvisTheme.accent.withAlpha(35),
            JarvisTheme.accentDim.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
        border: Border.all(color: JarvisTheme.accent.withAlpha(60)),
      );
    }
    if (isSystem) {
      return BoxDecoration(
        color: JarvisTheme.red.withAlpha(20),
        borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
        border: Border.all(color: JarvisTheme.red.withAlpha(60)),
      );
    }
    // Assistant: clean surface with left accent border
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
      border: Border(
        left: BorderSide(
          color: JarvisTheme.accent.withAlpha(120),
          width: 3,
        ),
        top: BorderSide(color: Theme.of(context).dividerColor),
        right: BorderSide(color: Theme.of(context).dividerColor),
        bottom: BorderSide(color: Theme.of(context).dividerColor),
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
          backgroundColor: JarvisTheme.codeBlockBg,
        ),
        codeblockDecoration: BoxDecoration(
          color: JarvisTheme.codeBlockBg,
          borderRadius: BorderRadius.circular(JarvisTheme.spacingSm),
          border: Border.all(color: JarvisTheme.codeBlockBorder),
        ),
        codeblockPadding: const EdgeInsets.all(14),
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
        tableBorder: TableBorder.all(color: Theme.of(context).dividerColor),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
      ),
    );
  }
}

/// Standalone code block widget with a copy button.
/// Can be used outside of Markdown for displaying code snippets.
class CodeBlockWithCopy extends StatefulWidget {
  const CodeBlockWithCopy({super.key, required this.code, this.language});

  final String code;
  final String? language;

  @override
  State<CodeBlockWithCopy> createState() => _CodeBlockWithCopyState();
}

class _CodeBlockWithCopyState extends State<CodeBlockWithCopy> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: JarvisTheme.codeBlockBg,
        borderRadius: BorderRadius.circular(JarvisTheme.spacingSm),
        border: Border.all(color: JarvisTheme.codeBlockBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with optional language label and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withAlpha(80),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(JarvisTheme.spacingSm),
              ),
            ),
            child: Row(
              children: [
                if (widget.language != null)
                  Text(
                    widget.language!,
                    style: TextStyle(
                      fontSize: 11,
                      color: JarvisTheme.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy,
                          size: 14,
                          color: _copied
                              ? JarvisTheme.green
                              : JarvisTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            color: _copied
                                ? JarvisTheme.green
                                : JarvisTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: JarvisTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

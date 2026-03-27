import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/models/chat_node.dart';
import 'package:jarvis_ui/providers/tree_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

/// Collapsible sidebar showing the full conversation tree.
class TreeSidebar extends StatelessWidget {
  const TreeSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TreeProvider>(
      builder: (context, tree, _) {
        if (!tree.hasTree) {
          return const SizedBox(
            width: 200,
            child: Center(
              child: Text('No conversation', style: TextStyle(fontSize: 12)),
            ),
          );
        }

        // Find root nodes (no parent)
        final roots = tree.nodes.values
            .where((n) => n.parentId == null)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return Container(
          width: 220,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: JarvisTheme.border, width: 1),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.account_tree, size: 16, color: JarvisTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Conversation Tree',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: JarvisTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              for (final root in roots) _buildNode(context, tree, root, 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNode(BuildContext context, TreeProvider tree, ChatNode node, int depth) {
    final isActive = tree.activePath.contains(node.id);
    final isFork = tree.isForkPoint(node.id);
    final children = tree.nodes.values
        .where((n) => n.parentId == node.id)
        .toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            // Navigate to this node's branch
            if (node.parentId != null) {
              tree.switchBranch(node.parentId!, node.branchIndex);
            }
          },
          child: Container(
            margin: EdgeInsets.only(left: depth * 12.0, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? JarvisTheme.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  node.isUser ? Icons.person : Icons.smart_toy,
                  size: 12,
                  color: isActive ? JarvisTheme.accent : JarvisTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    node.text.length > 30 ? '${node.text.substring(0, 30)}...' : node.text,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? JarvisTheme.textPrimary : JarvisTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFork)
                  Icon(Icons.call_split, size: 12, color: JarvisTheme.orange),
              ],
            ),
          ),
        ),
        for (final child in children) _buildNode(context, tree, child, depth + 1),
      ],
    );
  }
}

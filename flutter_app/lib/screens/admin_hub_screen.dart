import 'package:flutter/material.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

import 'package:jarvis_ui/screens/agents_screen.dart';
import 'package:jarvis_ui/screens/config_screen.dart';
import 'package:jarvis_ui/screens/memory_screen.dart';
import 'package:jarvis_ui/screens/models_screen.dart';
import 'package:jarvis_ui/screens/security_screen.dart';
import 'package:jarvis_ui/screens/system_screen.dart';
import 'package:jarvis_ui/screens/credentials_screen.dart';
import 'package:jarvis_ui/screens/knowledge_graph_screen.dart';
import 'package:jarvis_ui/screens/vault_screen.dart';
import 'package:jarvis_ui/screens/learning_screen.dart';
import 'package:jarvis_ui/screens/workflows_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final tiles = <_AdminTile>[
      _AdminTile(
        icon: Icons.tune,
        title: l.config,
        subtitle: l.adminConfigSubtitle,
        builder: (_) => const ConfigScreen(),
      ),
      _AdminTile(
        icon: Icons.smart_toy,
        title: l.agentsTitle,
        subtitle: l.adminAgentsSubtitle,
        builder: (_) => const AgentsScreen(),
      ),
      _AdminTile(
        icon: Icons.model_training,
        title: l.modelsTitle,
        subtitle: l.adminModelsSubtitle,
        builder: (_) => const ModelsScreen(),
      ),
      _AdminTile(
        icon: Icons.shield,
        title: l.securityTitle,
        subtitle: l.adminSecuritySubtitle,
        builder: (_) => const SecurityScreen(),
      ),
      _AdminTile(
        icon: Icons.account_tree,
        title: l.workflowsTitle,
        subtitle: l.adminWorkflowsSubtitle,
        builder: (_) => const WorkflowsScreen(),
      ),
      _AdminTile(
        icon: Icons.hub,
        title: l.memoryTitle,
        subtitle: l.adminMemorySubtitle,
        builder: (_) => const MemoryScreen(),
      ),
      _AdminTile(
        icon: Icons.lock,
        title: l.vaultTitle,
        subtitle: l.adminVaultSubtitle,
        builder: (_) => const VaultScreen(),
      ),
      _AdminTile(
        icon: Icons.dns,
        title: l.systemTitle,
        subtitle: l.adminSystemSubtitle,
        builder: (_) => const SystemScreen(),
      ),
      _AdminTile(
        icon: Icons.scatter_plot,
        title: l.knowledgeGraph,
        subtitle: 'Entity visualization',
        builder: (_) => const KnowledgeGraphScreen(),
      ),
      _AdminTile(
        icon: Icons.vpn_key,
        title: l.credentialsTitle,
        subtitle: 'Manage secrets',
        builder: (_) => const CredentialsScreen(),
      ),
      _AdminTile(
        icon: Icons.school,
        title: l.learningTitle,
        subtitle: l.adminLearningSubtitle,
        builder: (_) => const LearningScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminTitle),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(JarvisTheme.spacing),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: JarvisTheme.spacingSm,
          mainAxisSpacing: JarvisTheme.spacingSm,
          childAspectRatio: 1.0,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return _AdminGridTile(tile: tile);
        },
      ),
    );
  }
}

class _AdminTile {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

class _AdminGridTile extends StatefulWidget {
  const _AdminGridTile({required this.tile});

  final _AdminTile tile;

  @override
  State<_AdminGridTile> createState() => _AdminGridTileState();
}

class _AdminGridTileState extends State<_AdminGridTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = widget.tile;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: tile.builder),
          );
        },
        child: AnimatedContainer(
          duration: JarvisTheme.animDuration,
          curve: JarvisTheme.animCurve,
          transform: _hovered
              ? Matrix4.diagonal3Values(1.03, 1.03, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? JarvisTheme.surfaceHover : theme.cardColor,
            borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
            border: Border.all(
              color: _hovered ? JarvisTheme.accent.withAlpha(100) : theme.dividerColor,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: JarvisTheme.accent.withAlpha(30),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(JarvisTheme.spacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon in a rounded, gradient-tinted container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      JarvisTheme.accent.withAlpha(25),
                      JarvisTheme.accent.withAlpha(8),
                    ],
                  ),
                  border: Border.all(
                    color: JarvisTheme.accent.withAlpha(40),
                  ),
                ),
                child: Icon(
                  tile.icon,
                  size: JarvisTheme.iconSizeLg,
                  color: JarvisTheme.accent,
                ),
              ),
              const SizedBox(height: JarvisTheme.spacingSm + 4),
              Text(
                tile.title,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tile.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/jarvis_card.dart';

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

class _AdminGridTile extends StatelessWidget {
  const _AdminGridTile({required this.tile});

  final _AdminTile tile;

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      padding: const EdgeInsets.all(JarvisTheme.spacing),
      child: InkWell(
        borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: tile.builder),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tile.icon,
              size: JarvisTheme.iconSizeXl,
              color: JarvisTheme.accent,
            ),
            const SizedBox(height: JarvisTheme.spacingSm),
            Text(
              tile.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tile.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

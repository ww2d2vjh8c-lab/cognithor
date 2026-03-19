import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:jarvis_ui/providers/config_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/form/form_widgets.dart';

class AgentsConfigPage extends StatelessWidget {
  const AgentsConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, cfg, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(AppLocalizations.of(context).agentsTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: JarvisTheme.accent),
                  onPressed: () => cfg.addAgent({
                    'name': 'new-agent',
                    'system_prompt': '',
                    'model': '',
                    'temperature': 0.7,
                    'tools': <String>[],
                    'trigger_patterns': <String>[],
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(cfg.agents.length, (i) {
              final agent = cfg.agents[i];
              // Collect configured model names for suggestions
              final models = cfg.cfg['models'] as Map<String, dynamic>? ?? {};
              final modelNames = <String>[];
              for (final role in models.values) {
                if (role is Map<String, dynamic>) {
                  final name = (role['name'] ?? '').toString();
                  if (name.isNotEmpty && !modelNames.contains(name)) {
                    modelNames.add(name);
                  }
                }
              }
              final currentModel = (agent['model'] ?? '').toString();
              return JarvisCollapsibleCard(
                title: (agent['name'] ?? 'Agent $i').toString(),
                icon: Icons.smart_toy,
                children: [
                  JarvisTextField(
                    label: 'Name',
                    value: (agent['name'] ?? '').toString(),
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'name': v}),
                  ),
                  JarvisTextAreaField(
                    label: 'System Prompt',
                    value: (agent['system_prompt'] ?? '').toString(),
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'system_prompt': v}),
                    rows: 4,
                  ),
                  if (modelNames.isNotEmpty)
                    JarvisSelectField.fromStrings(
                      label: 'Model',
                      value: modelNames.contains(currentModel)
                          ? currentModel
                          : (modelNames.isNotEmpty ? modelNames.first : ''),
                      options: modelNames,
                      onChanged: (v) =>
                          cfg.updateAgent(i, {...agent, 'model': v}),
                      description: 'Select from configured models, or type a custom name below',
                    ),
                  JarvisTextField(
                    label: modelNames.isNotEmpty ? 'Custom Model' : 'Model',
                    value: currentModel,
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'model': v}),
                    placeholder: 'e.g. qwen3:8b',
                  ),
                  JarvisSliderField(
                    label: 'Temperature',
                    value:
                        (agent['temperature'] as num?)?.toDouble() ?? 0.7,
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'temperature': v}),
                    max: 2.0,
                    step: 0.05,
                  ),
                  JarvisListField(
                    label: 'Tools',
                    value: _toStringList(agent['tools']),
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'tools': v}),
                    placeholder: 'tool_name',
                  ),
                  JarvisListField(
                    label: 'Trigger Patterns',
                    value: _toStringList(agent['trigger_patterns']),
                    onChanged: (v) =>
                        cfg.updateAgent(i, {...agent, 'trigger_patterns': v}),
                    placeholder: 'regex pattern',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => cfg.removeAgent(i),
                      icon: Icon(Icons.delete,
                          size: 16, color: JarvisTheme.red),
                      label: Text(AppLocalizations.of(context).remove,
                          style: TextStyle(color: JarvisTheme.red)),
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}

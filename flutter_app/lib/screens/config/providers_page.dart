import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/providers/config_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/form/form_widgets.dart';

class ProvidersPage extends StatelessWidget {
  const ProvidersPage({super.key});

  static const _providers = [
    ('ollama', 'Ollama', Icons.computer),
    ('openai', 'OpenAI', Icons.auto_awesome),
    ('anthropic', 'Anthropic', Icons.psychology),
    ('gemini', 'Google Gemini', Icons.diamond),
    ('groq', 'Groq', Icons.speed),
    ('deepseek', 'DeepSeek', Icons.search),
    ('mistral', 'Mistral', Icons.air),
    ('together', 'Together AI', Icons.group),
    ('openrouter', 'OpenRouter', Icons.router),
    ('xai', 'xAI', Icons.smart_toy),
    ('cerebras', 'Cerebras', Icons.memory),
    ('github', 'GitHub Models', Icons.code),
    ('bedrock', 'AWS Bedrock', Icons.cloud),
    ('huggingface', 'Hugging Face', Icons.face),
    ('moonshot', 'Moonshot', Icons.nightlight),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, cfg, _) {
        final currentBackend =
            (cfg.cfg['llm_backend_type'] ?? 'ollama').toString();

        // Sort: active provider first, rest in original order.
        final sorted = List<(String, String, IconData)>.from(_providers)
          ..sort((a, b) {
            if (a.$1 == currentBackend && b.$1 != currentBackend) return -1;
            if (b.$1 == currentBackend && a.$1 != currentBackend) return 1;
            return 0;
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Prominent backend selector ---
            _BackendSelector(
              currentBackend: currentBackend,
              onChanged: (v) => cfg.set('llm_backend_type', v),
            ),
            const SizedBox(height: 16),
            // --- Provider cards (active first) ---
            ...sorted.map(
              (p) => _ProviderCard(
                cfg: cfg,
                provider: p,
                isActive: p.$1 == currentBackend,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Prominent backend selector widget
// ---------------------------------------------------------------------------
class _BackendSelector extends StatelessWidget {
  const _BackendSelector({
    required this.currentBackend,
    required this.onChanged,
  });

  final String currentBackend;
  final ValueChanged<String> onChanged;

  String _labelFor(String key) {
    for (final p in ProvidersPage._providers) {
      if (p.$1 == key) return p.$2;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JarvisTheme.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(JarvisTheme.cardRadius),
        border: Border.all(color: JarvisTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub, color: JarvisTheme.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'LLM Backend',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which LLM provider Jarvis uses for all AI requests. '
            'The active provider\'s card is expanded below so you can '
            'configure its connection settings.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: JarvisTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          JarvisSelectField.fromStrings(
            label: 'Active Provider',
            value: currentBackend,
            options:
                ProvidersPage._providers.map((p) => p.$1).toList(),
            onChanged: onChanged,
            description: 'Currently using: ${_labelFor(currentBackend)}',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual provider card — active is expanded + highlighted, others dimmed
// ---------------------------------------------------------------------------
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.cfg,
    required this.provider,
    required this.isActive,
  });

  final ConfigProvider cfg;
  final (String, String, IconData) provider;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final (key, label, icon) = provider;

    final children = _fieldsFor(key);

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: JarvisCollapsibleCard(
        title: label,
        icon: icon,
        badge: isActive ? 'ACTIVE PROVIDER' : null,
        initiallyExpanded: isActive,
        forceOpen: isActive,
        children: children,
      ),
    );
  }

  List<Widget> _fieldsFor(String key) {
    if (key == 'ollama') {
      final ollama = cfg.cfg['ollama'] as Map<String, dynamic>? ?? {};
      return [
        JarvisTextField(
          label: 'Base URL',
          value:
              (ollama['base_url'] ?? 'http://localhost:11434').toString(),
          onChanged: (v) => cfg.set('ollama.base_url', v),
        ),
        JarvisNumberField(
          label: 'Timeout (seconds)',
          value: (ollama['timeout_seconds'] as num?) ?? 120,
          onChanged: (v) => cfg.set('ollama.timeout_seconds', v),
          min: 10,
        ),
        JarvisTextField(
          label: 'Keep Alive',
          value: (ollama['keep_alive'] ?? '5m').toString(),
          onChanged: (v) => cfg.set('ollama.keep_alive', v),
        ),
      ];
    }

    final apiKey = '${key}_api_key';
    final baseUrl = '${key}_base_url';

    return [
      JarvisTextField(
        label: 'API Key',
        value: (cfg.cfg[apiKey] ?? '').toString(),
        onChanged: (v) => cfg.set(apiKey, v),
        isPassword: true,
        isSecret: true,
      ),
      if (key == 'openai')
        JarvisTextField(
          label: 'Base URL (optional)',
          value: (cfg.cfg[baseUrl] ?? '').toString(),
          onChanged: (v) => cfg.set(baseUrl, v),
          placeholder: 'https://api.openai.com/v1',
        ),
      if (key == 'anthropic')
        JarvisNumberField(
          label: 'Max Tokens',
          value: (cfg.cfg['anthropic_max_tokens'] as num?) ?? 4096,
          onChanged: (v) => cfg.set('anthropic_max_tokens', v),
          min: 256,
        ),
    ];
  }
}

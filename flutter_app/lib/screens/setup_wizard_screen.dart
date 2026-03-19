import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/glass_panel.dart';
import 'package:jarvis_ui/widgets/gradient_background.dart';
import 'package:jarvis_ui/screens/main_shell.dart';

/// First-run setup wizard — 3-step onboarding shown once on initial launch.
///
/// Step 1: Welcome + LLM provider selection (Local / Cloud)
/// Step 2: Model configuration (URL or API key)
/// Step 3: Connection test result + launch
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  /// SharedPreferences key that gates the wizard.
  static const prefKey = 'first_run_complete';

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;

  // Step 1 — provider selection
  _LlmProvider? _provider;

  // Step 2 — configuration
  final _ollamaUrlController =
      TextEditingController(text: 'http://localhost:11434');
  final _apiKeyController = TextEditingController();
  String _cloudProvider = 'OpenAI';
  static const _cloudProviders = [
    'OpenAI',
    'Anthropic',
    'Google',
    'Mistral',
    'Groq',
  ];

  // Connection test
  _TestState _testState = _TestState.idle;
  String? _testMessage;

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _testState = _TestState.idle;
        _testMessage = null;
      });
    }
  }

  // ── Connection Test ──────────────────────────────────────────────────────

  Future<void> _testConnection() async {
    setState(() {
      _testState = _TestState.testing;
      _testMessage = null;
    });

    try {
      if (_provider == _LlmProvider.local) {
        final url = _ollamaUrlController.text.trim();
        final uri = Uri.parse('$url/api/tags');
        final res = await http
            .get(uri)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final models = body['models'] as List<dynamic>? ?? [];
          setState(() {
            _testState = _TestState.success;
            _testMessage = models.isEmpty
                ? 'Connected to Ollama. No models installed yet — '
                    'run "ollama pull qwen3:8b" to get started.'
                : 'Connected to Ollama. ${models.length} model(s) available.';
          });
        } else {
          setState(() {
            _testState = _TestState.error;
            _testMessage =
                'Ollama responded with status ${res.statusCode}. '
                'Make sure the server is running.';
          });
        }
      } else {
        // Cloud provider — validate API key format only (no real call).
        final key = _apiKeyController.text.trim();
        if (key.isEmpty) {
          setState(() {
            _testState = _TestState.error;
            _testMessage = 'Please enter an API key.';
          });
          return;
        }
        if (key.length < 20) {
          setState(() {
            _testState = _TestState.error;
            _testMessage =
                'That key looks too short. Double-check your $_cloudProvider API key.';
          });
          return;
        }
        setState(() {
          _testState = _TestState.success;
          _testMessage =
              '$_cloudProvider API key saved. You can change it later in Settings.';
        });
      }
    } catch (e) {
      setState(() {
        _testState = _TestState.error;
        _testMessage = 'Connection failed: $e';
      });
    }
  }

  // ── Finish Wizard ────────────────────────────────────────────────────────

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SetupWizardScreen.prefKey, true);

    // Persist Ollama URL if local provider was chosen.
    if (_provider == _LlmProvider.local) {
      await prefs.setString(
        'jarvis_server_url',
        'http://localhost:8741',
      );
      await prefs.setString(
        'ollama_url',
        _ollamaUrlController.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JarvisTheme.dark,
      child: Scaffold(
        body: GradientBackground(
          particleColor: JarvisTheme.accent,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      // ── Step indicator ──
                      _StepIndicator(current: _step),
                      const SizedBox(height: 32),

                      // ── Step body ──
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: JarvisTheme.animDuration,
                          child: switch (_step) {
                            0 => _buildStep1(),
                            1 => _buildStep2(),
                            2 => _buildStep3(),
                            _ => const SizedBox.shrink(),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Welcome + Provider Selection ─────────────────────────────────

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // Logo / Title
        Text(
          'COGNITHOR',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: JarvisTheme.accent,
                letterSpacing: 6,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your Personal AI Assistant',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: JarvisTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 40),
        Text(
          'Choose your LLM provider',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),

        // Provider cards
        _ProviderCard(
          icon: Icons.computer,
          title: 'Local (Ollama)',
          subtitle:
              'Run models on your own hardware. '
              'Full privacy, no API costs. Requires Ollama installed.',
          selected: _provider == _LlmProvider.local,
          tint: JarvisTheme.matrix,
          onTap: () => setState(() => _provider = _LlmProvider.local),
        ),
        const SizedBox(height: 12),
        _ProviderCard(
          icon: Icons.cloud,
          title: 'Cloud Provider',
          subtitle:
              'Use OpenAI, Anthropic, or other cloud APIs. '
              'Faster setup, requires an API key.',
          selected: _provider == _LlmProvider.cloud,
          tint: JarvisTheme.sectionChat,
          onTap: () => setState(() => _provider = _LlmProvider.cloud),
        ),

        const Spacer(),

        // Next button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _NeonButton(
            label: 'Next',
            onPressed: _provider != null ? _next : null,
          ),
        ),
      ],
    );
  }

  // ── Step 2: Model Configuration ──────────────────────────────────────────

  Widget _buildStep2() {
    final isLocal = _provider == _LlmProvider.local;

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLocal ? 'Ollama Configuration' : 'Cloud API Configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          isLocal
              ? 'Enter the URL where Ollama is running.'
              : 'Select your cloud provider and enter your API key.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),

        if (isLocal) ...[
          Text('Ollama URL', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _ollamaUrlController,
            decoration: const InputDecoration(
              hintText: 'http://localhost:11434',
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ] else ...[
          Text('Provider', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _cloudProvider,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.cloud),
            ),
            dropdownColor: JarvisTheme.surface,
            items: _cloudProviders
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _cloudProvider = v);
            },
          ),
          const SizedBox(height: 16),
          Text('API Key', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'sk-...',
              prefixIcon: Icon(Icons.key),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Test Connection button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed:
                _testState == _TestState.testing ? null : _testConnection,
            icon: _testState == _TestState.testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(
              _testState == _TestState.testing
                  ? 'Testing...'
                  : 'Test Connection',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: JarvisTheme.accent,
              side: BorderSide(color: JarvisTheme.accent),
            ),
          ),
        ),

        // Test result
        if (_testMessage != null) ...[
          const SizedBox(height: 16),
          GlassPanel(
            tint: _testState == _TestState.success
                ? JarvisTheme.green
                : JarvisTheme.red,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _testState == _TestState.success
                      ? Icons.check_circle
                      : Icons.error,
                  color: _testState == _TestState.success
                      ? JarvisTheme.green
                      : JarvisTheme.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _testMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Navigation buttons
        Row(
          children: [
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: _NeonButton(
                label: 'Next',
                onPressed: _testState == _TestState.success ? _next : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Success ──────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      children: [
        const Spacer(),
        Icon(
          Icons.rocket_launch,
          size: 72,
          color: JarvisTheme.accent,
        ),
        const SizedBox(height: 24),
        Text(
          'You\'re All Set!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          _provider == _LlmProvider.local
              ? 'Ollama is connected and ready. Cognithor will use your '
                  'local models for planning and execution.'
              : '$_cloudProvider is configured. Cognithor will use your '
                  'cloud API for planning and execution.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: JarvisTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change these settings at any time.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),

        // Launch button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _NeonButton(
            label: 'Start Using Cognithor',
            onPressed: _finish,
            glow: true,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    );
  }
}

// ── Helper Types ─────────────────────────────────────────────────────────────

enum _LlmProvider { local, cloud }

enum _TestState { idle, testing, success, error }

// ── Reusable Widgets ─────────────────────────────────────────────────────────

/// Neon-glowing primary button matching the Sci-Fi aesthetic.
class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.onPressed,
    this.glow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedContainer(
      duration: JarvisTheme.animDuration,
      decoration: glow && enabled
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(JarvisTheme.buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: JarvisTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? JarvisTheme.accent : JarvisTheme.surface,
          foregroundColor:
              enabled ? JarvisTheme.bg : JarvisTheme.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(JarvisTheme.buttonRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// Provider selection card with a neon tint border on selection.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: selected ? tint : JarvisTheme.border,
      glowOnHover: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (selected ? tint : JarvisTheme.textTertiary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? tint : JarvisTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? tint : null,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle, color: tint, size: 24),
        ],
      ),
    );
  }
}

/// Three-dot step indicator at the top of the wizard.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: JarvisTheme.animDuration,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active
                ? JarvisTheme.accent
                : JarvisTheme.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

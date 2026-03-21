import 'package:flutter/material.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jarvis_ui/providers/admin_provider.dart';
import 'package:jarvis_ui/providers/chat_provider.dart';
import 'package:jarvis_ui/providers/connection_provider.dart'
    show ConnectionProvider, JarvisConnectionState;
import 'package:jarvis_ui/providers/memory_provider.dart';
import 'package:jarvis_ui/providers/security_provider.dart';
import 'package:jarvis_ui/providers/sessions_provider.dart';
import 'package:jarvis_ui/providers/skills_provider.dart';
import 'package:jarvis_ui/providers/workflow_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/screens/main_shell.dart';
import 'package:jarvis_ui/screens/settings_screen.dart';
import 'package:jarvis_ui/screens/setup_wizard_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final l = AppLocalizations.of(context);

    // Auto-navigate when connected — wire up all providers with the API first.
    if (conn.state == JarvisConnectionState.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final api = conn.api;
        context.read<AdminProvider>().setApi(api);
        context.read<SecurityProvider>().setApi(api);
        context.read<MemoryProvider>().setApi(api);
        context.read<SkillsProvider>().setApi(api);
        context.read<WorkflowProvider>().setApi(api);

        // Wire SessionsProvider with API
        final sessions = context.read<SessionsProvider>();
        sessions.setApi(api);

        // Attach ChatProvider to WebSocket and connect
        final chat = context.read<ChatProvider>();
        chat.attach(conn.ws);

        // Auto-session: resume recent or create new based on inactivity timeout
        final sessionId = await sessions.autoSessionOnStartup() ??
            'flutter_${DateTime.now().millisecondsSinceEpoch}';
        conn.ws.connect(sessionId);

        // Check if the first-run wizard has been completed.
        final prefs = await SharedPreferences.getInstance();
        final firstRunComplete =
            prefs.getBool(SetupWizardScreen.prefKey) ?? false;

        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => firstRunComplete
                ? const MainShell()
                : const SetupWizardScreen(),
          ),
        );
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / Title
              Text(
                l.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: JarvisTheme.accent,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 32),

              if (conn.state == JarvisConnectionState.connecting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l.connecting,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],

              if (conn.state == JarvisConnectionState.error) ...[
                Icon(Icons.cloud_off, size: 48, color: JarvisTheme.red),
                const SizedBox(height: 16),
                Text(l.connectionError,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: JarvisTheme.red)),
                const SizedBox(height: 8),
                Text(
                  l.connectionErrorDetail(conn.serverUrl),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: conn.connect,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.retry),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings),
                      label: Text(l.settings),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JarvisTheme.accent,
                        side: BorderSide(color: JarvisTheme.accent),
                      ),
                    ),
                  ],
                ),
              ],

              if (conn.state == JarvisConnectionState.disconnected) ...[
                Text(l.connecting,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

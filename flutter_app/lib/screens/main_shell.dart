import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:jarvis_ui/providers/theme_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/global_search_dialog.dart';

import 'package:jarvis_ui/screens/admin_hub_screen.dart';
import 'package:jarvis_ui/screens/chat_screen.dart';
import 'package:jarvis_ui/screens/config_screen.dart';
import 'package:jarvis_ui/screens/dashboard_screen.dart';
import 'package:jarvis_ui/screens/identity_screen.dart';
import 'package:jarvis_ui/screens/skills_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    DashboardScreen(),
    SkillsScreen(),
    AdminHubScreen(),
    IdentityScreen(),
  ];

  void _openSearch() {
    showDialog(
      context: context,
      builder: (_) => GlobalSearchDialog(
        onNavigate: (pageIndex) {
          // Navigate to config screen with the selected page
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConfigScreen(),
            ),
          );
        },
      ),
    );
  }

  String _titleForIndex(int index, AppLocalizations l) {
    return switch (index) {
      0 => l.chat,
      1 => l.dashboard,
      2 => l.skills,
      3 => l.adminTitle,
      4 => l.identity,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openSearch,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_titleForIndex(_currentIndex, l)),
            actions: [
              // Search (Ctrl+K)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search (Ctrl+K)',
                onPressed: _openSearch,
              ),
              // Theme toggle
              IconButton(
                icon: Icon(
                  themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeProvider.isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: () => themeProvider.toggle(),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Theme.of(context).cardColor,
            indicatorColor: JarvisTheme.accent.withValues(alpha: 0.15),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon:
                    Icon(Icons.chat_bubble, color: JarvisTheme.accent),
                label: l.chat,
              ),
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon:
                    Icon(Icons.dashboard, color: JarvisTheme.accent),
                label: l.dashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.extension_outlined),
                selectedIcon:
                    Icon(Icons.extension, color: JarvisTheme.accent),
                label: l.skills,
              ),
              NavigationDestination(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings,
                    color: JarvisTheme.accent),
                label: l.adminTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.psychology_outlined),
                selectedIcon:
                    Icon(Icons.psychology, color: JarvisTheme.accent),
                label: l.identity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

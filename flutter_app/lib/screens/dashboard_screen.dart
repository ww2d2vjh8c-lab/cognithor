import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:jarvis_ui/providers/connection_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/jarvis_card.dart';
import 'package:jarvis_ui/widgets/jarvis_empty_state.dart';
import 'package:jarvis_ui/widgets/jarvis_loading_skeleton.dart';
import 'package:jarvis_ui/widgets/jarvis_metric_card.dart';
import 'package:jarvis_ui/widgets/jarvis_progress_bar.dart';
import 'package:jarvis_ui/widgets/jarvis_section.dart';
import 'package:jarvis_ui/widgets/jarvis_stat.dart';
import 'package:jarvis_ui/widgets/jarvis_status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboard;
  List<dynamic>? _events;
  Map<String, dynamic>? _models;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<ConnectionProvider>().api;
      final results = await Future.wait([
        api.get('/monitoring/dashboard'),
        api.get('/monitoring/events?n=10'),
        api.get('/models/available'),
      ]);

      final dashboard = results[0];
      final eventsResult = results[1];
      final modelsResult = results[2];

      if (!mounted) return;

      if (dashboard.containsKey('error')) {
        setState(() {
          _error = dashboard['error'] as String;
          _loading = false;
        });
        return;
      }

      setState(() {
        _dashboard = dashboard;
        _events = eventsResult['events'] as List<dynamic>? ?? [];
        _models = modelsResult;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatUptime(dynamic raw) {
    if (raw == null) return '-';
    final seconds = raw is num ? raw.toInt() : int.tryParse(raw.toString());
    if (seconds == null) return raw.toString();

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    parts.add('${minutes}m');
    return parts.join(' ');
  }

  Color _severityColor(String severity) {
    return switch (severity.toUpperCase()) {
      'ERROR' || 'CRITICAL' => JarvisTheme.red,
      'WARNING' || 'WARN' => JarvisTheme.orange,
      'INFO' => JarvisTheme.accent,
      _ => JarvisTheme.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(JarvisTheme.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const JarvisLoadingSkeleton(height: 80, count: 2),
            const SizedBox(height: JarvisTheme.spacingLg),
            const JarvisLoadingSkeleton(height: 40, count: 3),
            const SizedBox(height: JarvisTheme.spacingLg),
            JarvisLoadingSkeleton(
              height: 60,
              count: 4,
              width: MediaQuery.of(context).size.width * 0.9,
            ),
          ],
        ),
      );
    }

    if (_error != null && _dashboard == null) {
      return JarvisEmptyState(
        icon: Icons.dashboard_outlined,
        title: l.noData,
        subtitle: _error,
        action: ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: Text(l.retry),
        ),
      );
    }

    final uptime = _dashboard!['uptime'];
    final activeSessions =
        _dashboard!['active_sessions']?.toString() ?? '0';
    final totalRequests =
        _dashboard!['total_requests']?.toString() ?? '0';
    final responseTime =
        _dashboard!['response_time_ms']?.toString() ?? '-';

    final cpuUsage = _dashboard!['cpu_usage']?.toString() ?? '-';
    final memoryUsage = _dashboard!['memory_usage']?.toString() ?? '-';
    final toolExecs =
        _dashboard!['tool_executions']?.toString() ?? '0';
    final successRateRaw = _dashboard!['success_rate'];
    final successRate = successRateRaw is num
        ? successRateRaw.toDouble()
        : double.tryParse(successRateRaw?.toString() ?? '') ?? 0.0;

    final conn = context.watch<ConnectionProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: JarvisTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(JarvisTheme.spacing),
        children: [
          // -- System Health section --
          JarvisSection(
            title: l.systemHealth,
            trailing: Text(
              l.dashboardRefreshing,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - JarvisTheme.spacingSm) / 2;
              return Wrap(
                spacing: JarvisTheme.spacingSm,
                runSpacing: JarvisTheme.spacingSm,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: JarvisMetricCard(
                      title: l.uptime,
                      value: _formatUptime(uptime),
                      icon: Icons.timer,
                      color: JarvisTheme.green,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: JarvisMetricCard(
                      title: l.activeSessions,
                      value: activeSessions,
                      icon: Icons.people,
                      color: JarvisTheme.accent,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: JarvisMetricCard(
                      title: l.totalRequests,
                      value: totalRequests,
                      icon: Icons.trending_up,
                      color: JarvisTheme.orange,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: JarvisMetricCard(
                      title: l.responseTime,
                      value: '${responseTime}ms',
                      icon: Icons.speed,
                      color: JarvisTheme.info,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: JarvisTheme.spacingLg),

          // -- Performance section --
          JarvisSection(title: l.performance),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              JarvisStat(
                label: l.cpuUsage,
                value: '$cpuUsage%',
                icon: Icons.memory,
                color: JarvisTheme.accent,
              ),
              JarvisStat(
                label: l.memoryUsage,
                value: '$memoryUsage%',
                icon: Icons.storage,
                color: JarvisTheme.orange,
              ),
              JarvisStat(
                label: l.toolExecutions,
                value: toolExecs,
                icon: Icons.build,
                color: JarvisTheme.green,
              ),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacing),
          JarvisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.successRate,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${(successRate * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: JarvisTheme.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: JarvisTheme.spacingSm),
                JarvisProgressBar(
                  value: successRate,
                  color: JarvisTheme.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: JarvisTheme.spacingLg),

          // -- Recent Events section --
          JarvisSection(
            title: l.recentEvents,
            trailing: TextButton(
              onPressed: () {
                // TODO: Navigate to full events view
              },
              child: Text(l.viewAll),
            ),
          ),
          if (_events == null || _events!.isEmpty)
            JarvisCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(JarvisTheme.spacingLg),
                  child: Text(
                    l.noEvents,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            )
          else
            ..._events!.map<Widget>((event) {
              final e = event as Map<String, dynamic>;
              final severity = e['severity']?.toString() ?? 'INFO';
              final message = e['message']?.toString() ?? '';
              final timestamp = e['timestamp']?.toString() ?? '';

              return JarvisCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JarvisStatusBadge(
                      label: severity,
                      color: _severityColor(severity),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (timestamp.isNotEmpty)
                            Text(
                              timestamp,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: JarvisTheme.spacingLg),

          // -- System Status section --
          JarvisSection(title: l.systemStatus),
          JarvisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  context,
                  l.backendVersion,
                  (conn.backendVersion != null &&
                          conn.backendVersion!.isNotEmpty)
                      ? conn.backendVersion!
                      : 'Unknown',
                ),
                const Divider(height: 20),
                _infoRow(
                  context,
                  l.plannerModel,
                  _models?['planner']?.toString() ?? '-',
                ),
                const SizedBox(height: 4),
                _infoRow(
                  context,
                  l.executorModel,
                  _models?['executor']?.toString() ?? '-',
                ),
                const Divider(height: 20),
                _infoRow(
                  context,
                  l.uptime,
                  _formatUptime(uptime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

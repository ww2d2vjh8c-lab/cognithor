import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jarvis_ui/l10n/generated/app_localizations.dart';
import 'package:jarvis_ui/providers/connection_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';
import 'package:jarvis_ui/widgets/jarvis_card.dart';
import 'package:jarvis_ui/widgets/jarvis_empty_state.dart';
import 'package:jarvis_ui/widgets/jarvis_stat.dart';
import 'package:jarvis_ui/widgets/jarvis_status_badge.dart';
import 'package:jarvis_ui/widgets/jarvis_tab_bar.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _tabIndex = 0;

  // Overview data
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _confidenceHistory = [];

  // Knowledge gaps data
  List<Map<String, dynamic>> _gaps = [];

  // Exploration queue data
  List<Map<String, dynamic>> _queue = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ConnectionProvider>().api;
      final results = await Future.wait([
        api.getLearningStats(),
        api.getLearningGaps(),
        api.getConfidenceHistory(),
        api.getLearningQueue(),
      ]);

      if (!mounted) return;

      final statsResult = results[0];
      final gapsResult = results[1];
      final historyResult = results[2];
      final queueResult = results[3];

      setState(() {
        _stats = statsResult.containsKey('error') ? null : statsResult;
        _gaps = _parseList(gapsResult, 'gaps');
        _confidenceHistory = _parseList(historyResult, 'history');
        _queue = _parseList(queueResult, 'tasks');
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseList(
      Map<String, dynamic> data, String key) {
    return (data[key] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
  }

  Future<void> _dismissGap(String gapId) async {
    try {
      final api = context.read<ConnectionProvider>().api;
      await api.dismissGap(gapId);
      setState(() {
        _gaps.removeWhere((g) => g['id']?.toString() == gapId);
      });
    } catch (_) {}
  }

  Future<void> _exploreGap(String gapId) async {
    try {
      final api = context.read<ConnectionProvider>().api;
      await api.triggerExploration(gapId);
      await _loadAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.learningTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: l.refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: TextStyle(color: JarvisTheme.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAll,
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    JarvisTabBar(
                      tabs: [
                        l.dashboard,
                        l.knowledgeGaps,
                        l.explorationQueue,
                      ],
                      icons: const [
                        Icons.dashboard,
                        Icons.help_outline,
                        Icons.explore,
                      ],
                      selectedIndex: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                    Expanded(
                      child: switch (_tabIndex) {
                        0 => _buildOverview(l),
                        1 => _buildGaps(l),
                        2 => _buildQueue(l),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverview(AppLocalizations l) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(JarvisTheme.spacing),
      children: [
        // Stats row
        Wrap(
          spacing: JarvisTheme.spacingSm,
          runSpacing: JarvisTheme.spacingSm,
          children: [
            JarvisStat(
              label: l.filesProcessed,
              value: '${_stats?['files_processed'] ?? 0}',
              icon: Icons.insert_drive_file,
              color: JarvisTheme.accent,
            ),
            JarvisStat(
              label: l.entitiesCreated,
              value: '${_stats?['entities_created'] ?? 0}',
              icon: Icons.bubble_chart,
              color: JarvisTheme.green,
            ),
            JarvisStat(
              label: l.confidenceUpdates,
              value: '${_stats?['confidence_updates'] ?? 0}',
              icon: Icons.trending_up,
              color: JarvisTheme.orange,
            ),
            JarvisStat(
              label: l.openGaps,
              value: '${_stats?['open_gaps'] ?? _gaps.length}',
              icon: Icons.help_outline,
              color: JarvisTheme.red,
            ),
          ],
        ),
        const SizedBox(height: JarvisTheme.spacingLg),

        // Learning activity chart
        JarvisCard(
          title: l.learningTitle,
          icon: Icons.show_chart,
          child: SizedBox(
            height: 200,
            child: _buildActivityChart(theme),
          ),
        ),

        // Confidence history
        JarvisCard(
          title: l.confidenceHistory,
          icon: Icons.history,
          child: _confidenceHistory.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(JarvisTheme.spacing),
                  child: Text(l.noData,
                      style: theme.textTheme.bodySmall),
                )
              : Column(
                  children: _confidenceHistory.take(10).map((entry) {
                    final entity =
                        (entry['entity'] ?? entry['entity_id'] ?? '')
                            .toString();
                    final oldConf =
                        (entry['old_confidence'] ?? 0).toString();
                    final newConf =
                        (entry['new_confidence'] ?? 0).toString();
                    final increased = (entry['new_confidence'] ?? 0) >
                        (entry['old_confidence'] ?? 0);

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        increased
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: increased
                            ? JarvisTheme.green
                            : JarvisTheme.red,
                        size: 18,
                      ),
                      title: Text(entity,
                          style: theme.textTheme.bodyMedium),
                      subtitle: Text(
                        '$oldConf -> $newConf',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        (entry['timestamp'] ?? '').toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityChart(ThemeData theme) {
    // Build spots from stats or use placeholder structure
    final dataPoints =
        (_stats?['activity_chart'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noData,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < dataPoints.length; i++) {
      final y = (dataPoints[i]['count'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), y));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.dividerColor,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: JarvisTheme.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: JarvisTheme.accent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Knowledge Gaps
  // ---------------------------------------------------------------------------

  Widget _buildGaps(AppLocalizations l) {
    if (_gaps.isEmpty) {
      return JarvisEmptyState(
        icon: Icons.check_circle_outline,
        title: l.noGaps,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(JarvisTheme.spacing),
      itemCount: _gaps.length,
      itemBuilder: (context, index) {
        final gap = _gaps[index];
        return _GapCard(
          gap: gap,
          l: l,
          onDismiss: () =>
              _dismissGap((gap['id'] ?? '').toString()),
          onExplore: () =>
              _exploreGap((gap['id'] ?? '').toString()),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Exploration Queue
  // ---------------------------------------------------------------------------

  Widget _buildQueue(AppLocalizations l) {
    if (_queue.isEmpty) {
      return JarvisEmptyState(
        icon: Icons.explore_off,
        title: l.noTasks,
      );
    }

    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(JarvisTheme.spacing),
      itemCount: _queue.length,
      itemBuilder: (context, index) {
        final task = _queue[index];
        final query = (task['query'] ?? '').toString();
        final sources = (task['sources'] as List?)
                ?.map((s) => s.toString())
                .toList() ??
            [];
        final priority = (task['priority'] ?? 'normal').toString();
        final status = (task['status'] ?? 'pending').toString();

        final priorityColor = switch (priority) {
          'high' => JarvisTheme.red,
          'medium' => JarvisTheme.orange,
          _ => JarvisTheme.green,
        };

        final statusColor = switch (status) {
          'running' => JarvisTheme.accent,
          'completed' => JarvisTheme.green,
          'failed' => JarvisTheme.red,
          _ => JarvisTheme.textSecondary,
        };

        return JarvisCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      query,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  JarvisStatusBadge(
                    label: status,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  JarvisStatusBadge(
                    label: '${l.priority}: $priority',
                    color: priorityColor,
                    icon: Icons.flag,
                  ),
                  if (sources.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sources.join(', '),
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Gap card widget
// -----------------------------------------------------------------------------

class _GapCard extends StatelessWidget {
  const _GapCard({
    required this.gap,
    required this.l,
    required this.onDismiss,
    required this.onExplore,
  });

  final Map<String, dynamic> gap;
  final AppLocalizations l;
  final VoidCallback onDismiss;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final question = (gap['question'] ?? '').toString();
    final topic = (gap['topic'] ?? '').toString();
    final importance = ((gap['importance'] ?? 0) as num).toDouble();
    final curiosityScore = ((gap['curiosity_score'] ?? 0) as num).toDouble();
    final status = (gap['status'] ?? 'open').toString();

    final statusColor = switch (status) {
      'exploring' => JarvisTheme.accent,
      'resolved' => JarvisTheme.green,
      'dismissed' => JarvisTheme.textSecondary,
      _ => JarvisTheme.orange,
    };

    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              JarvisStatusBadge(label: status, color: statusColor),
            ],
          ),
          if (topic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(topic, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),

          // Importance bar
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(l.importance,
                    style: theme.textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: importance.clamp(0.0, 1.0),
                    backgroundColor: theme.dividerColor,
                    color: JarvisTheme.accent,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(importance * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Curiosity score bar
          Row(
            children: [
              SizedBox(
                width: 80,
                child:
                    Text(l.curiosity, style: theme.textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: curiosityScore.clamp(0.0, 1.0),
                    backgroundColor: theme.dividerColor,
                    color: JarvisTheme.orange,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(curiosityScore * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 16),
                label: Text(l.dismiss),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.explore, size: 16),
                label: Text(l.explore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

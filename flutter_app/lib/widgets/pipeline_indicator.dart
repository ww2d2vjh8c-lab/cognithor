import 'package:flutter/material.dart';
import 'package:jarvis_ui/providers/chat_provider.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

class PipelineIndicator extends StatelessWidget {
  const PipelineIndicator({super.key, required this.phases});

  final List<PipelinePhase> phases;

  static const _phaseOrder = ['plan', 'gate', 'execute', 'replan', 'complete'];

  Color _phaseColor(String status) => switch (status) {
        'start' => JarvisTheme.accent,
        'done' => JarvisTheme.green,
        'error' => JarvisTheme.red,
        _ => Colors.grey,
      };

  IconData _phaseIcon(String phase) => switch (phase) {
        'plan' => Icons.psychology,
        'gate' => Icons.shield,
        'execute' => Icons.build,
        'replan' => Icons.replay,
        'complete' => Icons.check_circle,
        _ => Icons.circle,
      };

  @override
  Widget build(BuildContext context) {
    final phaseMap = {for (final p in phases) p.phase: p};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final name in _phaseOrder)
            if (phaseMap.containsKey(name)) ...[
              _PhaseChip(
                phase: phaseMap[name]!,
                icon: _phaseIcon(name),
                color: _phaseColor(phaseMap[name]!.status),
              ),
              if (name != _phaseOrder.last &&
                  _phaseOrder.indexOf(name) <
                      _phaseOrder.indexOf(phaseMap.keys.last))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right,
                      size: 16, color: Theme.of(context).dividerColor),
                ),
            ],
        ],
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.phase,
    required this.icon,
    required this.color,
  });

  final PipelinePhase phase;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isActive = phase.status == 'start';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            phase.phase,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (phase.elapsedMs > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${phase.elapsedMs}ms',
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

enum DagNodeStatus { pending, running, complete, error }

class DagNode {
  DagNode({required this.id, required this.label, this.status = DagNodeStatus.pending});
  final String id;
  final String label;
  final DagNodeStatus status;
  double x = 0;
  double y = 0;
}

class DagEdge {
  const DagEdge({required this.from, required this.to});
  final String from;
  final String to;
}

class DagGraphPainter extends CustomPainter {
  DagGraphPainter({
    required this.nodes,
    required this.edges,
    this.brightness = Brightness.dark,
  });

  final List<DagNode> nodes;
  final List<DagEdge> edges;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // Topological layout: Kahn's algorithm for layer assignment
    final layers = _assignLayers();
    _positionNodes(layers, size);

    // Draw edges
    final nodeMap = {for (final n in nodes) n.id: n};
    final edgePaint = Paint()
      ..color = JarvisTheme.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = nodeMap[edge.from];
      final to = nodeMap[edge.to];
      if (from == null || to == null) continue;

      final path = Path()
        ..moveTo(from.x, from.y + 15)
        ..cubicTo(
          from.x, from.y + 30,
          to.x, to.y - 30,
          to.x, to.y - 15,
        );
      canvas.drawPath(path, edgePaint);

      // Arrow head
      _drawArrow(canvas, to.x, to.y - 15, edgePaint);
    }

    // Draw nodes
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  List<List<DagNode>> _assignLayers() {
    if (nodes.isEmpty) return [];

    final inDegree = <String, int>{};
    final adj = <String, List<String>>{};
    for (final n in nodes) {
      inDegree[n.id] = 0;
      adj[n.id] = [];
    }
    for (final e in edges) {
      adj[e.from]?.add(e.to);
      inDegree[e.to] = (inDegree[e.to] ?? 0) + 1;
    }

    final queue = <String>[
      for (final n in nodes)
        if (inDegree[n.id] == 0) n.id
    ];
    final layers = <List<DagNode>>[];
    final nodeMap = {for (final n in nodes) n.id: n};

    while (queue.isNotEmpty) {
      final layer = <DagNode>[];
      final nextQueue = <String>[];
      for (final id in queue) {
        layer.add(nodeMap[id]!);
        for (final child in adj[id]!) {
          inDegree[child] = (inDegree[child] ?? 1) - 1;
          if (inDegree[child] == 0) nextQueue.add(child);
        }
      }
      layers.add(layer);
      queue
        ..clear()
        ..addAll(nextQueue);
    }

    return layers;
  }

  void _positionNodes(List<List<DagNode>> layers, Size size) {
    if (layers.isEmpty) return;
    final layerHeight = size.height / (layers.length + 1);

    for (var l = 0; l < layers.length; l++) {
      final layer = layers[l];
      final nodeWidth = size.width / (layer.length + 1);
      for (var n = 0; n < layer.length; n++) {
        layer[n].x = nodeWidth * (n + 1);
        layer[n].y = layerHeight * (l + 1);
      }
    }
  }

  void _drawNode(Canvas canvas, DagNode node) {
    final color = switch (node.status) {
      DagNodeStatus.running => JarvisTheme.accent,
      DagNodeStatus.complete => JarvisTheme.green,
      DagNodeStatus.error => JarvisTheme.red,
      DagNodeStatus.pending => JarvisTheme.textSecondary,
    };

    // Circle
    canvas.drawCircle(
      Offset(node.x, node.y),
      14,
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      Offset(node.x, node.y),
      14,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Pulsing effect for running nodes
    if (node.status == DagNodeStatus.running) {
      canvas.drawCircle(
        Offset(node.x, node.y),
        6,
        Paint()..color = color,
      );
    }

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    tp.paint(canvas, Offset(node.x - tp.width / 2, node.y + 18));
  }

  void _drawArrow(Canvas canvas, double x, double y, Paint paint) {
    final path = Path()
      ..moveTo(x - 4, y - 6)
      ..lineTo(x, y)
      ..lineTo(x + 4, y - 6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DagGraphPainter old) => true;
}

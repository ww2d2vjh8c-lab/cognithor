import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jarvis_ui/services/api_client.dart';

/// Task model matching backend Task.to_dict() output.
class KanbanTask {
  final String id;
  String title;
  String description;
  String status;
  String priority;
  String assignedAgent;
  String source;
  String sourceRef;
  String parentId;
  List<String> labels;
  int sortOrder;
  String createdAt;
  String updatedAt;
  String completedAt;
  String createdBy;
  String resultSummary;
  List<KanbanTask> subtasks;

  KanbanTask({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'medium',
    this.assignedAgent = '',
    this.source = 'manual',
    this.sourceRef = '',
    this.parentId = '',
    this.labels = const [],
    this.sortOrder = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.completedAt = '',
    this.createdBy = 'user',
    this.resultSummary = '',
    this.subtasks = const [],
  });

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    return KanbanTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      assignedAgent: json['assigned_agent'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
      sourceRef: json['source_ref'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? '',
      labels: (json['labels'] as List<dynamic>?)?.cast<String>() ?? [],
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? 'user',
      resultSummary: json['result_summary'] as String? ?? '',
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((s) => KanbanTask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'assigned_agent': assignedAgent,
        'labels': labels,
        'parent_id': parentId,
      };

  String get statusDisplay {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'verifying':
        return 'Verifying';
      case 'done':
        return 'Done';
      case 'blocked':
        return 'Blocked';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Board statistics from /api/v1/kanban/stats
class KanbanStats {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> byAgent;
  final Map<String, int> bySource;

  KanbanStats({
    this.total = 0,
    this.byStatus = const {},
    this.byAgent = const {},
    this.bySource = const {},
  });

  factory KanbanStats.fromJson(Map<String, dynamic> json) {
    return KanbanStats(
      total: json['total'] as int? ?? 0,
      byStatus: (json['by_status'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      byAgent: (json['by_agent'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      bySource: (json['by_source'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

/// Provider managing Kanban board state with REST API and WebSocket updates.
class KanbanProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<KanbanTask> _tasks = [];
  KanbanStats _stats = KanbanStats();
  bool _loading = false;
  String? _error;
  bool _pipelineMode = false;

  List<KanbanTask> get tasks => _tasks;
  KanbanStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  bool get pipelineMode => _pipelineMode;

  /// Tasks grouped by status for the board columns.
  Map<String, List<KanbanTask>> get tasksByStatus {
    final map = <String, List<KanbanTask>>{};
    for (final status in ['todo', 'in_progress', 'verifying', 'done', 'blocked']) {
      map[status] = _tasks.where((t) => t.status == status).toList();
    }
    return map;
  }

  void togglePipelineMode() {
    _pipelineMode = !_pipelineMode;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // REST API
  // ---------------------------------------------------------------------------

  Future<void> fetchTasks({String? status, String? agent}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (agent != null) params['agent'] = agent;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '/api/v1/kanban/tasks${query.isNotEmpty ? '?$query' : ''}';
      final resp = await _api.get(url);

      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        _tasks = list.map((j) => KanbanTask.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _error = 'Failed to load tasks: ${resp.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> fetchStats() async {
    try {
      final resp = await _api.get('/api/v1/kanban/stats');
      if (resp.statusCode == 200) {
        _stats = KanbanStats.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<KanbanTask?> createTask({
    required String title,
    String description = '',
    String priority = 'medium',
    String assignedAgent = '',
    List<String> labels = const [],
    String parentId = '',
  }) async {
    try {
      final resp = await _api.post('/api/v1/kanban/tasks', body: {
        'title': title,
        'description': description,
        'priority': priority,
        'assigned_agent': assignedAgent,
        'labels': labels,
        'parent_id': parentId,
      });
      if (resp.statusCode == 201) {
        final task = KanbanTask.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        _tasks.insert(0, task);
        notifyListeners();
        return task;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> moveTask(String taskId, String newStatus, {int sortOrder = 0}) async {
    // Optimistic update
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      _tasks[idx].status = newStatus;
      _tasks[idx].sortOrder = sortOrder;
      notifyListeners();
    }

    try {
      final resp = await _api.post('/api/v1/kanban/tasks/$taskId/move', body: {
        'status': newStatus,
        'sort_order': sortOrder,
      });
      if (resp.statusCode == 200) {
        // Refresh from server
        await fetchTasks();
        return true;
      } else {
        // Revert optimistic update
        await fetchTasks();
        return false;
      }
    } catch (_) {
      await fetchTasks();
      return false;
    }
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> fields) async {
    try {
      final resp = await _api.patch('/api/v1/kanban/tasks/$taskId', body: fields);
      if (resp.statusCode == 200) {
        await fetchTasks();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final resp = await _api.delete('/api/v1/kanban/tasks/$taskId');
      if (resp.statusCode == 204) {
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> getHistory(String taskId) async {
    try {
      final resp = await _api.get('/api/v1/kanban/tasks/$taskId/history');
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as List<dynamic>).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ---------------------------------------------------------------------------
  // WebSocket handler
  // ---------------------------------------------------------------------------

  void onKanbanUpdate(Map<String, dynamic> msg) {
    final action = msg['action'] as String? ?? '';
    switch (action) {
      case 'created':
        if (msg['task'] != null) {
          _tasks.insert(0, KanbanTask.fromJson(msg['task'] as Map<String, dynamic>));
        }
        break;
      case 'updated':
      case 'moved':
        fetchTasks(); // Refresh from server for consistency
        return;
      case 'deleted':
        final taskId = msg['task_id'] as String? ?? '';
        _tasks.removeWhere((t) => t.id == taskId);
        break;
    }
    notifyListeners();
  }
}

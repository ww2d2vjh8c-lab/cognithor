/// Connection state — manages backend URL, health, and connectivity.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jarvis_ui/services/api_client.dart';
import 'package:jarvis_ui/services/websocket_service.dart';

enum JarvisConnectionState { disconnected, connecting, connected, error }

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider();

  static const _serverUrlKey = 'jarvis_server_url';
  static const _defaultUrl = 'http://localhost:8741';

  JarvisConnectionState state = JarvisConnectionState.disconnected;
  String serverUrl = _defaultUrl;
  String? errorMessage;
  String? backendVersion;

  ApiClient? _api;
  WebSocketService? _ws;

  ApiClient get api => _api!;
  WebSocketService get ws => _ws!;

  /// Load saved server URL and connect.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString(_serverUrlKey) ?? _defaultUrl;
    await connect();
  }

  /// Change server URL and reconnect.
  Future<void> setServerUrl(String url) async {
    final clean = url.trimRight().replaceAll(RegExp(r'/+$'), '');
    if (clean == serverUrl) return;
    serverUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, serverUrl);
    await connect();
  }

  /// Connect to the backend (health check + bootstrap).
  Future<void> connect() async {
    state = JarvisConnectionState.connecting;
    errorMessage = null;
    notifyListeners();

    _ws?.disconnect();
    _api = ApiClient(baseUrl: serverUrl);

    try {
      // Health check with 10s timeout
      final health = await _api!.get('/health').timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Backend nicht erreichbar ($serverUrl)'),
      );
      if (health.containsKey('error')) {
        throw Exception(health['error']);
      }
      backendVersion = health['version'] as String?;

      // Bootstrap token
      final token = await _api!.bootstrap();
      if (token == null) {
        throw Exception('Bootstrap fehlgeschlagen - kein Token erhalten');
      }

      // WebSocket
      final wsUrl = serverUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      _ws = WebSocketService(apiClient: _api!, wsBaseUrl: wsUrl);

      state = JarvisConnectionState.connected;
    } on TimeoutException catch (e) {
      state = JarvisConnectionState.error;
      errorMessage = e.message ?? 'Backend nicht erreichbar ($serverUrl)';
    } catch (e) {
      state = JarvisConnectionState.error;
      errorMessage = 'Backend nicht erreichbar ($serverUrl)';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ws?.disconnect();
    super.dispose();
  }
}

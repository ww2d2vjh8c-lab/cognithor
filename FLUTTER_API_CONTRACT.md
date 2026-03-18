# Jarvis Backend API Contract for Flutter Frontend

> This document defines the complete API surface that the Flutter frontend
> must implement. It serves as the single source of truth for the
> backend-frontend boundary.
>
> **Generated**: 2026-03-17 | **Backend version**: v0.40.0

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [WebSocket Protocol](#2-websocket-protocol)
3. [Core REST Endpoints](#3-core-rest-endpoints)
4. [Implementation Phases](#4-implementation-phases)

---

## 1. Authentication

### Token Lifecycle

```
App Launch
    |
    v
GET /api/v1/bootstrap  (no auth required)
    |
    v
Response: { "token": "<URL-safe-base64-token>" }
    |
    v
Cache token in memory (NOT localStorage/SharedPreferences)
    |
    v
All REST calls:  Authorization: Bearer <token>
WebSocket:       First message: {"type": "auth", "token": "<token>"}
    |
    v
On HTTP 401:     Invalidate cache, re-fetch from /bootstrap, retry once
On WS close 4001: Invalidate cache, reconnect with fresh token
```

### Rules

- Token is generated per backend session (changes on restart)
- Use `hmac`-safe constant-time comparison on the backend
- Never persist the token to disk (it's ephemeral)
- The `/api/v1/bootstrap` and `/api/v1/health` endpoints require NO auth

---

## 2. WebSocket Protocol

### Connection

```
URL:    ws://<host>:8741/ws/<session_id>
        wss://<host>:8741/ws/<session_id>  (with TLS)

session_id: Client-generated UUID (e.g., "flutter_<uuid>")
```

### Handshake

```
1. Client connects to /ws/{session_id}
2. Server accepts immediately
3. Client MUST send auth within 10 seconds:
   --> { "type": "auth", "token": "<token>" }
4. Server validates token
   - OK:   Connection proceeds
   - FAIL: <-- { "type": "error", "error": "Unauthorized" }
           Server closes with code 4001
```

### Client --> Server Messages (5 types)

#### `auth` - Authentication (MUST be first message)
```json
{ "type": "auth", "token": "<api_token>" }
```

#### `user_message` - Send text/file/voice
```json
{
  "type": "user_message",
  "text": "User's message text",
  "session_id": "flutter_<uuid>",
  "metadata": {
    "file_name": "photo.jpg",
    "file_type": "image/jpeg",
    "file_base64": "<base64-encoded-file>",
    "audio_base64": "<base64-encoded-audio>",
    "audio_type": "audio/webm"
  }
}
```
- `metadata` is optional (omit for plain text)
- `file_base64` and `audio_base64` are mutually exclusive

#### `approval_response` - Respond to approval request
```json
{
  "type": "approval_response",
  "id": "<request_id>",
  "approved": true,
  "session_id": "flutter_<uuid>"
}
```

#### `ping` - Heartbeat (every 30 seconds)
```json
{ "type": "ping" }
```

#### `cancel` - Cancel current operation
```json
{
  "type": "cancel",
  "session_id": "flutter_<uuid>"
}
```
> Implemented in `webui.py` via `_cancel_callback` (wired from Gateway).

---

### Server --> Client Messages (16 types)

#### `assistant_message` - Final response
```json
{
  "type": "assistant_message",
  "text": "Response text with **markdown**",
  "session_id": "flutter_<uuid>",
  "timestamp": "2026-03-17T12:34:56.789Z"
}
```

#### `stream_token` - Streaming text chunk
```json
{
  "type": "stream_token",
  "token": "word or chunk",
  "session_id": "flutter_<uuid>"
}
```
- Accumulate tokens to build the response in real-time
- Display immediately for typewriter effect

#### `stream_end` - End of streaming
```json
{
  "type": "stream_end",
  "session_id": "flutter_<uuid>"
}
```
- Finalize accumulated stream text as a complete message

#### `tool_start` - Tool execution begins
```json
{
  "type": "tool_start",
  "tool": "web_search",
  "data": { "status": "Searching..." },
  "session_id": "flutter_<uuid>",
  "timestamp": "2026-03-17T12:34:56.789Z"
}
```

#### `tool_result` - Tool execution complete
```json
{
  "type": "tool_result",
  "tool": "web_search",
  "data": { "results": 5 },
  "session_id": "flutter_<uuid>"
}
```

#### `approval_request` - Request user approval
```json
{
  "type": "approval_request",
  "request_id": "<uuid>",
  "session_id": "flutter_<uuid>",
  "tool": "shell_execute",
  "params": { "command": "rm -rf /tmp/old" },
  "reason": "Shell command requires approval"
}
```
- Show dialog; user responds with `approval_response`
- Backend waits up to 300 seconds

#### `status_update` - Phase status change
```json
{
  "type": "status_update",
  "status": "thinking | executing | finishing",
  "text": "Analyzing your request...",
  "session_id": "flutter_<uuid>"
}
```

#### `pipeline_event` - PGE cycle phase progress
```json
{
  "type": "pipeline_event",
  "phase": "plan | gate | execute | replan | iteration | complete",
  "status": "start | done | error",
  "iteration": 1,
  "elapsed_ms": 1234,
  "tools": ["web_search", "read_file"],
  "tools_used": ["web_search"],
  "success": 5,
  "failed": 1,
  "blocked": 0,
  "allowed": 6,
  "session_id": "flutter_<uuid>"
}
```
- `tools` field appears on `execute/start`
- `tools_used`, `success`, `failed` appear on `complete/done`
- `blocked`, `allowed` appear on `gate/done`

#### `plan_detail` - Plan review data
```json
{
  "type": "plan_detail",
  "iteration": 1,
  "goal": "Search for current weather",
  "reasoning": "User asked about weather, need web search",
  "confidence": 0.95,
  "steps": [
    {
      "tool": "web_search",
      "params": { "query": "weather today" },
      "rationale": "Find current weather data",
      "risk_estimate": "GREEN",
      "depends_on": []
    }
  ],
  "session_id": "flutter_<uuid>"
}
```

#### `canvas_push` - Update canvas/artifact content
```json
{
  "type": "canvas_push",
  "html": "<div>HTML content</div>",
  "title": "Weather Dashboard"
}
```
- Render in a sandboxed WebView widget

#### `canvas_reset` - Clear canvas
```json
{ "type": "canvas_reset" }
```

#### `canvas_eval` - JavaScript for canvas
```json
{
  "type": "canvas_eval",
  "js": "document.querySelector('#chart').update(data)"
}
```
- Currently blocked by `sandbox=""` in the web UI
- For Flutter: only execute in sandboxed WebView if needed

#### `transcription` - Voice transcription result
```json
{
  "type": "transcription",
  "text": "Transcribed speech text"
}
```
- Updates the last user message placeholder with actual text

#### `error` - Error message
```json
{
  "type": "error",
  "error": "Human-readable error message"
}
```

#### `pong` - Heartbeat response
```json
{ "type": "pong" }
```

#### `identity_state` - Cognitive identity state update
```json
{
  "type": "identity_state",
  "session_id": "flutter_<uuid>",
  "...": "identity state fields"
}
```
- Only sent when identity layer is installed and active

---

## 3. Core REST Endpoints

> All paths below are relative to the base URL (default: `http://localhost:8741`).
> All authenticated endpoints require: `Authorization: Bearer <token>`

### 3.1 System (no auth)

| Method | Path | Response | Notes |
|--------|------|----------|-------|
| GET | `/api/v1/health` | `{ "status": "ok", "version": "0.40.0", "uptime_seconds": 123 }` | Health check |
| GET | `/api/v1/bootstrap` | `{ "token": "<token>" }` | Get auth token |

### 3.2 Chat (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/api/v1/message` | `{ "text": "...", "session_id": "..." }` | `{ "text": "...", "session_id": "...", "duration_ms": 1234 }` |

### 3.3 Configuration (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/config` | - | Full config object (secrets masked) |
| PATCH | `/api/v1/config` | `{ "field": "value" }` | `{ "status": "ok", "results": [...] }` |
| PATCH | `/api/v1/config/{section}` | `{ "field": "value" }` | `{ "status": "ok", "updated_fields": [...] }` |
| POST | `/api/v1/config/reload` | - | `{ "status": "reloaded" }` |
| POST | `/api/v1/config/presets/{name}` | - | `{ "status": "applied" }` |
| GET | `/api/v1/locales` | - | `{ "locales": [...], "current": "de" }` |
| POST | `/api/v1/translate-prompts` | `{ "target_language": "en" }` | `{ "status": "ok", "translated_prompts": {...} }` |

### 3.4 Agent & Binding Management (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/agents` | - | Agent profiles list |
| POST | `/api/v1/agents/{name}` | Agent config | `{ "status": "ok" }` |
| GET | `/api/v1/bindings` | - | Binding rules list |
| POST | `/api/v1/bindings/{name}` | Binding config | `{ "status": "ok" }` |

### 3.5 Prompts (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/prompts` | - | System/replan/personality prompts |
| PUT | `/api/v1/prompts` | Prompt updates | `{ "status": "ok", "updated": [...] }` |

### 3.6 Cron, MCP, A2A (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/cron-jobs` | - | Cron job list |
| PUT | `/api/v1/cron-jobs` | Jobs config | `{ "status": "ok" }` |
| GET | `/api/v1/mcp-servers` | - | MCP server config |
| PUT | `/api/v1/mcp-servers` | Server config | `{ "status": "ok" }` |
| GET | `/api/v1/a2a` | - | A2A config |
| PUT | `/api/v1/a2a` | A2A config | `{ "status": "ok" }` |

### 3.7 System Control (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/system/status` | - | `{ "components": [...] }` |
| POST | `/api/v1/system/start` | `{ "component": "..." }` | `{ "status": "started" }` |
| POST | `/api/v1/system/stop` | `{ "component": "..." }` | `{ "status": "stopped" }` |
| POST | `/api/v1/shutdown` | - | Shuts down the backend |

### 3.8 Voice & Media (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/api/v1/tts` | `{ "text": "..." }` | Audio binary (WAV/MP3) |
| POST | `/api/v1/voice/transcribe` | FormData: audio file | `{ "text": "transcribed..." }` |
| POST | `/api/v1/vision/analyze` | FormData: image + prompt | `{ "text": "analysis..." }` |

### 3.9 Prompt Evolution (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/prompt-evolution/stats` | - | Evolution statistics |
| POST | `/api/v1/prompt-evolution/toggle` | `{ "enabled": true }` | `{ "status": "ok" }` |
| POST | `/api/v1/prompt-evolution/evolve` | `{ ... }` | `{ "status": "ok" }` |

### 3.10 Workflows (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/workflows/templates` | - | Template list |
| GET | `/api/v1/workflows/instances` | - | Running instances |
| GET | `/api/v1/workflows/stats` | - | Workflow statistics |
| GET | `/api/v1/workflows/dag/runs` | - | DAG run history |
| GET | `/api/v1/workflows/dag/runs/{id}` | - | Specific run details |
| POST | `/api/v1/workflows/instances` | `{ "template_id": "..." }` | `{ "instance_id": "..." }` |

### 3.11 Memory & Knowledge Graph (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/memory/graph/stats` | - | Graph statistics |
| GET | `/api/v1/memory/graph/entities` | - | Entity list |
| GET | `/api/v1/memory/graph/entities/{id}/relations` | - | Entity relations |

### 3.12 Identity (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/identity/state` | - | Identity state (or `{ "available": false }`) |
| POST | `/api/v1/identity/{action}` | - | Action result (`dream`, `freeze`, `unfreeze`, `reset`) |

### 3.13 Push Notifications (auth required -- NEEDS FIX)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/push/vapid-key` | - | `{ "key": "<vapid-public-key>" }` |
| POST | `/api/v1/push/register` | `{ "token": "...", "type": "fcm" }` | `{ "status": "ok" }` |

> Note: PWA currently sends these WITHOUT auth headers.
> Flutter must include auth. Backend should enforce it.

### 3.14 Monitoring (auth required)

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/monitoring/dashboard` | - | Dashboard data |
| GET | `/api/v1/monitoring/metrics` | - | Current metrics |
| GET | `/api/v1/monitoring/events` | `?n=50&severity=` | Recent events |
| GET | `/api/v1/monitoring/audit` | `?skip=0&limit=50` | Audit log |

---

## 4. Implementation Phases

### Phase 2: Flutter Scaffold (MVP)

**9 endpoints + WebSocket = functional chat app**

```
Auth:    GET /api/v1/bootstrap
Health:  GET /api/v1/health
Chat:    WebSocket /ws/{session_id}  (all 21 message types)
Voice:   POST /api/v1/tts
         POST /api/v1/voice/transcribe
Vision:  POST /api/v1/vision/analyze
Push:    POST /api/v1/push/register
         GET /api/v1/push/vapid-key
Config:  GET /api/v1/config  (for wake word, theme, etc.)
```

**Flutter screens needed:**
1. `ChatScreen` - Main conversation (text + voice + file upload)
2. `ApprovalDialog` - Tool approval modal
3. `SettingsScreen` - Server URL, basic config
4. Splash/loading with health check

### Phase 3: Full Feature Parity

**Add 30+ endpoints for Control Center features**

```
Configuration:  14 endpoints (config, agents, bindings, prompts, cron, mcp, a2a)
Workflows:       6 endpoints
Memory/Graph:    3 endpoints
Identity:        2 endpoints
Monitoring:      4 endpoints
System Control:  4 endpoints
Evolution:       3 endpoints
```

**Flutter screens needed:**
5. `ConfigScreen` - Settings management (replaces CognithorControlCenter)
6. `AgentsScreen` - Agent management
7. `WorkflowScreen` - Workflow DAG visualization
8. `MemoryScreen` - Knowledge graph viewer
9. `IdentityScreen` - Cognitive identity dashboard
10. `MonitoringScreen` - Metrics and audit
11. `SkillsScreen` - Skill marketplace

### Phase 4: Cut Over

- Remove `ui/` (React) and `apps/pwa/` (Preact+Capacitor)
- Flutter builds for: Web, Android, iOS, Windows, macOS
- Single codebase replaces both frontend projects

---

## Backend Changes — Status

| # | Change | Status |
|---|--------|--------|
| 1 | Handle `cancel` message in WebSocket handler | DONE — `webui.py` + `gateway.py` cancel_callback |
| 2 | Add auth to push/voice/vision endpoints | DONE — all use `_Depends(_verify_cc_token)` |
| 3 | Return proper HTTP status codes | PARTIAL — error responses now include `code` field |
| 4 | Standardize error responses: `{ "error": "...", "code": "..." }` | DONE — TTS, identity, voice, vision, push |
| 5 | Add OpenAPI schema generation | DONE — `/api/docs`, `/api/redoc`, `/api/v1/openapi.json` |

### New Endpoints Added (Phase 3)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/voice/transcribe` | Bearer | Multipart audio upload, Whisper STT |
| POST | `/api/v1/vision/analyze` | Bearer | Multipart image upload + optional prompt |
| GET | `/api/v1/push/vapid-key` | Bearer | VAPID public key for push notifications |
| POST | `/api/v1/push/register` | Bearer | Register device for push (FCM/APNS) |

### Static File Priority

Backend serves pre-built UI at `/` with this priority:
1. `flutter_app/build/web/` (Flutter)
2. `ui/dist/` (React — legacy)
3. `channels/webchat/` (built-in fallback)

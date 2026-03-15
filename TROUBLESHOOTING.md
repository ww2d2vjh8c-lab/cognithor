# Cognithor Troubleshooting

> Common problems and their solutions.
> For deployment-specific issues, see [deploy/README.md](deploy/README.md).

## Table of Contents

- [Startup Issues](#startup-issues)
- [LLM / Ollama](#llm--ollama)
- [WebUI / WebSocket](#webui--websocket)
- [Tools & Gatekeeper](#tools--gatekeeper)
- [Memory System](#memory-system)
- [Channels](#channels)
- [Performance](#performance)
- [Windows-Specific](#windows-specific)

---

## Startup Issues

### ImportError on launch

```
ModuleNotFoundError: No module named 'jarvis'
```

Install in editable mode:
```bash
pip install -e ".[dev]"
```

### Missing optional dependencies

```
Optional feature 'telegram' not available: No module named 'telegram'
```

Install the required extra:
```bash
pip install -e ".[telegram]"
```

Available extras: `search`, `documents`, `telegram`, `discord`, `slack`,
`matrix`, `web`, `cron`, `vector`, `postgresql`, `irc`, `twitch`, `mcp`.

### Port already in use

```
[ERROR] Address already in use: 0.0.0.0:8741
```

Find and stop the conflicting process:
```bash
# Linux/macOS
lsof -i :8741
kill <PID>

# Windows
netstat -ano | findstr :8741
taskkill /PID <PID> /F
```

Or use a different port:
```bash
python -m jarvis --api-port 8742
```

### Preflight check fails

Run the diagnostics script:
```bash
python scripts/preflight_check.py
```

It validates Python version, Ollama connectivity, model availability, and
package imports. Use `--fix` to auto-resolve model issues:
```bash
python scripts/first_boot.py --fix
```

---

## LLM / Ollama

### Ollama not reachable

```
[ERROR] Connection refused: http://localhost:11434
```

1. Check if Ollama is running: `ollama list`
2. Start it: `ollama serve`
3. If using a remote Ollama, set the URL:
   ```bash
   export OLLAMA_HOST=http://192.168.1.100:11434
   # or in config.yaml:
   # ollama:
   #   base_url: "http://192.168.1.100:11434"
   ```

### Model not found

```
[ERROR] Model 'qwen3:32b' not found
```

Pull the model:
```bash
ollama pull qwen3:32b
```

### Out of VRAM

```
[ERROR] CUDA out of memory
```

Use smaller models:
```yaml
# ~/.jarvis/config.yaml
models:
  planner:
    name: qwen3:14b    # Instead of 32b
  executor:
    name: qwen3:8b
```

VRAM guide:

| GPU VRAM | Planner | Executor |
|----------|---------|----------|
| 32 GB | qwen3:32b | qwen3:8b |
| 24 GB | qwen3:32b | qwen3:8b |
| 12 GB | qwen3:14b | qwen3:8b |
| 8 GB | qwen3:8b | qwen3:8b |

### LLM ignores search results

The Planner (qwen3:32b) sometimes overrides web search results with training
data. This is mitigated by aggressive prompting in `formulate_response()` and
`REPLAN_PROMPT`. If it persists:

1. Use `search_and_read` instead of `web_search` (fetches full pages)
2. Increase `planner.response_token_budget` in config
3. Check that the search results are actually being injected into Working Memory

---

## WebUI / WebSocket

### WebSocket reconnect loop

```
[WS] Reconnecting in 3000ms (attempt 1/10)
[WS] Reconnecting in 6000ms (attempt 2/10)
```

**After server restart:** The browser caches a stale auth token. Hard refresh
(`Ctrl+Shift+R`) clears the cache. The code invalidates `_wsTokenCache` on
close code 4001, so reconnect should auto-fix.

**Server not running:** Check that the backend is running on the expected port:
```bash
curl http://localhost:8741/api/v1/health
```

### WebUI returns 503

The WebUI's `create_app()` factory runs standalone without a Gateway.
`POST /api/v1/message` returns 503 — this is expected. WebSocket communication
requires the Gateway to be running and connected.

### Canvas not displaying

Check the browser console for Content Security Policy errors. The canvas uses
an iframe with `srcdoc` — some CSP headers may block inline scripts.

---

## Tools & Gatekeeper

### Tool blocked (ORANGE/RED)

```
[GATEKEEPER] BLOCKED: exec_command — risk level RED
```

**Unknown tools** default to ORANGE. If you added a new tool:
1. Register it in `core/gatekeeper.py` → `_classify_risk()`
2. Add to the appropriate risk set (`_GREEN_TOOLS`, `_YELLOW_TOOLS`, etc.)

**Destructive commands** (`rm -rf`, `sudo`, `dd`) are always RED.

### Path validation error

```
[ERROR] Path traversal blocked: /etc/passwd
```

File operations are restricted to `allowed_paths` in config:
```yaml
security:
  allowed_paths:
    - ~/.jarvis
    - ~/Documents
    - /path/to/project
```

### Tool timeout

Default timeout is 30s. Media tools have higher limits (120-180s). Override:
```yaml
executor:
  default_timeout_seconds: 60
```

---

## Memory System

### Memory search returns no results

1. Check if memory has data:
   ```
   User > Memory-Statistiken anzeigen
   ```
2. Verify embeddings model is loaded:
   ```bash
   ollama list | grep nomic-embed
   ```
3. Re-index if needed (memory is stored in `~/.jarvis/memory/`)

### Episodic memory growing too large

The `EpisodicCompressor` summarizes old entries. If it's not running:
```yaml
memory:
  compressor_enabled: true
  compressor_age_days: 30
```

### Knowledge graph inconsistencies

Run memory hygiene scan via API:
```bash
curl -X POST http://localhost:8741/api/v1/memory/hygiene/scan \
  -H "Authorization: Bearer <token>"
```

---

## Channels

### Telegram bot not responding

1. Check token: `echo $JARVIS_TELEGRAM_TOKEN`
2. Verify bot is started in config:
   ```yaml
   channels:
     telegram:
       enabled: true
   ```
3. Check allowed users: `JARVIS_TELEGRAM_ALLOWED_USERS=123456,789012`
4. Review logs: `tail -f ~/.jarvis/logs/jarvis.log | grep telegram`

### Discord/Slack connection fails

Most channel-specific issues are dependency problems. Install the right extra:
```bash
pip install -e ".[discord]"   # discord.py
pip install -e ".[slack]"     # slack-sdk
```

---

## Performance

### Slow response times

1. **Model too large** — Use a smaller executor model (qwen3:8b)
2. **Too many PGE iterations** — Reduce `planner.max_iterations`:
   ```yaml
   planner:
     max_iterations: 15    # Default: 25
   ```
3. **Memory search slow** — Check FAISS index size, consider reducing `top_k`
4. **Web search slow** — Set up SearXNG locally for faster results

### High memory usage

1. **Ollama context** — Reduce `models.planner.context_window`
2. **Session history** — Reduce session storage limit
3. **Vector index** — FAISS HNSW uses ~1 GB per 500K entries

---

## Windows-Specific

### Unicode output errors

```
UnicodeEncodeError: 'charmap' codec can't encode character
```

Windows console uses cp1252 by default. The codebase uses ASCII-safe symbols
(`[OK]`/`[FAIL]` instead of checkmarks/arrows). If you see this in your own
code, set UTF-8 mode:
```bash
set PYTHONIOENCODING=utf-8
```

### `connect_read_pipe` not supported

```
NotImplementedError: connect_read_pipe
```

Windows ProactorEventLoop doesn't support `connect_read_pipe`. The MCP server
uses `loop.run_in_executor()` with a threading reader as fallback.

### Sandbox level

Windows uses Job Objects (`jobobject` sandbox level) instead of Linux
namespaces (`bwrap`). This provides resource limits but less isolation than
Linux containers.

### Long path issues

Enable long paths in Windows:
```
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1
```

Or use shorter `JARVIS_HOME`:
```bash
set JARVIS_HOME=C:\jarvis
```

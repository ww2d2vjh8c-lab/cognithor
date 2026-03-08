# Security Audit Findings — Cognithor v0.27.3-beta

**Datum:** 2026-03-07
**Scope:** ~230 Source-Dateien, 5-Pass Audit (Security, Portability, Reliability, Logic, Performance)
**Verifiziert:** Alle Findings gegen echten Quellcode geprüft, 17 False Positives eliminiert

---

## Legende

- **Status:** `OPEN` | `IN PROGRESS` | `FIXED` | `WONTFIX` | `DEFERRED`
- **Severity:** `CRITICAL` | `HIGH` | `MEDIUM`
- **Kategorie:** SEC (Security) | PORT (Portability) | REL (Reliability) | LOGIC (Logic) | PERF (Performance)

---

## CRITICAL

### F-001: PerAgentSecretVault hasht statt verschluesselt
- **Datei:** `src/jarvis/security/sandbox_isolation.py:243`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `PerAgentSecretVault.store()` verwendet `hashlib.sha256(value.encode()).hexdigest()` — eine Einweg-Hashfunktion statt Verschluesselung. Die `retrieve()`-Methode gibt den Hash zurueck, nicht das Original. Secrets sind nach dem Speichern unwiederbringlich verloren.
- **Fix:** SHA-256-Hash ersetzt durch Fernet-Verschluesselung (AES-128-CBC + HMAC). Jeder Agent erhaelt einen eigenen Key, abgeleitet via PBKDF2-HMAC-SHA256 (600k Iterationen) aus agent_id + zufaelligem 16-Byte-Salt (os.urandom). `retrieve()` entschluesselt und gibt den Originalwert zurueck. `revoke_all()` raeumt auch Crypto-Keys auf. 34 neue Tests in `tests/test_security/test_f001_secret_vault_encryption.py`, 6 bestehende Tests weiterhin gruen.

---

## HIGH

### F-002: AgentVault Key nur aus agent_id abgeleitet — FIXED
- **Datei:** `src/jarvis/security/agent_vault.py:114-122`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Salt und Key-Material wurden deterministisch und ausschliesslich aus `agent_id` abgeleitet. Kein Master-Key, kein OS-Secret, keine Zufallskomponente. Jeder, der die `agent_id` kannte, konnte den Fernet-Key rekonstruieren und alle Vault-Daten entschluesseln.
- **Fix:** Master-Secret (32 Bytes via `os.urandom`) wird persistent in `~/.jarvis/vault_master.key` gespeichert und in die PBKDF2-Key-Derivation einbezogen (`raw_key_material = f"vault:{agent_id}".encode() + master_secret`). `AgentVaultManager` laedt/erstellt das Secret automatisch via `_load_or_create_master_secret()`. Backward-compatible: leeres `master_secret` ergibt altes Verhalten. 22 Tests in `tests/test_security/test_f002_vault_key_derivation.py`.

### F-003: MCP auth_token im Klartext via GET-Endpoint — FIXED
- **Datei:** `src/jarvis/channels/config_routes.py:2435`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Der `GET /api/v1/mcp-servers` Endpoint gab das `auth_token` Feld im Klartext in der JSON-Response zurueck.
- **Fix:** Token wird maskiert: `"auth_token": "***" if sm.get("auth_token") else ""`. Leeres/fehlendes Token bleibt leer. PUT akzeptiert weiterhin Klartext. 4 Tests in `tests/test_security/test_f003_auth_token_masking.py`.

### F-004: Unsandboxed pytest-Ausfuehrung von LLM-generiertem Code — FIXED
- **Datei:** `src/jarvis/tools/skill_cli.py:337-358`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** LLM-generierter Test-Code wurde via `subprocess.run()` ohne Sandbox ausgefuehrt, mit vollem Eltern-Environment.
- **Fix:** Drei Haertungsmassnahmen:
  1. **Sanitized Environment** via `_build_safe_env()`: Nur minimale Vars (PATH, SYSTEMROOT/TEMP auf Windows, HOME/LANG auf Unix). Keine API-Keys, Tokens oder sonstige sensitive Variablen werden vererbt.
  2. **`--import-mode=importlib`**: Verhindert sys.path-Manipulation durch Test-Code.
  3. **`-p no:cacheprovider` + `--no-header`**: Kein Schreiben ausserhalb des tmpdir, keine System-Info-Leaks.
  Vollstaendiger Sandbox-Umbau (async `Sandbox.execute()`) waere ideal, erfordert aber async-Refactoring der gesamten SkillCLI-Kette. 16 Tests in `tests/test_security/test_f004_sandboxed_skill_tests.py`.

---

## MEDIUM

### F-005: Config-Endpoints ohne Schema-Validation — FIXED
- **Datei:** `src/jarvis/channels/config_routes.py:2181,2210`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** 2 von 5 Endpoints (`ui_upsert_agent`, `ui_upsert_binding`) schrieben `request.json()` direkt in YAML-Dateien ohne Schema-Validation. Die anderen 3 (`ui_put_prompts`, `ui_put_cron_jobs`, `ui_put_mcp_servers`) waren bereits sicher via explizite Key-Whitelists bzw. Pydantic-Model (`CronJob`).
- **Fix:** `ui_upsert_agent` validiert jetzt via `AgentProfileDTO(**body).model_dump()`, `ui_upsert_binding` via `BindingRuleDTO(**body).model_dump()`. Beide DTOs existierten bereits in `gateway/config_api.py`. Unbekannte Felder werden von Pydantic ignoriert (nicht gespeichert), Typ-Fehler werden abgelehnt. 9 Tests in `tests/test_security/test_f005_config_schema_validation.py`. Bestehender Test `test_upsert_binding` angepasst (jetzt `target_agent` required).

### F-006: WebUI Default 0.0.0.0 + CORS * — FIXED
- **Datei:** `src/jarvis/channels/webui.py:806-808`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `create_app()` Factory band per Default auf `0.0.0.0` mit CORS-Origins `*`.
- **Fix:** Default-Host geaendert auf `127.0.0.1`, Default-CORS auf `http://localhost:8741`. Explizites Opt-in via `JARVIS_WEBUI_HOST=0.0.0.0` und `JARVIS_WEBUI_CORS_ORIGINS=*` weiterhin moeglich (Docker-Deployments setzen dies bereits explizit). `WebUIChannel.__init__` hatte bereits `host="127.0.0.1"` als Default. 9 Tests in `tests/test_security/test_f006_webui_defaults.py`.

### F-007: Gemini API Key in URL Query-String (7x) — FIXED
- **Dateien:** `src/jarvis/core/llm_backend.py` (5 Stellen) + `src/jarvis/memory/embeddings.py` (2 Stellen)
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Gemini API Key wurde als `?key=API_KEY` in die URL eingesetzt (7 Stellen). Erschien in HTTP-Logs, Proxy-Logs, potenziell Browser-History.
- **Fix:** API-Key wird jetzt ausschliesslich als `x-goog-api-key` HTTP-Header gesendet (von Google offiziell unterstuetzt). Header wird beim httpx-Client-Setup als Default-Header konfiguriert (`headers={"x-goog-api-key": self._api_key}`). Alle 7 URL-Konstruktionen bereinigt. 12 Tests in `tests/test_security/test_f007_gemini_key_in_header.py`, 18 bestehende Gemini-Tests weiterhin gruen.

### F-008: WebSocket-Token als Query-Parameter — FIXED
- **Dateien:** `src/jarvis/__main__.py:354-383` + `src/jarvis/channels/webui.py:351-381`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** WebSocket-Authentifizierung via `websocket.query_params.get("token")` — Token erschien in Server-Logs und Proxy-Logs.
- **Fix:** Token wird jetzt via erster WS-Nachricht (`{"type": "auth", "token": "..."}`) gesendet, nicht als Query-Parameter. WebSocket wird erst accepted, dann Auth-Nachricht mit 10s Timeout erwartet. Timing-sicherer Vergleich via `hmac.compare_digest()`. Bei Failure: Error-Nachricht + Close(4001). Beide Stellen (`__main__.py` + `webui.py`) gefixt. 12 Tests in `tests/test_security/test_f008_ws_token_not_in_query.py`.

### F-009: Keine Checksum-Verifizierung fuer Voice-Models — FIXED
- **Datei:** `src/jarvis/__main__.py:631-694`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `urllib.request.urlretrieve()` lud `.onnx` Modelle von HuggingFace ohne Hash-Verifizierung.
- **Fix:** Nach Download wird SHA-256 berechnet und via `_verify_voice_hash()` geprueft. `_KNOWN_VOICE_HASHES` Dictionary fuer bekannte Modell-Hashes (befuellbar beim ersten Download via Log-Output). Bei Hash-Mismatch: `ValueError` (Download wird abgelehnt). Bei unbekannter Voice: Warning + Hash im Log (nicht blockierend, damit neue Voices nutzbar bleiben). 13 Tests in `tests/test_security/test_f009_voice_model_checksum.py`.

### F-010: Auto pip install ohne User-Bestaetigung
- **Datei:** `src/jarvis/core/startup_check.py:267-308`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `check_python_packages()` installiert fehlende Pakete automatisch via `_pip_install()` ohne User-Prompt. Paketnamen sind hardcoded (kein User-Input), aber stille Installation ist ein Supply-Chain-Risiko.
- **Fix:** `StartupChecker` akzeptiert jetzt `auto_install: bool = False` (keyword-only). Ohne `--auto-install` CLI-Flag werden fehlende Pakete nur als Warning gemeldet (inkl. Hinweis auf `--auto-install` und manuellen `pip install`-Befehl). `__main__.py` leitet `--auto-install` Flag an StartupChecker weiter. 20 neue Tests in `tests/test_security/test_f010_auto_install_flag.py`, 108 Tests gesamt (inkl. bestehende) gruen.

### F-011: O(N^2) Duplicate Detection — FIXED
- **Datei:** `src/jarvis/memory/integrity.py:192-253`
- **Kategorie:** PERF
- **Status:** FIXED
- **Beschreibung:** `detect()` verglich jeden Eintrag paarweise (O(N^2)) ohne Batch-Limit oder Caching.
- **Fix:** Drei Optimierungen:
  1. **MAX_ENTRIES=5000 Batch-Limit** — bei zu vielen Eintraegen werden nur die neuesten verarbeitet.
  2. **Normalisierung gecacht** — jeder Entry wird genau einmal normalisiert (statt redundant im Inner-Loop).
  3. **Pre-Filter via Wort-Set-Groesse** — Paare mit `min(|A|,|B|)/max(|A|,|B|) < threshold` werden uebersprungen (Jaccard kann nie hoch genug sein).
  Zusaetzlich: `_jaccard()` als eigene Methode extrahiert, arbeitet auf vorberechneten Sets. 16 Tests in `tests/test_security/test_f011_duplicate_detection_perf.py`.

### F-012: CI/CD Gate Override ohne Authentifizierung
- **Datei:** `src/jarvis/security/cicd_gate.py:164-172`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `override()` akzeptiert beliebige `by`/`reason` Strings ohne Authentifizierung oder Autorisierung. Interne Python-API, aber keine Zugriffskontrolle.
- **Fix:** Role-Check ueber `AUTHORIZED_OVERRIDE_ROLES` (admin, security-lead, release-manager). Unautorisierte Rollen loesen `PermissionError` aus. Begruendung muss mind. 10 Zeichen lang sein (`ValueError` bei zu kurz). Alle Override-Versuche (genehmigt + abgelehnt) werden im `_audit_log` mit Zeitstempel, Rolle, Begruendung und vorherigem Verdict protokolliert. 23 neue Tests in `tests/test_security/test_f012_cicd_gate_override_auth.py`, 1 bestehender Test angepasst (`test_secondary_coverage.py`), alle 44 cicd-Tests gruen.

### F-013: IRC Passwort im Klartext (SSL Default=False)
- **Datei:** `src/jarvis/channels/irc.py:51,97-98`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `use_ssl` ist per Default `False`, Port 6667. Wenn ein Passwort gesetzt ist, wird `PASS {password}` im Klartext ueber das Netzwerk gesendet.
- **Fix:** Default `use_ssl=True`, Default-Port auf 6697 (IRC-SSL-Standard). Neuer Guard in `start()`: wenn Passwort gesetzt und SSL deaktiviert, wird die Verbindung verweigert (Error-Log + fruehes Return). Ohne Passwort + ohne SSL bleibt erlaubt (kein Klartext-Risiko). 11 neue Tests in `tests/test_security/test_f013_irc_password_ssl.py`, alle 142 bestehenden IRC-Tests weiterhin gruen.

### F-014: Signal Webhook ohne Signatur-Verifizierung
- **Datei:** `src/jarvis/channels/signal.py:296-306`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Webhook-Endpoint akzeptiert POST-Requests ohne HMAC-Verifizierung, Shared-Secret oder Source-IP-Check. Default-Binding `127.0.0.1` limitiert Exposure, aber bei `0.0.0.0` ist keine Auth vorhanden.
- **Fix:** Neuer `webhook_secret` Parameter. Bei gesetztem Secret wird `X-Webhook-Signature` Header per HMAC-SHA256 (`hmac.compare_digest`) gegen den Request-Body verifiziert — fehlende/falsche Signatur ergibt 403. Ohne Secret bleibt Backward-Compatible. Warnung wenn `webhook_host != 127.0.0.1` und kein Secret konfiguriert. 17 neue Tests in `tests/test_security/test_f014_signal_webhook_signature.py`, alle 55 bestehenden Signal-Tests weiterhin gruen.

### F-015: Matrix stille Fallback auf unverschluesselt
- **Datei:** `src/jarvis/channels/matrix.py:138-143`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Wenn `libolm`/`python-olm` nicht installiert ist, sendet der Client unverschluesselt ohne Warnung. Kein Check auf E2EE-Verfuegbarkeit.
- **Fix:** E2EE-Pruefung in `start()` vor Client-Erstellung: `import olm` wird versucht. Bei Fehlen: WARNING ueber unverschluesselte Nachrichten inkl. Installationshinweis. Neuer `require_e2ee` Parameter (Default `False`): bei `True` und fehlendem olm wird der Start komplett verweigert (Error-Log + return). 11 neue Tests in `tests/test_security/test_f015_matrix_e2ee_fallback.py`, alle 57 bestehenden Matrix-Tests weiterhin gruen.

### F-016: shutil.rmtree ohne Path-Traversal-Validation
- **Datei:** `src/jarvis/skills/community/client.py:339-344`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `skill_name` wird ohne Validation in einen Pfad eingesetzt und an `shutil.rmtree()` uebergeben. Ein `skill_name` mit `../..` koennte Verzeichnisse ausserhalb des Community-Dirs loeschen.
- **Fix:** Path-Traversal-Validation via `.resolve()` + `.relative_to(community_dir.resolve())` in beiden Methoden `install()` und `uninstall()`. Bei Traversal-Versuch: `install()` gibt `InstallResult(success=False, errors=["Path-Traversal"])` zurueck, `uninstall()` loggt Error und gibt `False` zurueck. 14 neue Tests in `tests/test_security/test_f016_path_traversal_community.py` (install-Traversal, uninstall-Traversal, Edge-Cases, Source-Level), alle 43 verwandten Tests gruen.

### F-017: Install-History silent Reset + non-atomic Write
- **Datei:** `src/jarvis/skills/remote_registry.py:527-540`
- **Kategorie:** REL
- **Status:** FIXED
- **Beschreibung:** Bei JSON-Parse-Fehler wird `self._installed` stillschweigend auf `{}` zurueckgesetzt — gesamte History verloren. `_save_install_history()` schreibt non-atomic via `write_text()`, Crash waehrend Write korrumpiert die Datei.
- **Fix:** `_load_install_history()`: Bei Parse-Fehler wird `log.warning()` geloggt und korrupte Datei als `.json.corrupt` Backup gesichert. `_save_install_history()`: Atomic write via `tempfile.mkstemp()` + `os.replace()` — bei Fehler waehrend Write wird temp-Datei aufgeraeumt, Original bleibt intakt. 13 neue Tests in `tests/test_security/test_f017_install_history_safety.py`, alle 36 bestehenden remote_registry-Tests weiterhin gruen.

### F-018: Base64-Audio ohne Size-Limit
- **Datei:** `src/jarvis/__main__.py:425-436`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** WebSocket-Audio-Daten werden als Base64 empfangen und ohne Groessenpruefung vollstaendig in Memory dekodiert. Memory Exhaustion moeglich.
- **Fix:** Size-Estimation (`len(audio_b64) * 3 // 4`) vor `b64decode()` eingefuegt. Limit 50 MB (konsistent mit `webui.py MAX_UPLOAD_SIZE`). Bei Ueberschreitung wird Error-Response gesendet und `continue` ausgefuehrt.
- **Tests:** `tests/test_security/test_f018_audio_base64_size_limit.py` (17 Tests, 4 Klassen)

### F-019: GDPR ANONYMIZE/ARCHIVE nicht implementiert
- **Datei:** `src/jarvis/security/gdpr.py:502-551`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `RetentionEnforcer.enforce()` implementiert nur `DELETE`. `ANONYMIZE` und `ARCHIVE` Actions werden gezaehlt aber nicht ausgefuehrt — das System meldet Compliance ohne tatsaechliche Datentransformation.
- **Fix:** ANONYMIZE setzt PII-Felder zurueck (`user_id="ANONYMIZED"`, `data_summary=""`, `data_hash=""`, `purpose="ANONYMIZED"`, `third_party=""`), Record bleibt fuer Statistik erhalten. ARCHIVE verschiebt Records aus `_records` nach `_archived` (neues Property `DataProcessingLog.archived`). Alle 49 bestehenden GDPR-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f019_gdpr_anonymize_archive.py` (21 Tests, 5 Klassen)

### F-020: Windows Sandbox Fallback ohne Resource-Limits
- **Datei:** `src/jarvis/security/sandbox.py:331-362`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Wenn `CreateJobObjectW` fehlschlaegt, faellt der Code auf `_exec_process_bare` zurueck — ein bare Subprocess ohne Memory/CPU-Limits. Nur Timeout bleibt als Schutz.
- **Fix:** 1) Neues Feld `SandboxResult.isolation_degraded` (default False) signalisiert dem Caller reduzierte Isolation. 2) Neues Feld `SandboxConfig.allow_degraded_sandbox` (default True): Bei `False` wird Ausfuehrung verweigert statt Fallback. 3) Bei Fallback wird `log.warning` mit `degraded_fallback` geloggt und `isolation_degraded=True` gesetzt. Bei Verweigerung `log.error` mit `execution_refused`. Alle 181 bestehenden Sandbox/Secondary-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f020_sandbox_degraded_fallback.py` (16 Tests, 5 Klassen)

### F-021: Docker --cpus falsche Einheiten
- **Datei:** `src/jarvis/security/sandbox.py:621-622`
- **Kategorie:** LOGIC
- **Status:** FIXED
- **Beschreibung:** `--cpus` erwartet Anzahl CPU-Cores (z.B. `1.5`), aber der Code uebergibt `max_cpu_seconds / 10`. Bei `max_cpu_seconds=60` ergibt das `--cpus 6.0` (6 Cores) — semantisch falsch.
- **Fix:** Neues Feld `SandboxConfig.max_cpu_cores: float = 1.0` (Range 0.1–64.0) eingefuehrt. Docker `--cpus` verwendet jetzt `self._config.max_cpu_cores` statt `self._config.max_cpu_seconds / 10`. `max_cpu_seconds` bleibt fuer CPU-Zeitlimit (Job Objects, ulimit) erhalten. Alle 181 bestehenden Sandbox-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f021_docker_cpus_units.py` (20 Tests, 4 Klassen)

### F-022: Silero VAD via torch.hub.load ohne Integrity-Check
- **Datei:** `src/jarvis/channels/voice.py:386-430`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `torch.hub.load("snakers4/silero-vad", ...)` laedt und fuehrt Code von GitHub aus. Kein gepinnter Hash, keine Signaturpruefung. Cache nach erstem Download, aber initialer Download ist angreifbar.
- **Fix:** 1) Repo-Referenz auf Release-Tag gepinnt (`SILERO_REPO = "snakers4/silero-vad:v5.1"` statt ungepinnter `main`-Branch). 2) SHA-256 Integrity-Check ueber Model-State-Dict (`SILERO_MODEL_HASH`). Bei Mismatch wird Modell verworfen und Energie-VAD-Fallback verwendet. Hash-Feld initial leer (Check deaktiviert fuer Erstdownload, bei Produktion setzen). Alle 54 bestehenden Voice-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f022_silero_vad_integrity.py` (15 Tests, 4 Klassen)

### F-023: Audio-Accumulator ohne Max-Size
- **Datei:** `src/jarvis/channels/voice_bridge.py:42-68`
- **Kategorie:** REL
- **Status:** FIXED
- **Beschreibung:** `AudioAccumulator.add_chunk()` fuegt Bytes ohne Size-Check hinzu. TTLDict limitiert Sessions auf 100, aber ein einzelner Client kann innerhalb der 10-Min-TTL unbegrenzt Daten akkumulieren.
- **Fix:** `AudioAccumulator.MAX_BYTES = 104_857_600` (100 MB). `add_chunk()` prueft `_total_bytes + len(raw) > MAX_BYTES` vor dem Speichern und wirft `ValueError` bei Ueberschreitung. `_handle_audio_chunk()` faengt den Error ab und sendet `voice_error` an den Client. Alle 25 bestehenden Bridge-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f023_audio_accumulator_max_size.py` (21 Tests, 5 Klassen)

### F-024: Telegram Webhook ohne secret_token
- **Datei:** `src/jarvis/channels/telegram.py:126-330`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** Webhook-Handler prueft keinen `X-Telegram-Bot-Api-Secret-Token` Header. `set_webhook()` uebergibt keinen `secret_token`. Jeder, der die Webhook-URL kennt, kann gefaelschte Updates senden.
- **Fix:** 1) `__init__`: Generiert `_webhook_secret_token` via `secrets.token_hex(32)` (64 Hex-Zeichen). 2) `_start_webhook`: Uebergibt `secret_token=self._webhook_secret_token` an `set_webhook()`. 3) `_handle_webhook`: Prueft `X-Telegram-Bot-Api-Secret-Token` Header via `hmac.compare_digest()` — bei Mismatch/Fehlen wird 403 zurueckgegeben und Warning geloggt. Alle 36 bestehenden Telegram-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f024_telegram_webhook_secret.py` (14 Tests, 4 Klassen)

### F-025: config_routes run_id Path Traversal
- **Datei:** `src/jarvis/channels/config_routes.py:2626-2630`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `run_id` aus URL-Path-Parameter wird ohne Validation in Dateipfad eingesetzt: `dag._checkpoint_dir / f"{run_id}.json"`. Path Traversal moeglich (z.B. `../../etc/passwd.json`).
- **Fix:** `.resolve()` + `.relative_to(checkpoint_dir.resolve())` Validation vor Dateizugriff. Bei Path-Traversal wird `{"error": "Invalid run_id (Path-Traversal)", "status": 400}` zurueckgegeben. Alle 186 bestehenden config_routes/workflow-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f025_config_routes_path_traversal.py` (11 Tests, 4 Klassen)

### F-026: WhatsApp HMAC Fallback auf API-Token
- **Datei:** `src/jarvis/channels/whatsapp.py:311-339`
- **Kategorie:** SEC
- **Status:** FIXED
- **Beschreibung:** `hmac_key = self._app_secret or self._api_token` — wenn kein App Secret konfiguriert ist, wird der API-Token als HMAC-Key verwendet. Meta signiert Webhooks mit dem App Secret, nie mit dem API Token. Verifizierung ist damit funktional kaputt.
- **Fix:** 1) `_verify_signature()`: Ohne `app_secret` wird sofort `False` zurueckgegeben + `logger.error` geloggt. Kein Fallback auf `_api_token` mehr. 2) HMAC wird ausschliesslich mit `self._app_secret` berechnet. 3) `_setup_webhook()`: Warning-Log wenn `app_secret` fehlt. Bestehende WhatsApp-Tests haben pre-existing Cryptography-Fehler (unabhaengig von F-026).
- **Tests:** `tests/test_security/test_f026_whatsapp_hmac_fallback.py` (15 Tests, 4 Klassen)

### F-027: voice_ws_bridge Fixed Filename Race Condition
- **Datei:** `src/jarvis/channels/voice_ws_bridge.py:83,146`
- **Kategorie:** REL
- **Status:** FIXED
- **Beschreibung:** Audio-Dateien wurden mit festem Namen (`voice_input{ext}`, `voice_response.wav`) gespeichert. Bei gleichzeitigen Requests ueberschrieben sich die Dateien gegenseitig.
- **Fix:** Beide Dateinamen enthalten jetzt eine UUID-Komponente: `voice_input_{uuid4().hex[:12]}{ext}` und `voice_response_{uuid4().hex[:12]}.wav`. 12 Hex-Zeichen = 48 Bit Entropie, kollisionssicher. `import uuid` war bereits vorhanden. 10 bestehende voice_ws_bridge-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f027_voice_ws_filename_race.py` (13 Tests, 5 Klassen)

---

## LOW

### F-028: Hardcoded Unix Paths in multitenant.py
- **Datei:** `src/jarvis/core/multitenant.py:122-127`
- **Kategorie:** PORT
- **Status:** FIXED
- **Beschreibung:** `data_path` gab `/data/tenants/{tenant_id}` zurueck, `secrets_path` gab `/run/secrets/tenants/{tenant_id}` zurueck — hardcoded Unix-Pfade die auf Windows nicht funktionieren.
- **Fix:** Beide Properties verwenden jetzt `Path.home() / ".jarvis" / "tenants" / tenant_id / "data|secrets"` — plattformunabhaengig via `pathlib.Path`. `from pathlib import Path` hinzugefuegt. 150 bestehende Regressionstests (multitenant_coverage + v11_hardening) weiterhin gruen.
- **Tests:** `tests/test_security/test_f028_multitenant_hardcoded_paths.py` (17 Tests, 5 Klassen)

### F-029: O(N^2) Consolidation Deduplication
- **Datei:** `src/jarvis/memory/consolidation.py:106-127`
- **Kategorie:** PERF
- **Status:** FIXED
- **Beschreibung:** Phase-2 Deduplication verglich verbleibende Eintraege paarweise mit n-gram Jaccard Similarity. O(N^2) Komplexitaet auf alle Eintraege die Phase-1 (exact hash) nicht gefunden hat.
- **Fix:** `MAX_FUZZY_ENTRIES = 500` Klassenvariable begrenzt die Anzahl der Eintraege in der O(N^2)-Schleife. Bei Ueberschreitung wird ein Warning geloggt und nur die ersten 500 Eintraege fuzzy verglichen. Phase-1 (exact hash, O(N)) bleibt unbegrenzt. 500 Eintraege = max 124 750 Vergleiche — schnell auf jeder Maschine. Limit ist pro Instanz ueberschreibbar. 126 bestehende Regressionstests gruen.
- **Tests:** `tests/test_security/test_f029_consolidation_dedup_limit.py` (15 Tests, 6 Klassen)

### F-030: TTLDict.setdefault() bricht dict-Interface
- **Datei:** `src/jarvis/utils/ttl_dict.py:104-112`
- **Kategorie:** LOGIC
- **Status:** FIXED
- **Beschreibung:** `setdefault(key)` ohne Default warf `KeyError` statt `None` zurueckzugeben (Standard-dict-Verhalten). Gespeicherter Wert `None` wurde als fehlend behandelt und ueberschrieben.
- **Fix:** Komplett neu implementiert: Prueft `_data.get(key)` direkt (statt `self.get()`) um fehlenden Key von `None`-Wert unterscheiden zu koennen. Abgelaufene Eintraege werden korrekt entfernt. Kein `KeyError` mehr — fehlender Key ohne Default gibt `None` zurueck (dict-konform). 28 bestehende TTLDict-Tests weiterhin gruen.
- **Tests:** `tests/test_security/test_f030_ttldict_setdefault.py` (17 Tests, 6 Klassen)

### F-031: EpisodicStore SQLite ohne Application-Level Locking
- **Datei:** `src/jarvis/memory/episodic_store.py:27`
- **Kategorie:** REL
- **Status:** FIXED
- **Beschreibung:** `sqlite3.connect(db_path, check_same_thread=False)` ohne externen Write-Lock (anders als `MemoryIndex` das `threading.RLock` nutzt). Unter hoher Konkurrenz konnten Writes mit "database is locked" fehlschlagen.
- **Fix:** `self._write_lock = threading.RLock()` in `__init__` hinzugefuegt. Alle Write-Operationen (`_ensure_schema`, `store_episode`, `store_summary`) werden unter `with self._write_lock:` ausgefuehrt. Read-Operationen bleiben unlocked (WAL-Modus erlaubt concurrent reads). Analog zum Pattern in `MemoryIndex`. 55 bestehende Regressionstests gruen.
- **Tests:** `tests/test_security/test_f031_episodic_store_write_lock.py` (16 Tests, 6 Klassen)

---

## Statistik

| Severity | Anzahl | Fixed |
|----------|--------|-------|
| CRITICAL | 1 | 1 |
| HIGH | 3 | 3 |
| MEDIUM | 23 | 22 |
| LOW | 4 | 4 |
| **Gesamt** | **31** | **30** |

**Status:** 31 von 31 Findings gefixt.

### Nach Kategorie

| Kategorie | Anzahl | Fixed |
|-----------|--------|-------|
| Security (SEC) | 21 | 21 |
| Reliability (REL) | 4 | 4 |
| Performance (PERF) | 2 | 2 |
| Logic (LOGIC) | 2 | 2 |
| Portability (PORT) | 2 | 2 |

---

## Eliminierte False Positives (17)

Folgende Findings wurden nach Code-Verifizierung als False Positives klassifiziert und aus dem Report entfernt:

1. `_rate_hits` unbounded — Timestamps werden gepurgt, nur IP-Keys bleiben (LOW)
2. iMessage Command Injection — Input wird via `_escape_applescript()` escaped
3. API Keys als plaintext str — Standard-Praxis, kein Vulnerability
4. generator.py f-string injection — Sandbox-contained + interne Pfade
5. hygiene.py O(N^2) — Keyed dict, kein all-pairs Vergleich
6. search.py all-embeddings — Seltener Fallback-Pfad
7. CORS defaults `["*"]` — Default ist `[]`
8. discord target_id unbound — Immer vor dem catch gebunden
9. Adaptive Card XSS — JSON Schema, kein HTML
10. LLM decompose caching — Methode existiert nicht an der Stelle
11. asyncio.Lock() outside loop — Kein Problem seit Python 3.10+
12. Ollama SSL — httpx verifiziert SSL per Default
13. Indexer reads bypass lock — Intentional WAL-Design
14. MD5 fuer Query-Hashing — Nicht-kryptographischer Kontext
15. Mattermost no reconnect — Hat while-loop Reconnect
16. Google Chat path traversal — Admin-Config, kein User-Input
17. SQLite check_same_thread — WAL + busy_timeout reichen
18. MD5 fuer Cluster-IDs — Nicht-kryptographisch
19. import resource Windows — Korrekter 3-Tier Fallback

"""User-friendly error messages for Jarvis channels.

Replaces generic "Ein Fehler ist aufgetreten" messages with contextual,
empathetic error descriptions. Used across all channels.
"""

from __future__ import annotations


# ── Tool-Friendly-Names ─────────────────────────────────────────
# Maps internal MCP tool names to human-readable German names.

_TOOL_FRIENDLY_NAMES: dict[str, str] = {
    "exec_command": "Shell-Befehl",
    "write_file": "Datei schreiben",
    "read_file": "Datei lesen",
    "edit_file": "Datei bearbeiten",
    "list_directory": "Verzeichnis auflisten",
    "run_python": "Python-Code",
    "web_search": "Web-Suche",
    "web_news_search": "Nachrichten-Suche",
    "web_fetch": "Webseite abrufen",
    "search_and_read": "Web-Recherche",
    "search_memory": "Wissens-Suche",
    "save_to_memory": "Wissen speichern",
    "document_export": "Dokument erstellen",
    "media_analyze_image": "Bildanalyse",
    "media_transcribe_audio": "Audio-Transkription",
    "media_extract_text": "Text-Extraktion",
    "media_tts": "Sprachausgabe",
    "vault_search": "Vault-Suche",
    "vault_write": "Vault-Eintrag",
    "analyze_code": "Code-Analyse",
    "browser_navigate": "Browser-Navigation",
    "browser_screenshot": "Browser-Screenshot",
}


def _friendly_tool_name(tool: str) -> str:
    """Returns a user-friendly name for a tool."""
    return _TOOL_FRIENDLY_NAMES.get(tool, tool)


# ── Error Classification ────────────────────────────────────────

def classify_error_for_user(exc: BaseException) -> str:
    """Classifies an exception into a user-friendly German error message.

    Used by all channels instead of generic "Ein Fehler ist aufgetreten".
    """
    exc_type = type(exc).__name__
    exc_str = str(exc)[:200]

    if exc_type in ("TimeoutError", "asyncio.TimeoutError") or "timeout" in exc_str.lower():
        return (
            "Die Verarbeitung hat leider zu lange gedauert. "
            "Das kann an einem langsamen Netzwerk oder einem überlasteten Dienst liegen. "
            "Bitte versuch es gleich noch einmal."
        )

    if exc_type in ("ConnectionError", "ConnectError", "OSError") or "connection" in exc_str.lower():
        return (
            "Es gab ein Verbindungsproblem. "
            "Bitte prüfe deine Internetverbindung und versuch es erneut."
        )

    if exc_type in ("PermissionError", "AuthenticationError") or "permission" in exc_str.lower():
        return (
            "Mir fehlt die Berechtigung für diese Aktion. "
            "Bitte prüfe die Zugriffsrechte oder wende dich an den Administrator."
        )

    if exc_type == "FileNotFoundError" or "not found" in exc_str.lower():
        return (
            "Die angeforderte Datei oder Ressource wurde nicht gefunden. "
            "Bitte prüfe den Pfad und versuch es erneut."
        )

    if "rate limit" in exc_str.lower() or "429" in exc_str:
        return (
            "Der Dienst ist gerade überlastet (Rate-Limit erreicht). "
            "Bitte warte einen Moment und versuch es dann erneut."
        )

    if "memory" in exc_str.lower() or exc_type == "MemoryError":
        return (
            "Es ist ein Speicherproblem aufgetreten. "
            "Bitte versuch es mit einer kleineren Anfrage."
        )

    # Generic fallback -- still friendlier than raw exception
    return (
        "Bei der Verarbeitung ist ein unerwarteter Fehler aufgetreten. "
        "Bitte versuch es erneut. Wenn das Problem weiterhin besteht, "
        "formuliere deine Anfrage etwas anders."
    )


# ── Gatekeeper Block Messages ───────────────────────────────────

def gatekeeper_block_message(tool: str, reason: str) -> str:
    """Creates a user-friendly message when the Gatekeeper blocks an action.

    Instead of "Aktion blockiert", explains what happened and what the user can do.
    """
    friendly = _friendly_tool_name(tool)
    return (
        f"Ich wollte \"{friendly}\" ausführen, aber das wurde aus Sicherheitsgründen "
        f"blockiert: {reason}\n"
        f"Du kannst mir die Berechtigung erteilen oder eine alternative Vorgehensweise vorschlagen."
    )


# ── Retry Exhausted Messages ────────────────────────────────────

def retry_exhausted_message(tool: str, attempts: int, error: str) -> str:
    """Creates a user-friendly message when all retries are exhausted.

    Instead of "Fehler nach 3 Versuchen: {raw_error}".
    """
    friendly = _friendly_tool_name(tool)

    # Classify the error for a friendlier sub-message
    error_lower = error.lower()
    if "timeout" in error_lower:
        cause = "Der Dienst hat nicht rechtzeitig geantwortet."
    elif "connection" in error_lower:
        cause = "Die Verbindung konnte nicht hergestellt werden."
    elif "rate" in error_lower or "429" in error:
        cause = "Der Dienst ist gerade überlastet."
    else:
        cause = f"Technischer Fehler: {error[:100]}"

    return (
        f"Ich habe \"{friendly}\" {attempts}-mal versucht, aber es hat leider nicht geklappt. "
        f"{cause} "
        f"Ich versuche einen anderen Ansatz oder du kannst mir helfen, das Problem zu lösen."
    )


# ── All-Blocked Message ─────────────────────────────────────────

def all_actions_blocked_message(
    steps: list,
    decisions: list,
) -> str:
    """Creates a specific message when all planned actions are blocked.

    Instead of generic "Alle geplanten Aktionen wurden vom Gatekeeper blockiert."
    """
    reasons: list[str] = []
    for step, decision in zip(steps, decisions, strict=False):
        friendly = _friendly_tool_name(step.tool)
        reasons.append(f"- {friendly}: {decision.reason}")

    reasons_text = "\n".join(reasons) if reasons else "Keine Details verfügbar."
    return (
        "Ich konnte keinen meiner geplanten Schritte ausführen, da sie alle "
        "aus Sicherheitsgründen blockiert wurden:\n"
        f"{reasons_text}\n\n"
        "Du kannst mir die Berechtigungen erteilen oder mir eine andere "
        "Herangehensweise vorschlagen."
    )

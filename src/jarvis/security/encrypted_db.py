"""Encrypted database connection wrapper.

Uses SQLCipher (pysqlcipher3) for encryption at rest if available.
Falls back to standard sqlite3 with a WARNING if not installed.

Key management:
- Primary: JARVIS_DB_KEY environment variable
- Fallback: auto-generated key stored in credential store
"""
from __future__ import annotations

import os
import sqlite3
from pathlib import Path
from typing import Any

from jarvis.utils.logging import get_logger

log = get_logger(__name__)

__all__ = ["encrypted_connect", "is_encryption_available"]

_sqlcipher_available = False
try:
    from pysqlcipher3 import dbapi2 as sqlcipher
    _sqlcipher_available = True
except ImportError:
    try:
        import sqlcipher3 as sqlcipher
        _sqlcipher_available = True
    except ImportError:
        sqlcipher = None


def is_encryption_available() -> bool:
    """Check if SQLCipher is available."""
    return _sqlcipher_available


def _get_db_key() -> str:
    """Get the database encryption key.

    Priority:
    1. JARVIS_DB_KEY environment variable
    2. Auto-generated key from credential store
    3. Empty string (triggers WARNING)
    """
    key = os.environ.get("JARVIS_DB_KEY", "")
    if key:
        return key

    # Try credential store
    try:
        from jarvis.security.credentials import CredentialStore
        store = CredentialStore()
        existing = store.retrieve("system", "db_encryption_key")
        if existing:
            return existing
        # Generate new key
        import secrets
        new_key = secrets.token_hex(32)
        store.store("system", "db_encryption_key", new_key)
        log.info("db_encryption_key_generated")
        return new_key
    except Exception:
        log.debug("credential_store_unavailable_for_db_key", exc_info=True)

    return ""


def encrypted_connect(
    db_path: str,
    key: str | None = None,
    check_same_thread: bool = False,
) -> sqlite3.Connection:
    """Open a database connection, encrypted if SQLCipher is available.

    Args:
        db_path: Path to the SQLite database file
        key: Encryption key. If None, auto-detected from env/credential store.
        check_same_thread: sqlite3 check_same_thread parameter

    Returns:
        sqlite3.Connection (either encrypted or standard)
    """
    if key is None:
        key = _get_db_key()

    if _sqlcipher_available and key:
        try:
            conn = sqlcipher.connect(db_path, check_same_thread=check_same_thread)
            # Use hex key format to prevent SQL injection from user-supplied keys
            hex_key = key.encode().hex()
            conn.execute(f"PRAGMA key = \"x'{hex_key}'\"")  # noqa: S608
            conn.execute("PRAGMA journal_mode=WAL")
            # Test that the key works
            conn.execute("SELECT count(*) FROM sqlite_master")
            log.debug("encrypted_db_opened", path=db_path[-30:])
            return conn
        except Exception as e:
            log.warning("sqlcipher_open_failed_falling_back", path=db_path[-30:], error=str(e)[:50])

    if _sqlcipher_available and not key:
        log.warning("sqlcipher_available_but_no_key", path=db_path[-30:],
                     hint="Set JARVIS_DB_KEY env var for encryption at rest")
    elif not _sqlcipher_available:
        log.warning("sqlcipher_not_installed",
                     hint="Install pysqlcipher3 for encryption at rest: pip install pysqlcipher3")

    # Fallback: standard sqlite3 (unencrypted)
    conn = sqlite3.connect(db_path, check_same_thread=check_same_thread)
    conn.execute("PRAGMA journal_mode=WAL")
    return conn

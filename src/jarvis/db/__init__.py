"""Jarvis · Database Abstraction Layer.

Unterstuetzt SQLite (Default) und PostgreSQL (Optional).
Optional: SQLCipher-Verschluesselung mit OS-Keyring.
"""

from jarvis.db.backend import DatabaseBackend
from jarvis.db.encryption import (
    get_encryption_key,
    init_encryption,
    open_sqlite,
    remove_encryption_key,
)
from jarvis.db.factory import create_backend

__all__ = [
    "DatabaseBackend",
    "create_backend",
    "get_encryption_key",
    "init_encryption",
    "open_sqlite",
    "remove_encryption_key",
]

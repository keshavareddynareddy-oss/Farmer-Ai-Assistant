from pathlib import Path
import sqlite3
import os

_configured_path = Path(os.environ.get("DATABASE_PATH", "crop_price.db"))
DB_PATH = _configured_path if _configured_path.is_absolute() else Path(__file__).resolve().parents[2] / _configured_path
DB_PATH.parent.mkdir(parents=True, exist_ok=True)


def get_connection() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH, timeout=30)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA journal_mode = WAL")
    connection.execute("PRAGMA synchronous = NORMAL")
    return connection

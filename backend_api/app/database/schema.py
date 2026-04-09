from app.database.db import get_connection


def create_tables() -> None:
    with get_connection() as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                password TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS crop_prices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                crop_id TEXT NOT NULL,
                crop_name TEXT NOT NULL,
                market TEXT NOT NULL,
                district TEXT DEFAULT '',
                state TEXT DEFAULT '',
                latitude REAL,
                longitude REAL,
                price REAL NOT NULL,
                recorded_on TEXT,
                source TEXT DEFAULT 'bootstrap'
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS dataset_sync_state (
                dataset_name TEXT PRIMARY KEY,
                last_synced_at TEXT,
                source TEXT,
                row_count INTEGER DEFAULT 0
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS price_alerts (
                id TEXT PRIMARY KEY,
                username TEXT NOT NULL,
                crop_id TEXT DEFAULT '',
                crop_name TEXT NOT NULL,
                market TEXT DEFAULT '',
                target_price REAL NOT NULL,
                is_above INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(username) REFERENCES users(username)
            )
            """
        )
        connection.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_price_alerts_username
            ON price_alerts(username)
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS crop_watch_profiles (
                id TEXT PRIMARY KEY,
                username TEXT NOT NULL,
                crop_id TEXT DEFAULT '',
                crop_name TEXT NOT NULL,
                sowing_date TEXT NOT NULL,
                expected_harvest_date TEXT DEFAULT '',
                market TEXT DEFAULT '',
                status TEXT DEFAULT 'growing',
                notes TEXT DEFAULT '',
                created_at TEXT NOT NULL,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(username) REFERENCES users(username)
            )
            """
        )
        connection.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_crop_watch_profiles_username
            ON crop_watch_profiles(username)
            """
        )

from __future__ import annotations

from app.database.db import get_connection


def _clean_username(username: str) -> str:
    return username.strip().lower()


def ensure_user(username: str, password: str) -> str:
    clean_username = _clean_username(username)
    clean_password = password.strip()

    if not clean_username or not clean_password:
        raise ValueError("Username and password are required")

    with get_connection() as connection:
        row = connection.execute(
            "SELECT username, password FROM users WHERE username = ?",
            (clean_username,),
        ).fetchone()

        if row is None:
            connection.execute(
                "INSERT INTO users(username, password) VALUES (?, ?)",
                (clean_username, clean_password),
            )
            return clean_username

        if row["password"] != clean_password:
            raise ValueError("Invalid username or password")

        connection.execute(
            "UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE username = ?",
            (clean_username,),
        )
        return clean_username


def register_user(username: str, password: str) -> str:
    clean_username = _clean_username(username)
    clean_password = password.strip()

    if not clean_username or not clean_password:
        raise ValueError("Username and password are required")

    with get_connection() as connection:
        row = connection.execute(
            "SELECT 1 FROM users WHERE username = ?",
            (clean_username,),
        ).fetchone()

        if row is not None:
            raise ValueError("Username already exists")

        connection.execute(
            "INSERT INTO users(username, password) VALUES (?, ?)",
            (clean_username, clean_password),
        )
        return clean_username


def user_exists(username: str) -> bool:
    clean_username = _clean_username(username)
    if not clean_username:
        return False

    with get_connection() as connection:
        row = connection.execute(
            "SELECT 1 FROM users WHERE username = ?",
            (clean_username,),
        ).fetchone()
        return row is not None


def sign_out_user(username: str) -> bool:
    return user_exists(username)

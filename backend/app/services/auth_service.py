from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import secrets
import time

from app.database.db import get_connection


_TOKEN_TTL_SECONDS = int(os.environ.get("AUTH_TOKEN_TTL_SECONDS", "86400"))
_TOKEN_SECRET = os.environ.get("AUTH_SECRET_KEY", "development-only-change-me")


def _password_hash(password: str, salt: bytes | None = None) -> str:
    salt = salt or secrets.token_bytes(16)
    digest = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=16384, r=8, p=1)
    encoded_salt = base64.urlsafe_b64encode(salt).decode("ascii")
    encoded_digest = base64.urlsafe_b64encode(digest).decode("ascii")
    return f"scrypt${encoded_salt}${encoded_digest}"


def _password_matches(password: str, stored_hash: str) -> bool:
    try:
        algorithm, encoded_salt, encoded_digest = stored_hash.split("$", 2)
        if algorithm != "scrypt":
            return False
        salt = base64.urlsafe_b64decode(encoded_salt.encode("ascii"))
        expected = base64.urlsafe_b64decode(encoded_digest.encode("ascii"))
        actual = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=16384, r=8, p=1)
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def _sign_token(payload: dict) -> str:
    encoded_payload = base64.urlsafe_b64encode(
        json.dumps(payload, separators=(",", ":")).encode("utf-8")
    ).decode("ascii").rstrip("=")
    signature = hmac.new(
        _TOKEN_SECRET.encode("utf-8"), encoded_payload.encode("ascii"), hashlib.sha256
    ).digest()
    encoded_signature = base64.urlsafe_b64encode(signature).decode("ascii").rstrip("=")
    return f"{encoded_payload}.{encoded_signature}"


def _decode_token(token: str) -> dict | None:
    try:
        encoded_payload, encoded_signature = token.split(".", 1)
        expected_signature = hmac.new(
            _TOKEN_SECRET.encode("utf-8"), encoded_payload.encode("ascii"), hashlib.sha256
        ).digest()
        actual_signature = base64.urlsafe_b64decode(encoded_signature + "===")
        if not hmac.compare_digest(actual_signature, expected_signature):
            return None
        payload = json.loads(
            base64.urlsafe_b64decode(encoded_payload + "===").decode("utf-8")
        )
        if int(payload.get("expires_at", 0)) < int(time.time()):
            return None
        return payload
    except (ValueError, TypeError, KeyError, json.JSONDecodeError):
        return None


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
                (clean_username, _password_hash(clean_password)),
            )
            return clean_username

        if not _password_matches(clean_password, row["password"]):
            if hmac.compare_digest(row["password"], clean_password):
                connection.execute(
                    "UPDATE users SET password = ?, updated_at = CURRENT_TIMESTAMP WHERE username = ?",
                    (_password_hash(clean_password), clean_username),
                )
            else:
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
            (clean_username, _password_hash(clean_password)),
        )
        return clean_username


def ensure_federated_user(username: str, provider_id: str) -> str:
    clean_username = _clean_username(username)
    if not clean_username or not provider_id.strip():
        raise ValueError("Federated user identity is required")

    with get_connection() as connection:
        connection.execute(
            "INSERT OR IGNORE INTO users(username, password) VALUES (?, ?)",
            (clean_username, f"firebase:{provider_id.strip()}"),
        )
    return clean_username


def create_token(username: str) -> str:
    return _sign_token(
        {
            "username": _clean_username(username),
            "expires_at": int(time.time()) + _TOKEN_TTL_SECONDS,
        }
    )


def username_from_token(token: str) -> str | None:
    payload = _decode_token(token)
    username = payload.get("username") if payload else None
    return username if isinstance(username, str) and user_exists(username) else None


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

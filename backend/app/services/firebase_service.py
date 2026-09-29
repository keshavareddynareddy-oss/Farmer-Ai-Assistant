from __future__ import annotations

import os

import firebase_admin
from firebase_admin import auth


def verify_firebase_id_token(token: str) -> dict:
    if not token.strip():
        raise ValueError("Firebase ID token is required")

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            options={"projectId": os.environ.get("FIREBASE_PROJECT_ID")}
        )

    return auth.verify_id_token(token)
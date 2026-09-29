from fastapi import Header, HTTPException

from app.services.auth_service import username_from_token


def current_username(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Authentication required")

    username = username_from_token(authorization.split(" ", 1)[1].strip())
    if not username:
        raise HTTPException(status_code=401, detail="Invalid or expired authentication token")
    return username
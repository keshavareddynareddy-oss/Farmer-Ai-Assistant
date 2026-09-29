from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.services.auth_service import (
    create_token,
    ensure_federated_user,
    ensure_user,
    register_user,
    sign_out_user,
    user_exists,
)
from app.services.firebase_service import verify_firebase_id_token
from app.api.auth_dependencies import current_username

router = APIRouter()


class SignInRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=120)
    password: str = Field(..., min_length=1, max_length=200)


class SignOutRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=120)


class FirebaseSessionRequest(BaseModel):
    id_token: str = Field(..., min_length=1)


@router.post("/auth/sign-in")
def sign_in(payload: SignInRequest) -> dict:
    try:
        username = ensure_user(payload.username, payload.password)
    except ValueError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error
    return {"ok": True, "username": username, "token": create_token(username)}


@router.post("/auth/register")
def register(payload: SignInRequest) -> dict:
    try:
        username = register_user(payload.username, payload.password)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    return {"ok": True, "username": username, "token": create_token(username)}


@router.post("/auth/firebase-session")
def firebase_session(payload: FirebaseSessionRequest) -> dict:
    try:
        claims = verify_firebase_id_token(payload.id_token)
        username = claims.get("email") or claims.get("uid")
        provider_id = claims.get("uid")
        if not username or not provider_id:
            raise ValueError("Firebase identity is incomplete")
        username = ensure_federated_user(username, provider_id)
    except Exception as error:
        raise HTTPException(status_code=401, detail="Invalid Firebase identity") from error

    return {"ok": True, "username": username, "token": create_token(username)}


@router.post("/auth/sign-out")
def sign_out(payload: SignOutRequest) -> dict:
    return {"ok": sign_out_user(payload.username)}


@router.get("/auth/session")
def auth_session(username: str = Depends(current_username)) -> dict:
    return {"exists": user_exists(username)}

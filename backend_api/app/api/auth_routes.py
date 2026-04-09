from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.auth_service import ensure_user, register_user, sign_out_user, user_exists

router = APIRouter()


class SignInRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=120)
    password: str = Field(..., min_length=1, max_length=200)


class SignOutRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=120)


@router.post("/auth/sign-in")
def sign_in(payload: SignInRequest) -> dict:
    username = ensure_user(payload.username, payload.password)
    return {"ok": True, "username": username}


@router.post("/auth/register")
def register(payload: SignInRequest) -> dict:
    username = register_user(payload.username, payload.password)
    return {"ok": True, "username": username}


@router.post("/auth/sign-out")
def sign_out(payload: SignOutRequest) -> dict:
    return {"ok": sign_out_user(payload.username)}


@router.get("/auth/session")
def auth_session(username: str) -> dict:
    return {"exists": user_exists(username)}

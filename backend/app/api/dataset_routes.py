import os
from hmac import compare_digest

from fastapi import APIRouter, Header, HTTPException

from app.services.data_service import get_dataset_sync_state, refresh_dataset_from_remote

router = APIRouter()


@router.get("/dataset/sync-state")
def dataset_sync_state() -> dict:
    return {"state": get_dataset_sync_state()}


@router.post("/dataset/refresh")
def dataset_refresh(x_admin_key: str | None = Header(default=None)) -> dict:
    """Force a refresh from the remote mandi API.

    Requires an admin key in production; local development may omit it.
    """
    required_key = os.environ.get("ADMIN_API_KEY")
    is_production = os.environ.get("APP_ENV", "development").lower() == "production"
    if is_production and not required_key:
        raise HTTPException(status_code=503, detail="Dataset refresh is not configured for production.")
    if required_key and not compare_digest(x_admin_key or "", required_key):
        raise HTTPException(status_code=401, detail="Unauthorized")

    return refresh_dataset_from_remote(force=True)


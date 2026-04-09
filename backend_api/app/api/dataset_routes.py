import os

from fastapi import APIRouter, Header, HTTPException

from app.services.data_service import get_dataset_sync_state, refresh_dataset_from_remote

router = APIRouter()


@router.get("/dataset/sync-state")
def dataset_sync_state() -> dict:
    return {"state": get_dataset_sync_state()}


@router.post("/dataset/refresh")
def dataset_refresh(x_admin_key: str | None = Header(default=None)) -> dict:
    """Force a refresh from the remote mandi API.

    Protects the endpoint with `ADMIN_API_KEY` when set.
    """
    required_key = os.environ.get("ADMIN_API_KEY")
    if required_key and x_admin_key != required_key:
        raise HTTPException(status_code=401, detail="Unauthorized")

    return refresh_dataset_from_remote(force=True)


from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.services.crop_watch_service import (
    get_crop_watch_overview,
    list_crop_watches,
    remove_crop_watch,
    upsert_crop_watch,
)

router = APIRouter()


class CropWatchRequest(BaseModel):
    id: str = Field(default="", max_length=120)
    username: str = Field(..., min_length=1, max_length=120)
    crop_id: str = Field(default="", max_length=120)
    crop_name: str = Field(..., min_length=1, max_length=160)
    sowing_date: str = Field(..., min_length=1, max_length=32)
    expected_harvest_date: str = Field(default="", max_length=32)
    market: str = Field(default="", max_length=160)
    status: str = Field(default="growing", max_length=40)
    notes: str = Field(default="", max_length=500)


@router.get("/crop-watch")
def get_crop_watch(username: str) -> list[dict]:
    return list_crop_watches(username)


@router.get("/crop-watch/overview")
def crop_watch_overview(
    username: str,
    latitude: float | None = Query(default=None, ge=-90, le=90),
    longitude: float | None = Query(default=None, ge=-180, le=180),
) -> dict:
    return get_crop_watch_overview(username=username, latitude=latitude, longitude=longitude)


@router.post("/crop-watch")
def save_crop_watch(payload: CropWatchRequest) -> dict:
    try:
        return upsert_crop_watch(
            username=payload.username,
            watch_id=payload.id,
            crop_id=payload.crop_id,
            crop_name=payload.crop_name,
            sowing_date=payload.sowing_date,
            expected_harvest_date=payload.expected_harvest_date,
            market=payload.market,
            status=payload.status,
            notes=payload.notes,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.delete("/crop-watch/{watch_id}")
def delete_crop_watch(watch_id: str, username: str) -> dict:
    deleted = remove_crop_watch(username=username, watch_id=watch_id)
    return {"deleted": deleted}
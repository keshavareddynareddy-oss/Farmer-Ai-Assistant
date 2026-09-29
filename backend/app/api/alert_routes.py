from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.services.alert_service import list_alerts, remove_alert, upsert_alert
from app.api.auth_dependencies import current_username

router = APIRouter()


class AlertRequest(BaseModel):
    id: str = Field(..., min_length=1, max_length=120)
    crop_id: str = Field(default="", max_length=120)
    crop_name: str = Field(..., min_length=1, max_length=160)
    market: str = Field(default="", max_length=160)
    target_price: float = Field(..., gt=0)
    is_above: bool
    created_at: str = Field(..., min_length=1, max_length=64)


@router.get("/alerts")
def get_alerts(username: str = Depends(current_username)) -> list[dict]:
    return list_alerts(username)


@router.post("/alerts")
def save_alert(payload: AlertRequest, username: str = Depends(current_username)) -> dict:
    try:
        return upsert_alert(
            username=username,
            alert_id=payload.id,
            crop_id=payload.crop_id,
            crop_name=payload.crop_name,
            market=payload.market,
            target_price=payload.target_price,
            is_above=payload.is_above,
            created_at=payload.created_at,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.delete("/alerts/{alert_id}")
def delete_alert(alert_id: str, username: str = Depends(current_username)) -> dict:
    deleted = remove_alert(username=username, alert_id=alert_id)
    return {"deleted": deleted}

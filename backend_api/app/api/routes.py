from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from app.ml.predict import MODEL_VERSION, _load_model
from app.services.dashboard_service import get_dashboard_overview
from app.services.data_service import get_available_crops, get_dataset_sync_state, get_selection_options
from app.services.recommendation_service import recommend_crops_for_soil

router = APIRouter()


class SoilRecommendationRequest(BaseModel):
    ph: float = Field(..., ge=0, le=14)
    nitrogen: float = Field(..., ge=0)
    phosphorus: float = Field(..., ge=0)
    potassium: float = Field(..., ge=0)
    moisture: float = Field(..., ge=0, le=100)
    organic_matter: float = Field(..., ge=0, le=100)


@router.get('/health')
def health_check() -> dict:
    return {'status': 'ok'}


@router.get('/model-status')
def model_status() -> dict:
    model = _load_model()
    return {
        'model_version': MODEL_VERSION,
        'model_loaded': model is not None,
        'dataset_sync_state': get_dataset_sync_state(),
    }


@router.get('/crops')
def list_crops() -> list[dict]:
    return get_available_crops()


@router.get('/dashboard-summary')
def dashboard_summary(
    latitude: float | None = Query(default=None, ge=-90, le=90),
    longitude: float | None = Query(default=None, ge=-180, le=180),
) -> dict:
    return get_dashboard_overview(latitude=latitude, longitude=longitude)


@router.get('/selection-options')
def selection_options(
    latitude: float | None = Query(default=None, ge=-90, le=90),
    longitude: float | None = Query(default=None, ge=-180, le=180),
    max_radius_km: float | None = Query(default=None, gt=0, le=500),
) -> dict:
    return get_selection_options(
        latitude=latitude,
        longitude=longitude,
        max_radius_km=max_radius_km,
    )


@router.post('/soil-recommendations')
def soil_recommendations(payload: SoilRecommendationRequest) -> dict:
    return recommend_crops_for_soil(
        ph=payload.ph,
        nitrogen=payload.nitrogen,
        phosphorus=payload.phosphorus,
        potassium=payload.potassium,
        moisture=payload.moisture,
        organic_matter=payload.organic_matter,
    )

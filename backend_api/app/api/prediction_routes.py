from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.prediction_service import (
    generate_nearby_market_predictions,
    generate_prediction,
)
from app.services.recommendation_service import best_sell_recommendation

router = APIRouter()


class PredictionRequest(BaseModel):
    crop_id: str = Field(..., min_length=1)
    market: str = Field(..., min_length=1)
    forecast_days: int = Field(7, ge=1, le=90)


class LocationPredictionRequest(BaseModel):
    crop_id: str = Field(..., min_length=1)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    forecast_days: int = Field(7, ge=1, le=90)
    max_radius_km: float | None = Field(None, gt=0)


@router.post('/predict')
def predict_price(payload: PredictionRequest) -> dict:
    try:
        prediction = generate_prediction(
            crop_id=payload.crop_id,
            market=payload.market,
            forecast_days=payload.forecast_days,
        )
        prediction['recommendation'] = best_sell_recommendation(prediction['forecast'])
        return prediction
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}") from e


@router.post('/predict/nearby')
def predict_nearby_price(payload: LocationPredictionRequest) -> dict:
    try:
        nearby = generate_nearby_market_predictions(
            crop_id=payload.crop_id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            forecast_days=payload.forecast_days,
            max_radius_km=payload.max_radius_km,
        )
        for market in nearby.get('nearest_markets', []):
            market['recommendation'] = best_sell_recommendation(market['forecast'])
        return nearby
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Nearby prediction failed: {str(e)}") from e


@router.post('/recommend/best-sell-time')
def recommend_best_sell_time(payload: PredictionRequest) -> dict:
    try:
        prediction = generate_prediction(
            crop_id=payload.crop_id,
            market=payload.market,
            forecast_days=payload.forecast_days,
        )
        return {
            'crop_name': prediction['crop_name'],
            'market': prediction['market'],
            'recommendation': best_sell_recommendation(prediction['forecast']),
            'forecast': prediction['forecast'],
            'model_version': prediction.get('model_version'),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recommendation failed: {str(e)}") from e

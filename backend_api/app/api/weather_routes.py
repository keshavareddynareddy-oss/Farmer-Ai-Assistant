from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from app.services.weather_service import get_current_weather, get_weather_forecast

router = APIRouter()


class WeatherRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    days: int = Field(7, ge=1, le=14)


@router.get('/weather/current')
def get_weather(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
) -> dict:
    weather = get_current_weather(latitude, longitude)
    if weather is None:
        return {"error": "Unable to fetch weather data"}
    return weather


@router.get('/weather/forecast')
def get_forecast(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    days: int = Query(7, ge=1, le=14),
) -> dict:
    forecast = get_weather_forecast(latitude, longitude, days)
    if forecast is None:
        return {"error": "Unable to fetch forecast data"}
    return forecast
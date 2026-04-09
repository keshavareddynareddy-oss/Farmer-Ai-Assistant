from datetime import date, timedelta
from pathlib import Path

import joblib
import pandas as pd

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "price_predictor.pkl"
MODEL_VERSION = "v1"

_MODEL = None


def _load_model():
    global _MODEL
    if _MODEL is not None:
        return _MODEL

    if not MODEL_PATH.exists():
        return None

    try:
        _MODEL = joblib.load(MODEL_PATH)
    except Exception:
        _MODEL = None

    return _MODEL


def _fallback_forecast(crop_id: str, current_price: float, forecast_days: int) -> list[dict]:
    base_price = current_price if current_price > 0 else 2000.0
    crop_factor = (sum(ord(char) for char in crop_id) % 9) + 1

    forecast = []
    for day in range(1, forecast_days + 1):
        trend = day * 12
        seasonal = ((day % 5) - 2) * crop_factor * 3
        forecast.append(
            {
                "day": day,
                "price": round(base_price + trend + seasonal, 2),
            }
        )

    return forecast


def forecast_prices(crop_id: str, current_price: float, forecast_days: int) -> list[dict]:
    model = _load_model()
    if model is None:
        return _fallback_forecast(crop_id, current_price, forecast_days)

    if current_price <= 0:
        current_price = 2000.0

    prediction_date = date.today()
    recent_prices = [current_price, current_price, current_price]
    forecast = []

    for day in range(1, forecast_days + 1):
        prediction_date += timedelta(days=1)
        features = {
            "month": prediction_date.month,
            "day_of_year": prediction_date.timetuple().tm_yday,
            "price_lag_1": recent_prices[-1],
            "price_rolling_mean_3": sum(recent_prices[-3:]) / 3.0,
        }

        predicted_price = float(model.predict(pd.DataFrame([features]))[0])
        predicted_price = max(0.0, predicted_price)
        predicted_price = round(predicted_price, 2)

        forecast.append({
            "day": day,
            "price": predicted_price,
        })
        recent_prices.append(predicted_price)

    return forecast

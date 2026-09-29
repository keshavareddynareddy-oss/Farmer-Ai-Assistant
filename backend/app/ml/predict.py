from datetime import date, timedelta
from pathlib import Path

import joblib
import pandas as pd

from app.ml.feature_engineering import PREDICTION_FEATURE_COLUMNS

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
        artifact = joblib.load(MODEL_PATH)
        if not isinstance(artifact, dict):
            return None
        evaluation = artifact.get("evaluation")
        model = artifact.get("model")
        if (
            not isinstance(evaluation, dict)
            or evaluation.get("model_mae", float("inf"))
            >= evaluation.get("persistence_mae", float("-inf"))
            or model is None
        ):
            return None
        _MODEL = model
    except Exception:
        _MODEL = None

    return _MODEL


def _fallback_forecast(crop_id: str, current_price: float, forecast_days: int) -> list[dict]:
    base_price = max(0.0, current_price)

    forecast = []
    for day in range(1, forecast_days + 1):
        forecast.append(
            {
                "day": day,
                "price": round(base_price, 2),
            }
        )

    return forecast


def forecast_prices(crop_id: str, current_price: float, forecast_days: int) -> list[dict]:
    model = _load_model()
    if model is None or current_price <= 0:
        return _fallback_forecast(crop_id, current_price, forecast_days)

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

        feature_frame = pd.DataFrame([
            {column: features[column] for column in PREDICTION_FEATURE_COLUMNS}
        ])
        predicted_price = float(model.predict(feature_frame)[0])
        predicted_price = max(0.0, predicted_price)
        predicted_price = round(predicted_price, 2)

        forecast.append({
            "day": day,
            "price": predicted_price,
        })
        recent_prices.append(predicted_price)

    return forecast

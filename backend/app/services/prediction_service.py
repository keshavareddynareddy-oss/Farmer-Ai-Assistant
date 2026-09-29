from app.ml.predict import MODEL_VERSION, _load_model, forecast_prices
from app.services.data_service import get_selection_options, load_dataset


def generate_prediction(crop_id: str, market: str, forecast_days: int) -> dict:
    frame = load_dataset()
    filtered_rows = frame

    if "crop_id" in frame.columns:
        filtered_rows = filtered_rows[filtered_rows["crop_id"] == crop_id]

    if "market" in filtered_rows.columns:
        filtered_rows = filtered_rows[filtered_rows["market"] == market]

    if "date" in filtered_rows.columns:
        filtered_rows = filtered_rows.sort_values("date")

    if filtered_rows.empty:
        crop_name = crop_id.replace("-", " ").title()
        current_price = 0.0
    else:
        crop_name = str(filtered_rows.iloc[0].get("crop_name", crop_id.title()))
        current_price = float(filtered_rows.iloc[-1].get("price", 0.0))

    forecast = forecast_prices(
        crop_id=crop_id,
        current_price=current_price,
        forecast_days=forecast_days,
    )

    return {
        "crop_name": crop_name,
        "market": market,
        "current_price": current_price,
        "forecast": forecast,
        "model_version": MODEL_VERSION,
        "prediction_source": "trained_model" if _load_model() is not None else "fallback_estimate",
    }


def generate_nearby_market_predictions(
    crop_id: str,
    latitude: float,
    longitude: float,
    forecast_days: int,
    max_radius_km: float | None = None,
) -> dict:
    options = get_selection_options(latitude=latitude, longitude=longitude, max_radius_km=max_radius_km)
    market_options = options.get("market_options", {}).get(crop_id, [])

    if not market_options:
        return {
            "crop_name": crop_id.replace("-", " ").title(),
            "crop_id": crop_id,
            "nearest_markets": [],
        }

    predictions = []
    for market_info in market_options:
        current_price = float(market_info.get("current_price", 0.0))
        market_name = str(market_info.get("market", ""))
        forecast = forecast_prices(
            crop_id=crop_id,
            current_price=current_price,
            forecast_days=forecast_days,
        )

        predictions.append(
            {
                "market": market_name,
                "current_price": current_price,
                "last_updated": market_info.get("last_updated"),
                "distance_km": market_info.get("distance_km"),
                "forecast": forecast,
                "model_version": MODEL_VERSION,
                "prediction_source": "trained_model" if _load_model() is not None else "fallback_estimate",
            }
        )

    crop_name = next(
        (crop["name"] for crop in options.get("crops", []) if crop.get("id") == crop_id),
        crop_id.replace("-", " ").title(),
    )

    return {
        "crop_name": crop_name,
        "crop_id": crop_id,
        "nearest_markets": predictions,
        "filters": options.get("filters", {}),
    }

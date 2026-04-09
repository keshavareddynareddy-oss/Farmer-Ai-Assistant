from __future__ import annotations

from datetime import datetime, timedelta

import pandas as pd
import requests

from app.services.data_service import load_dataset

OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

_WEATHER_CODE_LOOKUP = {
    0: ("Clear", "sunny"),
    1: ("Mostly Clear", "partly_cloudy"),
    2: ("Partly Cloudy", "partly_cloudy"),
    3: ("Overcast", "cloudy"),
    45: ("Fog", "fog"),
    48: ("Rime Fog", "fog"),
    51: ("Light Drizzle", "rain"),
    53: ("Drizzle", "rain"),
    55: ("Heavy Drizzle", "rain"),
    61: ("Light Rain", "rain"),
    63: ("Rain", "rain"),
    65: ("Heavy Rain", "rain"),
    71: ("Light Snow", "snow"),
    73: ("Snow", "snow"),
    75: ("Heavy Snow", "snow"),
    80: ("Rain Showers", "rain"),
    81: ("Heavy Showers", "rain"),
    82: ("Violent Showers", "rain"),
    95: ("Thunderstorm", "storm"),
    96: ("Storm and Hail", "storm"),
    99: ("Severe Storm", "storm"),
}


def _empty_summary() -> dict:
    return {
        "crops_tracked": 0,
        "markets_tracked": 0,
        "best_crop_name": "Unknown",
        "best_crop_id": "",
        "best_crop_price": 0.0,
        "latest_date": "",
    }


def _prepare_frame() -> pd.DataFrame:
    frame = load_dataset().copy()
    if frame.empty:
        return frame

    if "date" in frame.columns:
        frame["date"] = pd.to_datetime(frame["date"], errors="coerce")
        frame = frame.dropna(subset=["date"]).sort_values("date")

    frame["price"] = pd.to_numeric(frame.get("price"), errors="coerce")
    frame = frame.dropna(subset=["price"])
    return frame


def get_dashboard_summary(frame: pd.DataFrame | None = None) -> dict:
    working = frame.copy() if frame is not None else _prepare_frame()
    if working.empty:
        return _empty_summary()

    latest_rows = working.groupby(["crop_id", "crop_name", "market"], as_index=False).tail(1)
    crop_scores = (
        latest_rows.groupby(["crop_id", "crop_name"], as_index=False)["price"]
        .mean()
        .sort_values("price", ascending=False)
    )
    best_crop = crop_scores.iloc[0] if not crop_scores.empty else None

    latest_date = ""
    if "date" in working.columns and not working["date"].empty:
        latest_date = working["date"].max().strftime("%Y-%m-%d")

    return {
        "crops_tracked": int(working["crop_id"].nunique()) if "crop_id" in working.columns else 0,
        "markets_tracked": int(working["market"].nunique()) if "market" in working.columns else 0,
        "best_crop_name": str(best_crop["crop_name"]) if best_crop is not None else "Unknown",
        "best_crop_id": str(best_crop["crop_id"]) if best_crop is not None else "",
        "best_crop_price": float(best_crop["price"]) if best_crop is not None else 0.0,
        "latest_date": latest_date,
    }


def get_price_trend(frame: pd.DataFrame | None = None) -> dict:
    working = frame.copy() if frame is not None else _prepare_frame()
    if working.empty or "date" not in working.columns:
        return {"labels": [], "series": []}

    latest_rows = working.groupby(["crop_id", "crop_name", "market"], as_index=False).tail(1)
    top_crops = (
        latest_rows.groupby(["crop_id", "crop_name"], as_index=False)["price"]
        .mean()
        .sort_values("price", ascending=False)
        .head(3)
    )
    if top_crops.empty:
        return {"labels": [], "series": []}

    date_index = working[["date"]].drop_duplicates().sort_values("date").tail(6)
    labels = date_index["date"].dt.strftime("%b %d").tolist()
    selected_dates = date_index["date"].tolist()

    series = []
    for _, crop in top_crops.iterrows():
        crop_rows = working[
            (working["crop_id"] == crop["crop_id"]) & (working["date"].isin(selected_dates))
        ]
        grouped = crop_rows.groupby("date", as_index=False)["price"].mean().sort_values("date")
        value_map = {
            row["date"].strftime("%b %d"): round(float(row["price"]), 2)
            for _, row in grouped.iterrows()
        }
        series.append(
            {
                "crop_id": str(crop["crop_id"]),
                "crop_name": str(crop["crop_name"]),
                "points": [value_map.get(label, 0.0) for label in labels],
            }
        )

    return {"labels": labels, "series": series}


def _resolve_weather_location(
    frame: pd.DataFrame,
    latitude: float | None = None,
    longitude: float | None = None,
) -> tuple[float | None, float | None, str]:
    if latitude is not None and longitude is not None:
        return latitude, longitude, "user_location"

    if frame.empty:
        return None, None, "fallback"

    valid_locations = frame.dropna(subset=["latitude", "longitude"])
    if valid_locations.empty:
        return None, None, "fallback"

    latest_rows = valid_locations.groupby(["crop_id", "crop_name", "market"], as_index=False).tail(1)
    top_market = latest_rows.sort_values("price", ascending=False).iloc[0]
    return float(top_market["latitude"]), float(top_market["longitude"]), str(top_market["market"])


def _fallback_weather() -> list[dict]:
    today = datetime.now()
    defaults = [
        ("Sunny", "sunny", 31, 21),
        ("Cloudy", "cloudy", 29, 20),
        ("Rain", "rain", 27, 19),
        ("Windy", "wind", 28, 20),
        ("Partly Cloudy", "partly_cloudy", 30, 22),
    ]
    forecast = []
    for offset, (condition, icon_key, maximum, minimum) in enumerate(defaults):
        date = today + timedelta(days=offset)
        forecast.append(
            {
                "label": date.strftime("%a"),
                "condition": condition,
                "icon_key": icon_key,
                "temp_max_c": maximum,
                "temp_min_c": minimum,
            }
        )
    return forecast


def get_weather_forecast(
    latitude: float | None = None,
    longitude: float | None = None,
    frame: pd.DataFrame | None = None,
) -> dict:
    working = frame.copy() if frame is not None else _prepare_frame()
    resolved_latitude, resolved_longitude, source = _resolve_weather_location(
        working,
        latitude=latitude,
        longitude=longitude,
    )

    if resolved_latitude is None or resolved_longitude is None:
        return {"source": "fallback", "forecast": _fallback_weather()}

    params = {
        "latitude": resolved_latitude,
        "longitude": resolved_longitude,
        "daily": "weather_code,temperature_2m_max,temperature_2m_min",
        "forecast_days": 5,
        "timezone": "auto",
    }
    try:
        response = requests.get(OPEN_METEO_FORECAST_URL, params=params, timeout=10)
        response.raise_for_status()
        payload = response.json().get("daily", {})
        dates = payload.get("time", [])
        codes = payload.get("weather_code", [])
        highs = payload.get("temperature_2m_max", [])
        lows = payload.get("temperature_2m_min", [])
        forecast = []
        for index, raw_date in enumerate(dates[:5]):
            parsed_date = datetime.strptime(raw_date, "%Y-%m-%d")
            condition, icon_key = _WEATHER_CODE_LOOKUP.get(int(codes[index]), ("Weather", "cloudy"))
            forecast.append(
                {
                    "label": parsed_date.strftime("%a"),
                    "condition": condition,
                    "icon_key": icon_key,
                    "temp_max_c": int(round(float(highs[index]))),
                    "temp_min_c": int(round(float(lows[index]))),
                }
            )
        if forecast:
            return {"source": source, "forecast": forecast}
    except Exception:
        pass

    return {"source": "fallback", "forecast": _fallback_weather()}


def get_dashboard_overview(
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict:
    frame = _prepare_frame()
    summary = get_dashboard_summary(frame)
    summary["price_trend"] = get_price_trend(frame)
    summary["weather"] = get_weather_forecast(latitude=latitude, longitude=longitude, frame=frame)
    return summary

from __future__ import annotations

from datetime import date, datetime
from uuid import uuid4

from app.database.db import get_connection
from app.database.schema import create_tables
from app.services.data_service import get_selection_options
from app.services.dashboard_service import get_weather_forecast

_VALID_STATUSES = {"growing", "ready_to_sell", "sold"}


def _clean_username(username: str) -> str:
    return username.strip().lower()


def _clean_text(value: str | None) -> str:
    return str(value or "").strip()


def _parse_date(value: str | None) -> date | None:
    clean_value = _clean_text(value)
    if not clean_value:
        return None

    for parser in (date.fromisoformat,):
        try:
            return parser(clean_value)
        except ValueError:
            continue

    try:
        return datetime.strptime(clean_value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _stage_from_days(days_since_sowing: int | None, days_to_harvest: int | None, status: str) -> str:
    if status == "sold":
        return "sold"
    if status == "ready_to_sell" or (days_to_harvest is not None and days_to_harvest <= 0):
        return "ready_to_sell"
    if days_since_sowing is None:
        return "growing"
    if days_since_sowing < 14:
        return "early_growth"
    if days_since_sowing < 45:
        return "vegetative"
    if days_since_sowing < 75:
        return "flowering"
    return "pre_harvest"


def _stage_label(stage: str) -> str:
    return {
        "sold": "Sold",
        "ready_to_sell": "Ready to Sell",
        "early_growth": "Early Growth",
        "vegetative": "Vegetative Growth",
        "flowering": "Flowering / Grain Fill",
        "pre_harvest": "Pre-Harvest",
        "growing": "Growing",
    }.get(stage, "Growing")


def _stage_advisory(stage: str, crop_name: str) -> dict:
    crop_label = crop_name.strip() or "this crop"
    if stage == "sold":
        return {
            "title": "Crop monitoring complete",
            "summary": f"{crop_label} is marked as sold. Monitoring stops until you track a new crop.",
            "severity": "info",
            "action": "Track the next crop when you are ready.",
        }
    if stage == "ready_to_sell":
        return {
            "title": "Sell window is open",
            "summary": f"{crop_label} is ready for market comparison. Use the sell flow to check nearby mandis and current prices.",
            "severity": "high",
            "action": "Open the sell screen and compare markets now.",
        }
    if stage == "early_growth":
        return {
            "title": "Early growth update",
            "summary": f"{crop_label} is in an early growth phase. Keep soil moisture stable and avoid unnecessary stress.",
            "severity": "info",
            "action": "Monitor moisture and weed pressure.",
        }
    if stage == "vegetative":
        return {
            "title": "Vegetative growth update",
            "summary": f"{crop_label} is building canopy and roots. Balanced nutrition matters more than aggressive intervention.",
            "severity": "info",
            "action": "Check nutrition and irrigation timing.",
        }
    if stage == "flowering":
        return {
            "title": "Flowering / grain fill update",
            "summary": f"{crop_label} is at a sensitive stage where weather and water stress can affect yield.",
            "severity": "medium",
            "action": "Avoid water stress and watch the forecast daily.",
        }
    return {
        "title": "Pre-harvest update",
        "summary": f"{crop_label} is close to harvest. Start planning storage, labour, and market comparison.",
        "severity": "medium",
        "action": "Prepare harvest and sale planning.",
    }


def _weather_advisory(crop_name: str, latitude: float | None, longitude: float | None) -> dict:
    if latitude is None or longitude is None:
        return {
            "title": "Weather watch",
            "summary": f"No location is attached yet, so weather risk for {crop_name} cannot be checked automatically.",
            "severity": "info",
            "action": "Save a farm location to unlock weather advisories.",
        }

    forecast = get_weather_forecast(latitude=latitude, longitude=longitude)
    days = forecast.get("forecast", [])
    if not days:
        return {
            "title": "Weather watch",
            "summary": f"Weather data is unavailable right now for {crop_name}.",
            "severity": "info",
            "action": "Refresh later for the latest weather check.",
        }

    first_days = days[:3]
    rainy = any(str(day.get("icon_key", "")).lower() in {"rain", "storm"} for day in first_days)
    hot = max(int(day.get("temp_max_c", 0) or 0) for day in first_days)

    if rainy:
        return {
            "title": "Weather alert",
            "summary": f"Rain or storm conditions are expected soon, which may affect {crop_name} during the current growth stage.",
            "severity": "high",
            "action": "Review irrigation, drainage, and spray timing.",
        }

    if hot >= 35:
        return {
            "title": "Heat stress watch",
            "summary": f"Forecast temperatures are high enough to stress {crop_name} if moisture is low.",
            "severity": "medium",
            "action": "Check soil moisture and irrigation timing.",
        }

    return {
        "title": "Weather watch",
        "summary": f"The next few days look stable for {crop_name}. Keep watching changes as harvest approaches.",
        "severity": "info",
        "action": "Continue daily monitoring.",
    }


def _market_advisory(crop_id: str, crop_name: str, latitude: float | None, longitude: float | None) -> dict:
    options = get_selection_options(latitude=latitude, longitude=longitude, max_radius_km=200)
    resolved_crop_id = crop_id.strip()
    if not resolved_crop_id:
        resolved_crop_id = crop_name.strip().lower().replace(" ", "-")

    market_options = options.get("market_options", {}).get(resolved_crop_id, [])
    if not market_options:
        return {
            "title": "Market watch",
            "summary": f"No direct mandi match is available yet for {crop_name}. Use the sell flow to search more markets.",
            "severity": "info",
            "action": "Open the sell flow for market comparison.",
        }

    best_market = market_options[0]
    price = float(best_market.get("current_price", 0.0))
    market_name = str(best_market.get("market", ""))
    location_bits = [str(best_market.get("district", "") or ""), str(best_market.get("state", "") or "")]
    location = ", ".join(bit for bit in location_bits if bit)
    distance = best_market.get("distance_km")
    distance_text = f" about {distance:.1f} km away" if isinstance(distance, (int, float)) else ""

    return {
        "title": "Market watch",
        "summary": f"{market_name}{distance_text} is currently showing around Rs {price:.2f} for {crop_name}{(' in ' + location) if location else ''}.",
        "severity": "info",
        "action": "Compare this with nearby mandis before you sell.",
    }


def _load_rows(username: str) -> list[dict]:
    clean_username = _clean_username(username)
    if not clean_username:
        return []

    create_tables()
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT id, username, crop_id, crop_name, sowing_date, expected_harvest_date, market, status, notes, created_at, updated_at
            FROM crop_watch_profiles
            WHERE username = ?
            ORDER BY datetime(created_at) DESC
            """,
            (clean_username,),
        ).fetchall()

    return [dict(row) for row in rows]


def list_crop_watches(username: str) -> list[dict]:
    return _load_rows(username)


def upsert_crop_watch(
    *,
    username: str,
    watch_id: str,
    crop_id: str,
    crop_name: str,
    sowing_date: str,
    expected_harvest_date: str,
    market: str,
    status: str,
    notes: str,
) -> dict:
    clean_username = _clean_username(username)
    clean_watch_id = _clean_text(watch_id) or uuid4().hex
    clean_crop_name = _clean_text(crop_name)
    clean_sowing_date = _clean_text(sowing_date)
    clean_expected_harvest_date = _clean_text(expected_harvest_date)
    clean_market = _clean_text(market)
    clean_status = _clean_text(status).lower() or "growing"
    clean_notes = _clean_text(notes)

    if not clean_username:
        raise ValueError("Username is required")
    if not clean_crop_name:
        raise ValueError("Crop name is required")
    if _parse_date(clean_sowing_date) is None:
        raise ValueError("Sowing date must be a valid ISO date such as 2026-04-10")
    if clean_expected_harvest_date and _parse_date(clean_expected_harvest_date) is None:
        raise ValueError("Expected harvest date must be a valid ISO date")
    if clean_status not in _VALID_STATUSES:
        raise ValueError("Status must be growing, ready_to_sell, or sold")

    create_tables()
    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO crop_watch_profiles(
                id, username, crop_id, crop_name, sowing_date, expected_harvest_date, market, status, notes, created_at, updated_at
            )
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
                username = excluded.username,
                crop_id = excluded.crop_id,
                crop_name = excluded.crop_name,
                sowing_date = excluded.sowing_date,
                expected_harvest_date = excluded.expected_harvest_date,
                market = excluded.market,
                status = excluded.status,
                notes = excluded.notes,
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                clean_watch_id,
                clean_username,
                _clean_text(crop_id),
                clean_crop_name,
                clean_sowing_date,
                clean_expected_harvest_date,
                clean_market,
                clean_status,
                clean_notes,
            ),
        )

    rows = _load_rows(clean_username)
    return next((row for row in rows if row["id"] == clean_watch_id), rows[0] if rows else {})


def remove_crop_watch(username: str, watch_id: str) -> bool:
    clean_username = _clean_username(username)
    clean_watch_id = _clean_text(watch_id)
    if not clean_username or not clean_watch_id:
        return False

    create_tables()
    with get_connection() as connection:
        cursor = connection.execute(
            "DELETE FROM crop_watch_profiles WHERE username = ? AND id = ?",
            (clean_username, clean_watch_id),
        )
        return cursor.rowcount > 0


def get_crop_watch_overview(
    username: str,
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict:
    rows = _load_rows(username)
    today = date.today()
    watches: list[dict] = []

    for row in rows:
      sowing_date = _parse_date(row.get("sowing_date"))
      harvest_date = _parse_date(row.get("expected_harvest_date"))
      days_since_sowing = (today - sowing_date).days if sowing_date else None
      days_to_harvest = (harvest_date - today).days if harvest_date else None
      stage = _stage_from_days(days_since_sowing, days_to_harvest, str(row.get("status", "growing")))
      ready_to_sell = stage == "ready_to_sell"

      advisories = [
          _stage_advisory(stage, str(row.get("crop_name", ""))),
          _weather_advisory(str(row.get("crop_name", "")), latitude, longitude),
          _market_advisory(
              str(row.get("crop_id", "")),
              str(row.get("crop_name", "")),
              latitude,
              longitude,
          ),
      ]

      if ready_to_sell:
          advisories.append(
              {
                  "title": "Sell action ready",
                  "summary": "Open the sell flow to compare nearby mandis and decide when to sell.",
                  "severity": "high",
                  "action": "Use the price predictor and market comparison screen.",
              }
          )

      watches.append(
          {
              **row,
              "stage": stage,
              "stage_label": _stage_label(stage),
              "days_since_sowing": days_since_sowing,
              "days_to_harvest": days_to_harvest,
              "ready_to_sell": ready_to_sell,
              "advisories": advisories,
          }
      )

    return {
        "username": _clean_username(username),
        "watches": watches,
        "active_count": sum(1 for watch in watches if watch.get("status") != "sold"),
        "ready_to_sell_count": sum(1 for watch in watches if watch.get("ready_to_sell")),
    }
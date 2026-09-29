from math import asin, cos, radians, sin, sqrt
from pathlib import Path
from typing import Any
from io import StringIO
import json
import os
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

import pandas as pd
import requests

from app.database.db import get_connection
from app.database.schema import create_tables

DATASET_PATH = Path(__file__).resolve().parents[3] / "dataset" / "mandi_prices.csv"
MARKET_METADATA_PATH = Path(__file__).resolve().parents[3] / "dataset" / "market_locations.csv"
DATASET_NAME = "mandi_prices"

DEFAULT_MANDI_RESOURCE_ID = "9ef84268-d588-465a-a308-a864a43d0070"
MANDI_API_URL = os.environ.get("MANDI_API_URL")
MANDI_API_KEY = os.environ.get("MANDI_API_KEY")
MANDI_RESOURCE_ID = os.environ.get("MANDI_RESOURCE_ID", DEFAULT_MANDI_RESOURCE_ID)
MANDI_MAX_RECORDS = int(os.environ.get("MANDI_MAX_RECORDS", "10000"))
MANDI_PAGE_SIZE = int(os.environ.get("MANDI_PAGE_SIZE", "1000"))
MANDI_REFRESH_INTERVAL_HOURS = int(os.environ.get("MANDI_REFRESH_INTERVAL_HOURS", "24"))

DISTRICT_COLUMNS = ("district", "district_name")
STATE_COLUMNS = ("state", "state_name")
LATITUDE_COLUMNS = ("latitude", "lat", "market_latitude", "market_lat")
LONGITUDE_COLUMNS = ("longitude", "lon", "lng", "market_longitude", "market_lon", "market_lng")


def _distance_km(
    start_latitude: float,
    start_longitude: float,
    end_latitude: float,
    end_longitude: float,
) -> float:
    earth_radius_km = 6371.0
    delta_latitude = radians(end_latitude - start_latitude)
    delta_longitude = radians(end_longitude - start_longitude)
    start_latitude_radians = radians(start_latitude)
    end_latitude_radians = radians(end_latitude)

    haversine = (
        sin(delta_latitude / 2) ** 2
        + cos(start_latitude_radians)
        * cos(end_latitude_radians)
        * sin(delta_longitude / 2) ** 2
    )
    return 2 * earth_radius_km * asin(sqrt(haversine))


def _fallback_dataset() -> pd.DataFrame:
    return pd.DataFrame(
        [
            {
                "crop_id": "wheat",
                "crop_name": "Wheat",
                "market": "Delhi",
                "district": "New Delhi",
                "state": "Delhi",
                "latitude": 28.6139,
                "longitude": 77.2090,
                "price": 2450,
                "date": "2025-12-15",
            },
            {
                "crop_id": "rice",
                "crop_name": "Rice",
                "market": "Lucknow",
                "district": "Lucknow",
                "state": "Uttar Pradesh",
                "latitude": 26.8467,
                "longitude": 80.9462,
                "price": 3100,
                "date": "2025-12-15",
            },
            {
                "crop_id": "maize",
                "crop_name": "Maize",
                "market": "Indore",
                "district": "Indore",
                "state": "Madhya Pradesh",
                "latitude": 22.7196,
                "longitude": 75.8577,
                "price": 2100,
                "date": "2025-12-15",
            },
        ]
    )


def _first_available_column(frame: pd.DataFrame, candidates: tuple[str, ...]) -> pd.Series:
    for column in candidates:
        if column in frame.columns:
            return frame[column]
    return pd.Series([None] * len(frame), index=frame.index)


def _clean_text_series(series: pd.Series) -> pd.Series:
    cleaned = series.fillna("").astype(str).str.strip()
    return cleaned.replace({"nan": "", "None": "", "null": ""})


def _build_mandi_request_url(*, limit: int | None = None, offset: int = 0) -> str:
    if MANDI_API_URL:
        return MANDI_API_URL

    if not (MANDI_RESOURCE_ID and MANDI_API_KEY):
        raise RuntimeError(
            "MANDI_RESOURCE_ID and MANDI_API_KEY must be configured to fetch mandi data."
        )

    base_url = f"https://api.data.gov.in/resource/{MANDI_RESOURCE_ID}"
    query = urlencode(
        {
            "api-key": MANDI_API_KEY,
            "format": "json",
            "limit": limit if limit is not None else MANDI_MAX_RECORDS,
            "offset": offset,
            "sort[arrival_date]": "desc",
        }
    )
    return f"{base_url}?{query}"


def _normalise_remote_payload_to_frame(payload: dict[str, Any] | list[dict[str, Any]]) -> pd.DataFrame:
    if isinstance(payload, list):
        payload = {"records": payload}
    records = payload.get("records") or payload.get("data") or []
    if not records:
        return _fallback_dataset()

    frame = pd.DataFrame(records)

    if "commodity" in frame.columns:
        frame["crop_name"] = _clean_text_series(frame["commodity"])
    elif "crop_name" in frame.columns:
        frame["crop_name"] = _clean_text_series(frame["crop_name"])
    else:
        frame["crop_name"] = _clean_text_series(_first_available_column(frame, ("commodity_name",)))

    frame["crop_id"] = (
        frame["crop_name"]
        .str.lower()
        .str.replace(r"[^a-z0-9]+", "-", regex=True)
        .str.strip("-")
    )

    if "market" in frame.columns:
        frame["market"] = _clean_text_series(frame["market"])
    elif "market_name" in frame.columns:
        frame["market"] = _clean_text_series(frame["market_name"])
    else:
        frame["market"] = _clean_text_series(_first_available_column(frame, ("market",)))

    if "modal_price" in frame.columns:
        frame["price"] = pd.to_numeric(frame["modal_price"], errors="coerce")
    elif "price" in frame.columns:
        frame["price"] = pd.to_numeric(frame["price"], errors="coerce")
    else:
        frame["price"] = pd.Series([None] * len(frame), index=frame.index)

    if "arrival_date" in frame.columns:
        frame["date"] = _clean_text_series(frame["arrival_date"])
    elif "report_date" in frame.columns:
        frame["date"] = _clean_text_series(frame["report_date"])
    else:
        frame["date"] = ""

    frame["district"] = _clean_text_series(_first_available_column(frame, DISTRICT_COLUMNS))
    frame["state"] = _clean_text_series(_first_available_column(frame, STATE_COLUMNS))
    frame["latitude"] = pd.to_numeric(_first_available_column(frame, LATITUDE_COLUMNS), errors="coerce")
    frame["longitude"] = pd.to_numeric(_first_available_column(frame, LONGITUDE_COLUMNS), errors="coerce")

    clean_frame = frame[
        [
            "crop_id",
            "crop_name",
            "market",
            "district",
            "state",
            "latitude",
            "longitude",
            "price",
            "date",
        ]
    ].dropna(subset=["crop_id", "market", "price"])

    clean_frame = clean_frame[(clean_frame["crop_id"] != "") & (clean_frame["market"] != "")]
    return clean_frame if not clean_frame.empty else _fallback_dataset()


def _load_bootstrap_csv() -> pd.DataFrame:
    if not DATASET_PATH.exists():
        return _fallback_dataset()

    try:
        frame = pd.read_csv(DATASET_PATH)
    except Exception:
        return _fallback_dataset()

    if "district" not in frame.columns:
        frame["district"] = ""
    if "state" not in frame.columns:
        frame["state"] = ""
    if "latitude" not in frame.columns:
        frame["latitude"] = pd.NA
    if "longitude" not in frame.columns:
        frame["longitude"] = pd.NA
    if "date" not in frame.columns:
        frame["date"] = ""

    frame["crop_id"] = _clean_text_series(frame["crop_id"])
    frame["crop_name"] = _clean_text_series(frame["crop_name"])
    frame["market"] = _clean_text_series(frame["market"])
    frame["district"] = _clean_text_series(frame["district"])
    frame["state"] = _clean_text_series(frame["state"])
    frame["latitude"] = pd.to_numeric(frame["latitude"], errors="coerce")
    frame["longitude"] = pd.to_numeric(frame["longitude"], errors="coerce")
    frame["price"] = pd.to_numeric(frame["price"], errors="coerce")
    frame["date"] = _clean_text_series(frame["date"])

    frame = frame[
        [
            "crop_id",
            "crop_name",
            "market",
            "district",
            "state",
            "latitude",
            "longitude",
            "price",
            "date",
        ]
    ].dropna(subset=["crop_id", "market", "price"])
    return frame if not frame.empty else _fallback_dataset()


def _load_market_metadata() -> pd.DataFrame | None:
    if not MARKET_METADATA_PATH.exists():
        return None

    try:
        metadata = pd.read_csv(MARKET_METADATA_PATH)
    except Exception:
        return None

    if "market" not in metadata.columns:
        return None

    metadata = metadata.copy()
    metadata["market"] = _clean_text_series(metadata["market"])
    metadata["district"] = _clean_text_series(
        metadata["district"] if "district" in metadata.columns else pd.Series([""] * len(metadata))
    )
    metadata["state"] = _clean_text_series(
        metadata["state"] if "state" in metadata.columns else pd.Series([""] * len(metadata))
    )
    metadata["latitude"] = pd.to_numeric(
        metadata["latitude"] if "latitude" in metadata.columns else pd.Series([None] * len(metadata)),
        errors="coerce",
    )
    metadata["longitude"] = pd.to_numeric(
        metadata["longitude"] if "longitude" in metadata.columns else pd.Series([None] * len(metadata)),
        errors="coerce",
    )
    return metadata[["market", "district", "state", "latitude", "longitude"]].drop_duplicates()


def _merge_market_metadata(frame: pd.DataFrame) -> pd.DataFrame:
    metadata = _load_market_metadata()
    if metadata is None or metadata.empty:
        return frame

    merged = frame.merge(metadata, on="market", how="left", suffixes=("", "_meta"))
    for column in ("district", "state"):
        merged[column] = _clean_text_series(merged[column])
        merged[column] = merged[column].where(merged[column] != "", merged[f"{column}_meta"])
        merged[column] = _clean_text_series(merged[column])
    for column in ("latitude", "longitude"):
        merged[column] = pd.to_numeric(merged[column], errors="coerce")
        merged[column] = merged[column].fillna(merged[f"{column}_meta"])
        merged[column] = pd.to_numeric(merged[column], errors="coerce")
    return merged.drop(columns=["district_meta", "state_meta", "latitude_meta", "longitude_meta"])


def _replace_dataset_in_db(frame: pd.DataFrame, source: str) -> None:
    create_tables()
    frame = _merge_market_metadata(frame.copy())
    frame["recorded_on"] = frame["date"]
    frame["source"] = source
    rows = frame[
        [
            "crop_id",
            "crop_name",
            "market",
            "district",
            "state",
            "latitude",
            "longitude",
            "price",
            "recorded_on",
            "source",
        ]
    ].copy()

    with get_connection() as connection:
        connection.execute("DELETE FROM crop_prices")
        rows.to_sql("crop_prices", connection, if_exists="append", index=False)
        connection.execute(
            """
            INSERT INTO dataset_sync_state(dataset_name, last_synced_at, source, row_count)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(dataset_name) DO UPDATE SET
                last_synced_at=excluded.last_synced_at,
                source=excluded.source,
                row_count=excluded.row_count
            """,
            (
                DATASET_NAME,
                datetime.now(timezone.utc).isoformat(),
                source,
                int(len(rows)),
            ),
        )


def _get_sync_state() -> dict | None:
    create_tables()
    with get_connection() as connection:
        row = connection.execute(
            "SELECT dataset_name, last_synced_at, source, row_count FROM dataset_sync_state WHERE dataset_name = ?",
            (DATASET_NAME,),
        ).fetchone()
    return dict(row) if row else None


def _db_has_rows() -> bool:
    create_tables()
    with get_connection() as connection:
        row = connection.execute("SELECT COUNT(*) AS count FROM crop_prices").fetchone()
    return bool(row["count"])


def _should_refresh_from_remote() -> bool:
    if not (MANDI_API_URL or (MANDI_RESOURCE_ID and MANDI_API_KEY)):
        return False

    state = _get_sync_state()
    if not state or not state.get("last_synced_at"):
        return True

    try:
        last_synced = datetime.fromisoformat(str(state["last_synced_at"]))
    except ValueError:
        return True

    return datetime.now(timezone.utc) - last_synced > timedelta(hours=MANDI_REFRESH_INTERVAL_HOURS)


def _fetch_mandi_api_records() -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    offset = 0

    while offset < MANDI_MAX_RECORDS:
        limit = min(MANDI_PAGE_SIZE, MANDI_MAX_RECORDS - offset)
        response = requests.get(
            _build_mandi_request_url(limit=limit, offset=offset),
            timeout=30,
        )
        response.raise_for_status()
        try:
            payload = response.json()
        except (ValueError, json.JSONDecodeError) as error:
            raise RuntimeError(f"Failed to decode mandi API response: {error}") from error

        if isinstance(payload, list):
            page_records = payload
            total = None
        elif isinstance(payload, dict):
            page_records = payload.get("records") or payload.get("data") or []
            try:
                total = int(payload["total"]) if payload.get("total") is not None else None
            except (TypeError, ValueError):
                total = None
        else:
            raise RuntimeError("Mandi response must be a JSON object or array of records.")

        if not isinstance(page_records, list):
            raise RuntimeError("Mandi response records must be an array.")
        if not page_records:
            break

        records.extend(page_records)
        offset += len(page_records)

        if (total is not None and offset >= total) or len(page_records) < limit:
            break

    return records


def _refresh_dataset_from_remote() -> None:
    if not MANDI_API_URL:
        records = _fetch_mandi_api_records()
        if not records:
            raise RuntimeError("Mandi API returned no records.")
        frame = _normalise_remote_payload_to_frame(records)
        _replace_dataset_in_db(frame, source="remote_api")
        return

    url = _build_mandi_request_url()
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    content_type = response.headers.get("content-type", "").lower()
    if "csv" in content_type or url.lower().split("?", 1)[0].endswith(".csv"):
        try:
            frame = _normalise_remote_payload_to_frame(
                {"records": pd.read_csv(StringIO(response.text)).to_dict("records")}
            )
        except Exception as error:
            raise RuntimeError(f"Failed to decode mandi CSV response: {error}") from error
    else:
        try:
            payload = response.json()
        except (ValueError, json.JSONDecodeError) as error:
            raise RuntimeError(f"Failed to decode mandi API response: {error}") from error
        if isinstance(payload, list):
            payload = {"records": payload}
        if not isinstance(payload, dict):
            raise RuntimeError("Mandi response must be a JSON object or array of records.")
        frame = _normalise_remote_payload_to_frame(payload)
    _replace_dataset_in_db(frame, source="remote_api")


def _bootstrap_dataset_if_needed() -> None:
    if _db_has_rows():
        return
    _replace_dataset_in_db(_load_bootstrap_csv(), source="bootstrap_csv")


def _ensure_dataset_ready() -> None:
    create_tables()
    _bootstrap_dataset_if_needed()
    if _should_refresh_from_remote():
        try:
            _refresh_dataset_from_remote()
        except Exception:
            pass


def get_dataset_sync_state() -> dict | None:
    """Return the last known dataset sync state from the local DB."""
    return _get_sync_state()


def refresh_dataset_from_remote(*, force: bool = False) -> dict:
    """Refresh local dataset from the official mandi API (data.gov.in) when configured.

    Returns a small status dict suitable for API responses/logging.
    """
    if not (MANDI_API_URL or (MANDI_RESOURCE_ID and MANDI_API_KEY)):
        return {
            "ok": False,
            "refreshed": False,
            "error": "MANDI sync is not configured. Set MANDI_API_URL or (MANDI_RESOURCE_ID and MANDI_API_KEY).",
            "state": _get_sync_state(),
        }

    if not force and not _should_refresh_from_remote():
        return {
            "ok": True,
            "refreshed": False,
            "state": _get_sync_state(),
        }

    try:
        _refresh_dataset_from_remote()
    except Exception as error:
        return {
            "ok": False,
            "refreshed": False,
            "error": str(error),
            "state": _get_sync_state(),
        }

    return {
        "ok": True,
        "refreshed": True,
        "state": _get_sync_state(),
    }


def load_dataset() -> pd.DataFrame:
    _ensure_dataset_ready()
    with get_connection() as connection:
        frame = pd.read_sql_query(
            """
            SELECT crop_id, crop_name, market, district, state, latitude, longitude, price, recorded_on AS date
            FROM crop_prices
            """,
            connection,
        )

    if frame.empty:
        frame = _fallback_dataset()

    frame["district"] = _clean_text_series(frame["district"])
    frame["state"] = _clean_text_series(frame["state"])
    frame["latitude"] = pd.to_numeric(frame["latitude"], errors="coerce")
    frame["longitude"] = pd.to_numeric(frame["longitude"], errors="coerce")
    frame["price"] = pd.to_numeric(frame["price"], errors="coerce")
    frame["date"] = _clean_text_series(frame["date"])
    return frame


def get_selection_options(
    latitude: float | None = None,
    longitude: float | None = None,
    max_radius_km: float | None = None,
) -> dict:
    frame = load_dataset()
    required_columns = {"crop_id", "crop_name", "market"}

    if not required_columns.issubset(frame.columns):
        frame = _fallback_dataset().copy()

    clean_frame = frame[["crop_id", "crop_name", "market"]].dropna().copy()
    clean_frame["crop_id"] = clean_frame["crop_id"].astype(str)
    clean_frame["crop_name"] = clean_frame["crop_name"].astype(str)
    clean_frame["market"] = clean_frame["market"].astype(str)

    latest_prices = frame.copy()
    if "date" in latest_prices.columns:
        latest_prices = latest_prices.sort_values("date")

    latest_prices = latest_prices.dropna(subset=["crop_id", "market"]).copy()
    latest_prices["crop_id"] = latest_prices["crop_id"].astype(str)
    latest_prices["market"] = latest_prices["market"].astype(str)
    latest_prices["district"] = _clean_text_series(latest_prices["district"])
    latest_prices["state"] = _clean_text_series(latest_prices["state"])
    latest_prices["latitude"] = pd.to_numeric(latest_prices["latitude"], errors="coerce")
    latest_prices["longitude"] = pd.to_numeric(latest_prices["longitude"], errors="coerce")

    crops = (
        clean_frame[["crop_id", "crop_name"]]
        .drop_duplicates()
        .sort_values(by=["crop_name", "crop_id"])
    )
    market_options: dict[str, list[dict]] = {}
    market_metadata: dict[str, dict[str, float | str | None]] = {}

    grouped_latest_prices = (
        latest_prices.groupby(["crop_id", "market", "district", "state"], dropna=False, as_index=False)
        .tail(1)
        .sort_values(by=["crop_id", "market", "district", "state"])
    )

    for crop_id, group in grouped_latest_prices.groupby("crop_id"):
        crop_market_options: list[dict] = []
        for _, row in group.iterrows():
            market_name = str(row["market"])
            district = str(row.get("district", "") or "")
            state = str(row.get("state", "") or "")
            row_latitude = row.get("latitude")
            row_longitude = row.get("longitude")
            market_latitude = None if pd.isna(row_latitude) else float(row_latitude)
            market_longitude = None if pd.isna(row_longitude) else float(row_longitude)
            distance_km = None

            if (
                latitude is not None
                and longitude is not None
                and market_latitude is not None
                and market_longitude is not None
            ):
                distance_km = round(
                    _distance_km(latitude, longitude, market_latitude, market_longitude),
                    1,
                )

            if (
                max_radius_km is not None
                and distance_km is not None
                and distance_km > max_radius_km
            ):
                continue

            market_key = " | ".join(part for part in [market_name, district, state] if part)
            market_option = {
                "market": market_name,
                "current_price": float(row.get("price", 0.0)),
                "last_updated": str(row.get("date", "")),
                "latitude": market_latitude,
                "longitude": market_longitude,
                "district": district,
                "state": state,
                "distance_km": distance_km,
            }
            crop_market_options.append(market_option)
            market_metadata[market_key] = {
                "market": market_name,
                "district": district,
                "state": state,
                "latitude": market_latitude,
                "longitude": market_longitude,
            }

        crop_market_options.sort(
            key=lambda option: (
                option["distance_km"] is None,
                option["distance_km"] if option["distance_km"] is not None else 0,
                option["state"],
                option["district"],
                option["market"],
            )
        )
        market_options[str(crop_id)] = crop_market_options

    return {
        "crops": [
            {"id": row["crop_id"], "name": row["crop_name"]}
            for _, row in crops.iterrows()
        ],
        "market_options": market_options,
        "market_metadata": market_metadata,
        "filters": {
            "latitude": latitude,
            "longitude": longitude,
            "max_radius_km": max_radius_km,
        },
    }


def get_available_crops() -> list[dict]:
    options = get_selection_options()
    market_options = options["market_options"]
    return [
        {
            "id": crop["id"],
            "name": crop["name"],
            "market": market_options.get(crop["id"], [{"market": "Unknown"}])[0]["market"],
        }
        for crop in options["crops"]
    ]

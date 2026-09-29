import os
import asyncio
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

if os.environ.get("APP_ENV", "development").lower() == "production":
    auth_secret = os.environ.get("AUTH_SECRET_KEY", "")
    if len(auth_secret) < 32 or auth_secret == "development-only-change-me":
        raise RuntimeError("AUTH_SECRET_KEY must be a long random value in production")
    required_settings = (
        "ADMIN_API_KEY",
        "DATABASE_PATH",
        "FIREBASE_PROJECT_ID",
        "OPENWEATHER_API_KEY",
    )
    missing_settings = [name for name in required_settings if not os.environ.get(name)]
    if missing_settings:
        raise RuntimeError(
            "Missing required production settings: " + ", ".join(missing_settings)
        )
    if not (os.environ.get("MANDI_API_URL") or os.environ.get("MANDI_API_KEY")):
        raise RuntimeError("MANDI_API_KEY or MANDI_API_URL is required in production")
    if os.environ.get("ALLOW_MOCK_WEATHER", "false").lower() in {"1", "true", "yes"}:
        raise RuntimeError("ALLOW_MOCK_WEATHER must be false in production")
    if os.environ.get("GEMINI_REQUIRED", "false").lower() in {"1", "true", "yes"} and not os.environ.get(
        "GOOGLE_GEMINI_API_KEY"
    ):
        raise RuntimeError("GOOGLE_GEMINI_API_KEY is required when GEMINI_REQUIRED is enabled")

from app.api.chat_routes import router as chat_router
from app.api.dataset_routes import router as dataset_router
from app.api.crop_watch_routes import router as crop_watch_router
from app.api.routes import router as base_router
from app.api.prediction_routes import router as prediction_router
from app.api.weather_routes import router as weather_router
from app.api.auth_routes import router as auth_router
from app.api.alert_routes import router as alert_router
from app.database.schema import create_tables
from app.services.data_service import (
    MANDI_API_KEY,
    MANDI_REFRESH_INTERVAL_HOURS,
    refresh_dataset_from_remote,
)

app = FastAPI(title="Crop Price Predictor API", version="0.1.0")

create_tables()


def _parse_cors_origins(value: str | None) -> list[str]:
    if not value:
        return []
    return [part.strip() for part in value.split(",") if part.strip()]


cors_allow_origins = _parse_cors_origins(os.environ.get("CORS_ALLOW_ORIGINS"))
cors_allow_origin_regex = os.environ.get("CORS_ALLOW_ORIGIN_REGEX")
cors_allow_credentials = os.environ.get("CORS_ALLOW_CREDENTIALS", "false").lower() in {
    "1",
    "true",
    "yes",
}

# Default to localhost-only (any port) for dev.
if not cors_allow_origins and not cors_allow_origin_regex:
    if os.environ.get("APP_ENV", "development").lower() == "production":
        raise RuntimeError("Configure CORS_ALLOW_ORIGINS or CORS_ALLOW_ORIGIN_REGEX in production")
    cors_allow_origin_regex = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_allow_origins,
    allow_origin_regex=cors_allow_origin_regex,
    allow_credentials=cors_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(base_router, prefix="/api")
app.include_router(prediction_router, prefix="/api")
app.include_router(chat_router, prefix="/api")
app.include_router(weather_router, prefix="/api")
app.include_router(dataset_router, prefix="/api")
app.include_router(crop_watch_router, prefix="/api")
app.include_router(auth_router, prefix="/api")
app.include_router(alert_router, prefix="/api")


logger = logging.getLogger("app.mandi_sync")


async def _mandi_sync_loop() -> None:
    enabled = os.environ.get("MANDI_SYNC_ENABLED", "true").lower() in {"1", "true", "yes"}
    if not enabled:
        logger.info("MANDI sync disabled (MANDI_SYNC_ENABLED=false).")
        return

    has_mandi_config = bool(
        os.environ.get("MANDI_API_URL")
        or MANDI_API_KEY
    )
    if not has_mandi_config:
        logger.info(
            "MANDI sync skipped (missing API key). Set MANDI_API_KEY or configure MANDI_API_URL."
        )
        return

    interval_seconds = max(1, int(MANDI_REFRESH_INTERVAL_HOURS)) * 60 * 60
    logger.info("Starting mandi sync loop (interval=%ss).", interval_seconds)

    while True:
        result = refresh_dataset_from_remote(force=False)
        if not result.get("ok"):
            logger.warning("MANDI sync failed: %s", result.get("error"))
        await asyncio.sleep(interval_seconds)


@app.on_event("startup")
async def _start_background_jobs() -> None:
    asyncio.create_task(_mandi_sync_loop())

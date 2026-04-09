# Crop Price Predictor

AI-assisted crop price advisor with a FastAPI backend and Flutter frontend.

Current app capabilities include:

- crop and mandi selection with location-aware nearby market filtering
- forecasting and sell-time recommendations
- weather snapshot + risk indicator
- crop watch workflow from sowing stage to ready-to-sell stage
- alert center for target price notifications
- multilingual chatbot with grounded/fallback response policy
- Firebase Authentication on Flutter web (Google + email/password)

## Project structure

- `backend_api/`: FastAPI services, dataset sync, prediction and chat logic
- `frontend_flutter/`: Flutter client (web/mobile)
- `dataset/`: bootstrap mandi prices and market metadata

## Backend quick start

Python requirement: 3.11+.

1. Create and activate a Python 3.11 environment.
2. Install dependencies:
	- `pip install -r backend_api/requirements.txt`
3. Run backend from repo root:
	- `cd backend_api`
	- `python -m uvicorn --app-dir . app.main:app --reload --host 127.0.0.1 --port 8000`

Why `--app-dir .` is recommended:
- It prevents accidental import of another global `app` package.
- This avoids recurring frontend `Failed to fetch` issues caused by hitting the wrong server on port 8000.

Health check:
- `GET /api/health`

## Frontend quick start

1. Install Flutter SDK.
2. Install dependencies:
	- `cd frontend_flutter`
	- `flutter pub get`
3. Run web app:
	- `flutter run -d chrome`

The default API base URL is `http://127.0.0.1:8000` in `frontend_flutter/lib/core/constants/api_constants.dart`.

## Firebase auth setup (Flutter web)

The web app now supports:

- Google sign-in
- Email/password sign-in
- Email/password registration

Required Firebase console steps:

1. Enable Authentication in your Firebase project.
2. Enable providers:
	- Google
	- Email/Password
3. Ensure authorized domains include:
	- `localhost`
	- your production domain (when deployed)

Firebase web options are loaded from `frontend_flutter/lib/firebase_options.dart`.

## Crop watch and selling flow

New crop watch APIs:

- `GET /api/crop-watch?username=...`
- `GET /api/crop-watch/overview?username=...&latitude=...&longitude=...`
- `POST /api/crop-watch`
- `DELETE /api/crop-watch/{watch_id}?username=...`

Flow:

1. User tracks a crop from sowing date.
2. App shows stage + advisories (weather/market/watch).
3. When crop is ready to sell, app prompts sell-time actions.

## Daily mandi dataset sync (official India dataset)

Configure in `backend_api/.env`:

- `MANDI_RESOURCE_ID`
- `MANDI_API_KEY`
- `MANDI_MAX_RECORDS` (optional; increase for wider coverage)
- `MANDI_REFRESH_INTERVAL_HOURS` (optional; default `24`)
- `MANDI_SYNC_ENABLED` (optional; default `true`)

Useful endpoints:

- `GET /api/dataset/sync-state`
- `POST /api/dataset/refresh` (optionally protected with `ADMIN_API_KEY`)

## Troubleshooting login `Failed to fetch`

If login fails on web, verify:

1. Backend health:
	- `curl -i http://127.0.0.1:8000/api/health`
2. CORS preflight:
	- `curl -i -X OPTIONS "http://127.0.0.1:8000/api/auth/sign-in" -H "Origin: http://localhost:<port>" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: content-type"`
3. Backend command uses local app directory:
	- `python -m uvicorn --app-dir . app.main:app --reload --host 127.0.0.1 --port 8000`

If the wrong app is on port 8000, Flutter web may show `ClientException: Failed to fetch` even when your code is correct.

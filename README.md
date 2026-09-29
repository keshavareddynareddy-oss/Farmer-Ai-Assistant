# Crop Price Predictor

AI-assisted crop price advisor with a FastAPI backend in `backend/` and a Flutter frontend in `frontend/`.

Current app capabilities include:

- crop and mandi selection with location-aware nearby market filtering
- forecasting and sell-time recommendations
- weather snapshot + risk indicator
- crop watch workflow from sowing stage to ready-to-sell stage
- alert center for target price notifications
- multilingual chatbot with grounded/fallback response policy
- Firebase Authentication on Flutter web (Google + email/password)

## Project structure

- `backend/`: FastAPI API, dataset sync, prediction and chat logic
- `frontend/`: Flutter client (web/mobile)
- `dataset/`: bootstrap mandi prices and market metadata

## Easy local run

Run each app from its own folder:

- Backend: `cd backend && .\run.ps1`
- Frontend: `cd frontend && .\run.ps1`

## Backend quick start

Python requirement: 3.11+.

1. Create and activate a Python 3.11 environment.
2. Install dependencies:
	- `pip install -r backend/requirements.txt`
3. Run backend from inside `backend/`:
	- `cd backend`
	- `.\run.ps1`

Why `--app-dir .` is recommended:
- It prevents accidental import of another global `app` package.
- This avoids recurring frontend `Failed to fetch` issues caused by hitting the wrong server on port 8000.

Health check:
- `GET /api/health`

## Frontend quick start

1. Install Flutter SDK.
2. Install dependencies:
	- `cd frontend`
	- `flutter pub get`
3. Run web app:
	- `.\run.ps1`

The API base URL is now configurable at build time. If you do nothing, it defaults to `http://127.0.0.1:8000` for local development.

Examples:

- Local dev:
	- `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000`
- Production web build:
	- `flutter build web --release --dart-define=API_BASE_URL=https://api.yourdomain.com`

If you host the frontend and backend under the same domain, point `API_BASE_URL` to that origin.

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

Firebase web options are loaded from `frontend/lib/firebase_options.dart`.

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

The backend can fetch the official [Current Daily Price of Various Commodities from Various Markets (Mandi)](https://www.data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi) feed. Its resource ID is built in; you only need a data.gov.in API key in `backend/.env`:

- `MANDI_API_KEY` (required; create an account on data.gov.in and generate an API key)
- `MANDI_RESOURCE_ID` (optional; defaults to `9ef84268-d588-465a-a308-a864a43d0070`)
- `MANDI_API_URL` (optional; overrides the official endpoint for a custom JSON or CSV feed)
- `MANDI_MAX_RECORDS` (optional; maximum total records fetched, default `10000`)
- `MANDI_PAGE_SIZE` (optional; records per API request, default `1000`)
- `MANDI_REFRESH_INTERVAL_HOURS` (optional; default `24`)
- `MANDI_SYNC_ENABLED` (optional; default `true`)

Useful endpoints:

- `GET /api/dataset/sync-state`
- `POST /api/dataset/refresh` (optionally protected with `ADMIN_API_KEY`)

When `MANDI_API_KEY` is set, the backend loads the bootstrap CSV first and
then refreshes from the nationwide mandi feed on startup and every
`MANDI_REFRESH_INTERVAL_HOURS` (24 hours by default). The official feed is read
in pages, prioritizing the most recent arrival dates; increase `MANDI_MAX_RECORDS`
if its latest data exceeds the default cap. If a remote refresh fails, the last successful local
dataset remains available. JSON feeds may return either an object with a
`records` or `data` array, or an array directly. CSV feeds should include
`commodity`/`crop_name`, `market`, `modal_price`/`price`, and a date column;
district, state, latitude, and longitude are optional.

## Troubleshooting login `Failed to fetch`

If login fails on web, verify:

1. Backend health:
	- `curl -i http://127.0.0.1:8000/api/health`
2. CORS preflight:
	- `curl -i -X OPTIONS "http://127.0.0.1:8000/api/auth/sign-in" -H "Origin: http://localhost:<port>" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: content-type"`
3. Backend command uses local app directory:
	- `python -m uvicorn --app-dir . app.main:app --reload --host 127.0.0.1 --port 8000`

If the wrong app is on port 8000, Flutter web may show `ClientException: Failed to fetch` even when your code is correct.

## Deployment checklist

For a working deployment, you need:

1. A reachable backend URL with CORS set for the frontend domain.
2. A Flutter web build created with the production `API_BASE_URL`.
3. Firebase Authentication configured for the deployed domain.
4. Backend environment variables set for any remote dataset or API keys you use.
5. A hosting target for the Flutter `build/web` output and a runtime for the FastAPI app.

### Production backend

1. Copy `backend/.env.example` to the backend host's secret configuration.
2. Set `APP_ENV=production`, a random `AUTH_SECRET_KEY`, `ADMIN_API_KEY`, and exact `CORS_ALLOW_ORIGINS`.
3. Set `DATABASE_PATH` to a persistent volume; keep database files out of the repository.
4. Configure Firebase Admin credentials with the hosting provider's secret/identity mechanism and set `FIREBASE_PROJECT_ID`.
5. Set `OPENWEATHER_API_KEY` and `ALLOW_MOCK_WEATHER=false`.
6. Configure `MANDI_API_KEY` or `MANDI_API_URL`; production startup rejects missing feed configuration.
7. Set `GOOGLE_GEMINI_API_KEY` and `GEMINI_REQUIRED=true` if AI chat is required.
8. Start the API with `backend/run-production.ps1` or an equivalent process manager. It uses one worker because the app's in-process sync loop runs once per worker.

If deploying multiple API replicas, set `MANDI_SYNC_ENABLED=false` on the API instances and use one external daily scheduler to call `POST /api/dataset/refresh` with the `X-Admin-Key` header. Do not enable an in-process sync loop on every replica. The endpoint returns `503` in production if `ADMIN_API_KEY` is missing.

Production startup fails when required secrets/services are missing or mock weather is enabled. Keep real secret values in the hosting provider's secret manager, not in the repository or a committed `.env` file.

### Production frontend

Build the web client with the public API origin:

```powershell
cd frontend
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Host `frontend/build/web` over HTTPS and add that domain to Firebase Authentication's authorized domains.

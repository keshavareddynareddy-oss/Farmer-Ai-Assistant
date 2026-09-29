# Frontend Flutter

Flutter client for crop analytics, advisories, alerts, and assistant features.

## Features

- Dashboard with weather risk, market momentum, and interactive popups
- Crop watch cards with stage-based advisories and sell-flow handoff
- Price alert center with threshold checks
- Crop selection and forecast workflow
- Assistant shortcuts + full chatbot screen
- Authentication:
  - Google sign-in (web)
  - Email/password sign-in and registration (web)

## Setup

1. Install Flutter SDK.
2. Install packages:
	- `flutter pub get`
3. Ensure backend is running on `http://127.0.0.1:8000`.
4. Run app:
	- Web: `.\run.ps1`
	- Other targets: `flutter run`

## Quick launch

From inside this folder, launch the frontend directly:

- Frontend: `.\run.ps1`

## Firebase (web auth)

Firebase config is in `lib/firebase_options.dart`.

In Firebase console, enable:

- Google provider
- Email/Password provider

And add authorized domains:

- `localhost`
- production domain (if deployed)

## Important files

- `lib/core/constants/api_constants.dart`: backend base URL + endpoint constants
- `lib/features/auth/login_screen.dart`: Google/email auth UI
- `lib/services/auth_service.dart`: Firebase web auth + backend fallback logic
- `lib/features/home/home_screen.dart`: dashboard, crop watch cards, popup interactions

## Common issue

If you get `ClientException: Failed to fetch` on login:

- verify backend health endpoint (`/api/health`)
- verify CORS preflight is allowed for your localhost web port
- verify backend is your project backend (not another app bound to port 8000)

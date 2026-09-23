# Smart Street-Vendor Location Optimizer — Lagos Case Study

A full-stack implementation of the system designed in the uploaded
thesis chapters: a weighted-suitability decision-support tool that ranks
candidate street-vendor locations in Lagos on an interactive map.

```
smart-street-vendor-app/
  backend/       Node.js + Express + SQLite REST API (auth, locations, scoring)
  mobile_app/    Flutter source (lib/ + pubspec.yaml) for the Android/iOS app
```

## Quick start

**1. Backend**
```bash
cd backend
npm install
cp .env.example .env
npm start
```
Runs on `http://localhost:4000`, auto-seeds demo users and 18 mock Lagos
locations. See `backend/README.md` for the full API and deployment steps.

**2. Mobile app**
```bash
flutter create --org com.smartvendor --project-name smart_vendor_app smart_vendor_app_project
cd smart_vendor_app_project
rm -rf lib && cp -r ../mobile_app/lib . && cp ../mobile_app/pubspec.yaml .
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```
See `mobile_app/README.md` for release-build (APK/AAB/IPA) instructions.

## What's implemented vs. what's left as an extension point

Implemented (matches Chapter 3's functional requirements):
user registration/login (JWT), location search/filter by area, interactive
map, weighted suitability scoring `S_i = Σ wⱼ·xᵢⱼ` with adjustable weights,
location ranking, location detail view, recommendation history, admin
location CRUD endpoints.

Left as extension points (the thesis frames these as optional/"where data
is available"):
- The Random Forest / ML model from §3.15 — the scoring module is
  structured so it can be swapped in once labelled outcome data exists
  (see `backend/README.md`).
- Real pedestrian/vendor/competition data — currently mock/randomised,
  clearly marked in `backend/src/seed.js`.
- An in-app admin UI (the API supports admin CRUD; only a UI screen for it
  is not included).

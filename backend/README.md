# Smart Street-Vendor Location Optimizer — Backend API

Node.js/Express + SQLite backend implementing the design in Chapter 3
(User, Location, LocationFeature, Recommendation, Vendor, Model entities;
weighted suitability scoring `S_i = Σ wⱼ·xᵢⱼ`).

## Run locally

```bash
cd backend
npm install
cp .env.example .env      # edit JWT_SECRET before deploying for real
npm start                 # seeds the DB automatically on first run
```

The API listens on `http://localhost:4000` (or `$PORT`). It seeds:
- Admin login: `[email protected]` / `Admin@123`
- Vendor login: `[email protected]` / `Vendor@123`
- 18 mock candidate locations across Lagos (Ikeja, Yaba, Surulere, Oshodi,
  Ikorodu Road, Lekki, Lagos Island, Mile 2, Berger, Ipaja) with mock
  pedestrian/accessibility/competition/traffic feature values.

> The feature values are illustrative mock data, not measured field data —
> swap `src/seed.js` for a real data-import script when real Lagos
> pedestrian/vendor data is available.

## API summary

| Method | Endpoint                    | Auth   | Purpose |
|--------|------------------------------|--------|---------|
| POST   | `/api/auth/register`         | -      | Create account |
| POST   | `/api/auth/login`            | -      | Log in, get JWT |
| GET    | `/api/locations`              | -      | List locations (`?area=`, `?q=`) |
| GET    | `/api/locations/areas`        | -      | Distinct areas for filters |
| GET    | `/api/locations/:id`          | -      | Location detail + features + vendors |
| POST   | `/api/locations`              | Admin  | Add candidate location |
| PUT    | `/api/locations/:id`          | Admin  | Update location/features |
| DELETE | `/api/locations/:id`          | Admin  | Remove location |
| POST   | `/api/recommendations`        | User   | Score + rank locations (`{area?, weights?}`) |
| GET    | `/api/recommendations/history`| User   | Past recommendation runs |

## Deploying

Any Node hosting works (Render, Railway, Fly.io, a VPS with PM2/nginx).
Steps are the same everywhere:

1. `npm install --production`
2. Set environment variables `PORT`, `JWT_SECRET`, `DB_PATH` (point `DB_PATH`
   at a persistent disk/volume — SQLite is a single file).
3. `npm start`
4. Point the Flutter app's `API_BASE_URL` (see `mobile_app/README.md`) at
   this server's public URL, e.g. `https://your-app.onrender.com/api`.

## Extending toward the thesis's optional ML model

`src/scoring.js` currently implements the weighted-suitability model
(Chapter 3, §3.14). To add the Random Forest approach from §3.15 once
labelled outcome data exists, train a model offline (e.g. in Python with
scikit-learn), export it, and either:
- serve predictions from a small Python inference service the Node API
  calls, or
- port the trained weights/thresholds into a JS scoring function alongside
  `scoreLocations()`.

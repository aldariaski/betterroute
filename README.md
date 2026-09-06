# BetterRoute

BetterRoute is an MVP for calculating the real driving distance and route between a buyer and a merchant.

(image.png)

## Stack

- Flutter + Dart — mobile UI
- Go + Gin — REST API
- PostgreSQL + PostGIS — merchant geospatial data
- OpenRouteService — road routing/distance/ETA
- MapLibre — map rendering
- Docker Compose — local PostgreSQL

The routing endpoint proxies OpenRouteService so the API key stays on the backend rather than being shipped in the Flutter app.

## Project structure

```text
betterroute/
├── backend/       # Go/Gin API
├── frontend/      # Flutter app
├── database/      # PostGIS initialization
├── docker-compose.yml
└── README.md
```

## 1. Start PostgreSQL/PostGIS

Install Docker Desktop, then from this directory:

```bash
docker compose up -d
```

Postgres is available on `localhost:5432`.

## 2. Configure the backend

Copy `backend/.env.example` to `backend/.env` and set your OpenRouteService API key:

```env
PORT=8080
DATABASE_URL=postgres://betterroute:betterroute@localhost:5432/betterroute?sslmode=disable
ORS_API_KEY=YOUR_KEY
```

Create an OpenRouteService API key from their developer portal. The backend uses `POST /v2/directions/driving-car/geojson` with `units=km`.

## 3. Run the Go API

```bash
cd backend
go mod tidy
go run ./cmd/server
```

Test:

```text
http://localhost:8080/health
http://localhost:8080/api/merchants
```

Example route:

```text
http://localhost:8080/api/route?buyer_lat=-6.2&buyer_lng=106.8166&merchant_lat=-6.175392&merchant_lng=106.827153
```

## 4. Run Flutter

The frontend currently expects the API at `http://10.0.2.2:8080` for the Android emulator.

```bash
cd frontend
flutter pub get
flutter run
```

For a physical phone, change `baseUrl` in `frontend/lib/services/api.dart` to the LAN address of the computer running the Go server.

## MVP flow

1. Buyer coordinates are entered.
2. A merchant is selected.
3. Flutter calls the Go API.
4. Go calls OpenRouteService.
5. OpenRouteService returns a GeoJSON road route, distance and duration.
6. Go returns only the data needed by the app.
7. Flutter displays the merchant/buyer points and route polyline.

## Production next steps

- Add authentication and users.
- Add address search/geocoding instead of manual coordinates.
- Add merchant CRUD UI.
- Cache route results to reduce routing API calls.
- Add nearest-merchant queries using PostGIS.
- Add delivery pricing based on route distance.
- Replace the demo MapLibre tile style with a production tile provider.
- Add rate limiting, request validation, structured logging and observability.

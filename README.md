# BetterRoute

BetterRoute is an MVP for calculating the real driving distance and route between a buyer and a merchant.

![Dashboard Screenshot](image.png)
![Dashboard Screenshot](image copy.png)
![Dashboard Screenshot](Screenshot (5164).png)
![Dashboard Screenshot](Screenshot (5165).png)

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
http://localhost:8080/api/route?origin_lat=-6.2&origin_lng=106.8166&destination_lat=-6.175392&destination_lng=106.827153
```

## 4. Run Flutter

The frontend currently expects the API at `http://10.0.2.2:8080` for the Android emulator.

```bash
cd frontend
flutter pub get
flutter run
```

For a physical phone, change `baseUrl` in `frontend/lib/services/api.dart` to the LAN address of the computer running the Go server.

## Current trip-planning flow

1. The user searches for an origin and destination, or uses the current location as origin.
2. Flutter calls Go for place suggestions and driving routes.
3. Go proxies OpenRouteService geocoding and directions so the key stays server-side.
4. The route response includes alternative routes, maneuver instructions, distance, ETA, and GeoJSON geometry.
5. Flutter displays route choices, fits the selected route to the map, and shows a directions list.
6. Foreground navigation preview follows GPS position and requests a new route when the device is sufficiently far from the selected route.

Geocoding is currently restricted to Indonesia. Directions and search require a configured `ORS_API_KEY`. Live traffic ETA and background navigation are not yet implemented.

## Production next steps

- Add authentication and users.
- Add persistent route caching, provider-usage safeguards and structured observability.
- Add background navigation with platform-specific lifecycle and permission handling.
- Evaluate a traffic-aware routing provider for refreshed ETA and traffic-based alternatives.
- Add merchant CRUD UI.
- Cache route results to reduce routing API calls.
- Add nearest-merchant queries using PostGIS.
- Add delivery pricing based on route distance.
- Replace the demo MapLibre tile style with a production tile provider.
- Add rate limiting, request validation, structured logging and observability.

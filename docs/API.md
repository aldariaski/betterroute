# BetterRoute API

## GET /health

Returns `{ "status": "ok" }`.

## GET /api/merchants

Returns all merchants.

## GET /api/merchants/:id

Returns one merchant.

## POST /api/merchants

Creates a merchant with `name`, `address`, `latitude`, and `longitude`.

## GET /api/places/search?q=...

Searches OpenRouteService geocoding results, limited to Indonesia. Queries must contain 3–160 characters. Returns up to six places with name, address, latitude, and longitude. The ORS API key stays on the server.

## GET /api/route

Query parameters:

- `origin_lat`, `origin_lng`
- `destination_lat`, `destination_lng`

Returns route alternatives, each with `distance_km`, `duration_minutes`, GeoJSON `geometry`, and `steps`. Each step has `instruction`, `name`, `distance_m`, `duration_s`, and provider maneuver `type`.

```json
{
  "routes": [
    {
      "distance_km": 4.8,
      "duration_minutes": 18,
      "geometry": { "type": "LineString", "coordinates": [[106.8, -6.2], [106.81, -6.19]] },
      "steps": [{ "instruction": "Head northeast", "name": "Example Street", "distance_m": 350, "duration_s": 45, "type": 11 }]
    }
  ]
}
```

The route ETA is the routing provider's estimate. Live traffic adjustment and background navigation are not currently supplied by the API.

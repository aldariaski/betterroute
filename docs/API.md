# BetterRoute API

## GET /health

Returns `{ "status": "ok" }`.

## GET /api/merchants

Returns all merchants.

## GET /api/merchants/:id

Returns one merchant.

## POST /api/merchants

Body:

```json
{
  "name": "Example Merchant",
  "address": "Jakarta",
  "latitude": -6.2,
  "longitude": 106.8
}
```

## GET /api/route

Query parameters:

- `buyer_lat`
- `buyer_lng`
- `merchant_lat`
- `merchant_lng`

Response:

```json
{
  "distance_km": 4.8,
  "duration_minutes": 18,
  "geometry": {
    "type": "LineString",
    "coordinates": [[106.8,-6.2],[106.81,-6.19]]
  }
}
```

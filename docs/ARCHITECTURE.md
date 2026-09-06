# Architecture

```text
Flutter
  |
  | GET /api/route
  v
Go + Gin
  |             \
  |              \ POST directions
  v               v
PostgreSQL      OpenRouteService
+ PostGIS           |
  |                 |
  +------ route geometry/distance/duration
                    |
                    v
                 Flutter
                    |
                    v
                 MapLibre
```

The routing API key is kept in the backend environment and never placed in Flutter source code.

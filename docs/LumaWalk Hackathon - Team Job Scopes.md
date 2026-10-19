# LumaWalk Team Job Scopes

This document describes the current repository boundaries. The product
requirements document contains the longer-term roadmap; this file describes
what is actually present in the demo.

## Data Pipeline

**Location:** `data_pipeline/`

The pipeline prepares the Petaling Jaya walking network and safety metadata.
The scripts download OpenStreetMap data, apply lighting weights, calculate
safe-haven proximity scores, and write GraphML, GeoJSON, and coverage-report
artifacts to `data_pipeline/output/`.

Key configuration lives in `data_pipeline/scripts/config.py`. The current
pipeline uses a 300 m linear falloff for `w_haven` and neutral defaults for
crowd and hazard weights. Rerunning the pipeline requires its source data and
network access; inspect each script before running it on a clean machine.

## Routing Backend

**Location:** `backend/routing_service/` and `backend/main.py`

The routing service validates the Petaling Jaya bounding box, snaps requested
coordinates to the loaded graph, calculates a safety-aware route and a direct
route, and returns distances, lit percentage, and detour time.

The implemented endpoint is:

```text
POST /api/v1/route/
```

The graph is loaded from `data_pipeline/output/pj_network.graphml` when the
FastAPI application starts. If the file is unavailable, the backend uses a
small dummy graph for development. Routing state is held in process memory.

## Virtual Buddy Backend

**Location:** `backend/buddy_service/`

The buddy service starts sessions, stores the active route polyline, calculates
cross-track error using Shapely and Web Mercator projection, and accepts
telemetry pings.

Implemented endpoints:

```text
POST /api/v1/buddy/session/start
POST /api/v1/buddy/telemetry/ping
```

The current thresholds are 50 m for route deviation and 180 seconds between
telemetry pings. Alerts are simulated by a server log; no production SMS or
emergency webhook is connected.

## Flutter Frontend

**Location:** `lunawalk_frontend/`

The Flutter app provides the map and navigation demo. Current features include
Nominatim destination search, OpenStreetMap tiles, direct and safe route
selection, local safe-haven GeoJSON markers, navigation simulation, telemetry,
insights, support, and settings screens.

The frontend uses `flutter_map`, `latlong2`, Provider, `http`, Geolocator, and
Flutter TTS. It calls the backend at `localhost:8000` on desktop/web and uses
`10.0.2.2:8000` from an Android emulator.

## Shared Contracts

**Location:** `docs/schemas.json`

The JSON file documents the implemented FastAPI payloads. Routing response
coordinates use `[latitude, longitude]`; buddy route and telemetry coordinates
use `[longitude, latitude]`. Keep this distinction when changing either side
of the integration.

## Planned Work

PostGIS storage, MapLibre, authentication, crowd-report APIs, a safe-haven
search endpoint, production alert dispatch, and multi-tenant B2B analytics are
not part of the current implementation. Changes that add these capabilities
should update the PRD, schemas, and root README together.

# LumaWalk

LumaWalk is a safety-aware walking navigation demo for Petaling Jaya. It
combines an OpenStreetMap walking graph, lighting and safe-haven scores, a
FastAPI routing service, and a Flutter client for route planning and simulated
walk monitoring.

## Current Implementation

The repository currently contains:

- A data pipeline that produces an enriched Petaling Jaya GraphML network and
	GeoJSON artifacts.
- A FastAPI backend that loads the network into memory and calculates a
	safety-weighted route alongside a direct route.
- A virtual buddy service that tracks an active route, calculates cross-track
	deviation, and logs simulated emergency dispatches.
- A Flutter app in `lunawalk_frontend/` with map search, route selection,
	navigation simulation, safe-haven markers, telemetry, insights, support,
	and settings screens.

The product requirements document contains the longer-term B2B product vision.
PostGIS, MapLibre, authentication, crowdsourced reports, production SMS, and
multi-tenant analytics are planned capabilities, not implemented services in
this repository.

## Repository Layout

```text
backend/                 FastAPI routing and virtual buddy services
data_pipeline/           OSM graph download and safety-score enrichment
data_pipeline/output/    Generated and shared graph/GeoJSON artifacts
docs/                    Product, contract, ownership, and architecture notes
lunawalk_frontend/       Flutter web, desktop, and mobile application
cache/                   Cached geocoding/search responses
```

## Prerequisites

- Python 3.10 or newer
- Flutter SDK 3.x or newer with a web or desktop device configured
- Network access for OSM/Nominatim requests in the data pipeline and Photon
	destination search

## Quick Start

### 1. Start the backend

In PowerShell:

```powershell
cd "c:\Documents\docs\Desktop\LumaWalk\LumaWalk\backend"
py -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload
```

The backend runs at `http://127.0.0.1:8000`. Open
`http://127.0.0.1:8000/docs` for the interactive API documentation.

The server loads `data_pipeline/output/pj_network.graphml` at startup. If it
cannot find that file, it uses a small dummy graph for development.

### 2. Start the Flutter frontend

In a second terminal:

```powershell
cd "c:\Documents\docs\Desktop\LumaWalk\LumaWalk\lunawalk_frontend"
flutter pub get
flutter devices
flutter run -d chrome
```

Use another device ID from `flutter devices` when needed. The frontend calls
the backend at `http://127.0.0.1:8000`; Android emulators use
`http://10.0.2.2:8000`.

### 3. Run checks

```powershell
cd "c:\Documents\docs\Desktop\LumaWalk\LumaWalk\lunawalk_frontend"
flutter analyze
flutter test
```

## Backend API

The implemented endpoints are:

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/v1/route/` | Return a safety-aware route and direct route for Petaling Jaya coordinates. |
| `POST` | `/api/v1/buddy/session/start` | Start a monitored walking session from a route polyline. |
| `POST` | `/api/v1/buddy/telemetry/ping` | Submit a position and receive the session safety status. |

Routing requests use separate `start_lat`, `start_lng`, `end_lat`, and
`end_lng` fields. Route coordinate arrays returned by the backend are
`[latitude, longitude]`. Buddy polylines and telemetry positions use
`[longitude, latitude]`, matching the spatial helper and current frontend
integration; keep this distinction in mind when testing the endpoints.

## Data Pipeline

The pipeline scripts are in `data_pipeline/scripts/`:

1. `01_fetch_osm.py` downloads the Petaling Jaya walking network and OSM
	 safe-haven points.
2. `02_patch_lit.py` applies lighting values and defaults for untagged ways.
3. `03_buffers.py` calculates the `w_haven` score with a 300 m linear falloff
	 and writes enriched graph and GeoJSON output.

The checked-in output includes `pj_network.graphml`, `pj_edges.geojson`,
`real_havens_petaling_jaya.geojson`, and `lit_coverage_report.json`. The
pipeline also expects its input data directory when rerunning the patch stage;
check each script and `data_pipeline/scripts/config.py` before running it on a
new machine.

## Documentation

- [Backend setup and API examples](backend/README.md)
- [Frontend setup and user workflow](lunawalk_frontend/README.md)
- [Current project structure](docs/project_structure.txt)
- [Implemented API contracts](docs/schemas.json)
- [Product requirements and planned roadmap](docs/LumaWalk%20Product%20Requirements%20Document%20(PRD).md)
- [Team responsibilities](docs/LumaWalk%20Hackathon%20-%20Team%20Job%20Scopes.md)

## Limitations

- Safety is a proxy based on OSM-derived lighting and safe-haven metadata; it
	is not a crime-risk prediction model.
- Emergency alerts are console logs, not real SMS or emergency-service
	integrations.
- Several frontend flows, including simulation time, SOS, hazard reporting,
	and some dashboard metrics, are local demo behavior.
- The API currently keeps sessions and the routing graph in process memory.
- Nominatim, Photon, and OSM tile usage must follow their service policies and
	include attribution in the app.

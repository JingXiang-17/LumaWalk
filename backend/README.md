# LumaWalk Backend

FastAPI backend for LumaWalk. It provides the safe-route calculation API and the virtual buddy safety-session API.

## Requirements

- Python 3.10 or newer
- The network data file at `../data_pipeline/output/pj_network.graphml` for real route calculations

When the network file is unavailable, the application starts with a small dummy graph for development.

## Setup and Run

Run these commands from the `backend` directory.

### Windows Command Prompt

```bat
cd /d C:\path\to\LumaWalk\backend
py -m venv .venv
.\.venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### Windows PowerShell

```powershell
Set-Location "C:\path\to\LumaWalk\backend"
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

Replace `C:\path\to\LumaWalk` with the location of your repository. Keep this
terminal open while using the Flutter app; browser requests to
`http://127.0.0.1:8000` require the backend server to be running. The API is
available at that address.

Useful local URLs:

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

To stop the development server, press `Ctrl+C`. To leave the virtual environment, run:

```text
deactivate
```

## API Endpoints

### Safe route

`POST /api/v1/route/`

Accepts start and end coordinates inside the supported Petaling Jaya map area:

```json
{
	"start_lat": 3.12,
	"start_lng": 101.65,
	"end_lat": 3.13,
	"end_lng": 101.66
}
```

The response includes the safety-aware route, direct route, distances, a distance-weighted lighting score based on each edge's `w_light` value, and estimated detour time.

### Start a buddy session

`POST /api/v1/buddy/session/start`

```json
{
	"user_id": "demo-user",
	"route_polyline": [[101.65, 3.12], [101.66, 3.13]],
	"human_contact_name": "Emergency Contact",
	"human_contact_phone": "+60123456789"
}
```

The response contains a generated `session_id`. Use it when sending telemetry updates.

### Send telemetry

`POST /api/v1/buddy/telemetry/ping`

```json
{
	"session_id": "sess_12345678",
	"current_position": [101.655, 3.125]
}
```

The service returns the current session status and the calculated cross-track error in meters. A deviation greater than 50 meters or more than three minutes without movement triggers the simulated emergency dispatch log.

## Project Structure

```text
backend/
├── main.py                 # FastAPI application and graph loading
├── requirements.txt        # Python dependencies
├── buddy_service/          # Safety sessions and telemetry
└── routing_service/        # Safe-route calculation
```

## Notes

- Coordinate arrays use `[longitude, latitude]` order in buddy route polylines and telemetry positions.
- Route requests use separate `*_lat` and `*_lng` fields.
- The loaded graph is kept in memory while the server is running.

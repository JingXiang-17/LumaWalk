from fastapi import APIRouter, HTTPException, BackgroundTasks
import uuid
from datetime import datetime, timezone

from .schemas import StartSessionRequest, TelemetryPing
from .spatial import polyline_to_meters, calculate_cross_track_error

router = APIRouter()

# In-memory state machine
active_sessions = {}

DEVIATION_THRESHOLD_METERS = 50.0
STATIONARY_THRESHOLD_SECONDS = 180

def dispatch_emergency_alert(session_id: str, reason: str, position: list):
    timestamp = datetime.now(timezone.utc).isoformat()
    print("\n" + "="*50)
    print(f"🚨 [EMERGENCY DISPATCH TRIGGERED] 🚨")
    print(f"Time: {timestamp}")
    print(f"Session: {session_id}")
    print(f"Reason: {reason}")
    print(f"Last Known Coord: {position}")
    print("="*50 + "\n")

@router.post("/session/start")
async def start_session(req: StartSessionRequest):
    if len(req.route_polyline) < 2:
        raise HTTPException(status_code=400, detail="Polyline needs at least 2 points.")
    
    session_id = f"sess_{uuid.uuid4().hex[:8]}"
    line_in_meters = polyline_to_meters(req.route_polyline)
    
    active_sessions[session_id] = {
        "user_id": req.user_id,
        "route_line_meters": line_in_meters,
        "last_ping_time": datetime.now(timezone.utc),
        "last_position": req.route_polyline[0],
        "status": "SAFE"
    }
    
    return {"session_id": session_id, "status": "SESSION_ACTIVE"}

@router.post("/telemetry/ping")
async def ingest_telemetry(ping: TelemetryPing, bg_tasks: BackgroundTasks):
    session = active_sessions.get(ping.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found or expired.")

    now = datetime.now(timezone.utc)
    time_since_last_ping = (now - session["last_ping_time"]).total_seconds()
    
    session["last_ping_time"] = now
    session["last_position"] = ping.current_position
    
    deviation_meters = calculate_cross_track_error(
        ping.current_position, 
        session["route_line_meters"]
    )
    
    if deviation_meters > DEVIATION_THRESHOLD_METERS:
        session["status"] = "WARNING_DEVIATED"
        bg_tasks.add_task(
            dispatch_emergency_alert, 
            ping.session_id, 
            f"User is {deviation_meters:.1f}m off route.", 
            ping.current_position
        )
    elif time_since_last_ping > STATIONARY_THRESHOLD_SECONDS:
        session["status"] = "WARNING_STATIONARY"
        bg_tasks.add_task(
            dispatch_emergency_alert, 
            ping.session_id, 
            "User has not moved in 3 minutes.", 
            ping.current_position
        )
    else:
        session["status"] = "SAFE"

    return {
        "status": session["status"],
        "cross_track_error_meters": round(deviation_meters, 2)
    }
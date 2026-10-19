from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class StartSessionRequest(BaseModel):
    user_id: str
    route_polyline: List[List[float]]
    # New: Optional human contact details
    human_contact_name: Optional[str] = None
    human_contact_phone: Optional[str] = None

class TelemetryPing(BaseModel):
    session_id: str
    current_position: List[float]
from pydantic import BaseModel
from typing import List

class StartSessionRequest(BaseModel):
    user_id: str
    route_polyline: List[List[float]] # [longitude, latitude]

class TelemetryPing(BaseModel):
    session_id: str
    current_position: List[float]     # [longitude, latitude]
from pydantic import BaseModel
from typing import List, Dict

class RouteRequest(BaseModel):
    start_lat: float
    start_lon: float
    end_lat: float
    end_lon: float

class RouteResponse(BaseModel):
    safe_route_coords: List[Dict[str, float]]
    direct_route_coords: List[Dict[str, float]]
    safe_distance_meters: float
    direct_distance_meters: float
    percentage_lit: float
    detour_time_seconds: int
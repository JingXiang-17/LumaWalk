from pydantic import BaseModel
from typing import List

class RouteRequest(BaseModel):
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float
    is_recalculation: bool = False

class RouteResponse(BaseModel):
    safe_route_coords: List[List[float]]
    direct_route_coords: List[List[float]]
    safe_distance: float
    direct_distance: float
    percentage_lit: float
    detour_time_seconds: int
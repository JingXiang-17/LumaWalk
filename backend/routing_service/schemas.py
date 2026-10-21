from pydantic import BaseModel, Field
from typing import List, Tuple

class RouteRequest(BaseModel):
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float
    is_recalculation: bool = False
    lighting_failure_points: List[Tuple[float, float]] = Field(
        default_factory=list, max_length=2
    )

class RouteResponse(BaseModel):
    safe_route_coords: List[List[float]]
    direct_route_coords: List[List[float]]
    safe_distance: float
    direct_distance: float
    percentage_lit: float
    detour_time_seconds: int
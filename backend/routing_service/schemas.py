from pydantic import BaseModel
from typing import List

class RouteRequest(BaseModel):
    start_node: int
    end_node: int

class RouteResponse(BaseModel):
    path_intersections: List[int]
    total_distance_meters: float
    percentage_lit: float
    detour_time_seconds: int
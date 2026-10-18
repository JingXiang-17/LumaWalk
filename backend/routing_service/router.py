from fastapi import APIRouter
import networkx as nx
from routing_service.schemas import RouteRequest, RouteResponse
from routing_service import algo

router = APIRouter()

@router.post("/", response_model=RouteResponse)
def get_safe_route(request: RouteRequest):
    # We call the math from algo.py
    path, final_distance = algo.find_safest_route(algo.route_graph, request.start_node, request.end_node)
    
    lit_distance = 0
    for i in range(len(path) - 1):
        u = path[i]
        v = path[i+1]
        if algo.route_graph[u][v].get('is_lit', False):
            lit_distance += algo.route_graph[u][v].get('weight', 0)
            
    if final_distance > 0:
        percentage_lit = round((lit_distance / final_distance) * 100, 2)
    else:
        percentage_lit = 0.0

    shortest_distance = nx.shortest_path_length(algo.route_graph, request.start_node, request.end_node, weight='weight')
    extra_distance_meters = final_distance - shortest_distance
    walking_speed_mps = 1.4 
    detour_time_seconds = int(extra_distance_meters / walking_speed_mps)
    
    return RouteResponse(
        path_intersections=path,
        total_distance_meters=final_distance,
        percentage_lit=percentage_lit, 
        detour_time_seconds=detour_time_seconds
    )
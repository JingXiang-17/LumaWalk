from fastapi import APIRouter
import networkx as nx
from routing_service.schemas import RouteRequest, RouteResponse
from routing_service import algo

router = APIRouter()

@router.post("/", response_model=RouteResponse)
def get_safe_route(request: RouteRequest):
    G = algo.route_graph
    
    # 1. Snap incoming GPS coordinates to the nearest graph nodes
    start_node = algo.get_closest_node(G, request.start_lat, request.start_lon)
    end_node = algo.get_closest_node(G, request.end_lat, request.end_lon)
    
    # 2. Calculate both routes using the snapped node IDs
    safe_path, safe_distance = algo.find_safest_route(G, start_node, end_node)
    
    direct_path = nx.shortest_path(G, start_node, end_node, weight='weight')
    direct_distance = nx.shortest_path_length(G, start_node, end_node, weight='weight')
    
    # 3. Extract coordinates into arrays for the frontend
    safe_coords = [{"lat": G.nodes[n].get('y', 0.0), "lon": G.nodes[n].get('x', 0.0)} for n in safe_path]
    direct_coords = [{"lat": G.nodes[n].get('y', 0.0), "lon": G.nodes[n].get('x', 0.0)} for n in direct_path]
    
    # Calculate lighting metric
    lit_distance = 0
    for i in range(len(safe_path) - 1):
        u = safe_path[i]
        v = safe_path[i+1]
        if G[u][v].get('is_lit', False):
            lit_distance += G[u][v].get('weight', 0)
            
    percentage_lit = round((lit_distance / safe_distance) * 100, 2) if safe_distance > 0 else 0.0

    # Calculate detour time
    extra_distance_meters = safe_distance - direct_distance
    walking_speed_mps = 1.4 
    detour_time_seconds = int(extra_distance_meters / walking_speed_mps)
    
    return RouteResponse(
        safe_route_coords=safe_coords,
        direct_route_coords=direct_coords,
        safe_distance_meters=safe_distance,
        direct_distance_meters=direct_distance,
        percentage_lit=percentage_lit, 
        detour_time_seconds=detour_time_seconds
    )
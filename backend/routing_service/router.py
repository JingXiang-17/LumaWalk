from fastapi import APIRouter, HTTPException
import networkx as nx
from routing_service.schemas import RouteRequest, RouteResponse
from routing_service import algo

router = APIRouter()

# Approximate Bounding Box for Petaling Jaya (Adjust if necessary)
PJ_MIN_LAT, PJ_MAX_LAT = 3.033, 3.160
PJ_MIN_LNG, PJ_MAX_LNG = 101.560, 101.665

def is_within_pj(lat: float, lng: float) -> bool:
    return (PJ_MIN_LAT <= lat <= PJ_MAX_LAT) and (PJ_MIN_LNG <= lng <= PJ_MAX_LNG)

@router.post("/", response_model=RouteResponse)
def get_safe_route(request: RouteRequest):
    # 1. Geofence Check: Reject out-of-bounds locations immediately
    if not is_within_pj(request.start_lat, request.start_lng) or not is_within_pj(request.end_lat, request.end_lng):
        raise HTTPException(status_code=400, detail="Location is outside the supported Petaling Jaya map area.")

    G = algo.route_graph
    
    # 2. Snap incoming GPS coordinates to the nearest graph nodes
    start_node = algo.get_closest_node(G, request.start_lat, request.start_lng)
    end_node = algo.get_closest_node(G, request.end_lat, request.end_lng)
    
    if start_node is None or end_node is None:
        raise HTTPException(status_code=400, detail="Could not snap to a valid route node.")
    
    # 3. Calculate both routes using the snapped node IDs
    safe_path, safe_distance = algo.find_safest_route(G, start_node, end_node)
    
    weight_fn = lambda u, v, d: float(list(d.values())[0].get('length', 1.0))
    direct_path = nx.shortest_path(G, start_node, end_node, weight=weight_fn)
    direct_distance = nx.shortest_path_length(G, start_node, end_node, weight=weight_fn)
    
    # 4. Extract coordinates into arrays for the frontend
    safe_coords = [[G.nodes[n].get('y', 0.0), G.nodes[n].get('x', 0.0)] for n in safe_path]
    direct_coords = [[G.nodes[n].get('y', 0.0), G.nodes[n].get('x', 0.0)] for n in direct_path]
    
    # Calculate lighting metric
    lit_distance = 0
    for i in range(len(safe_path) - 1):
        u = safe_path[i]
        v = safe_path[i+1]
        # Bypass the string/int key issue by forcing a list conversion
        edge_data = list(G[u][v].values())[0]
        # The data pipeline uses a float metric 'w_light', not a boolean 'is_lit'
        if float(edge_data.get('w_light', 0.0)) >= 0.5:
            lit_distance += float(edge_data.get('length', 0.0))
            
    percentage_lit = round((lit_distance / safe_distance) * 100, 2) if safe_distance > 0 else 0.0

    # Calculate detour time
    extra_distance_meters = safe_distance - direct_distance
    walking_speed_mps = 1.4 
    detour_time_seconds = int(extra_distance_meters / walking_speed_mps)
    
    return RouteResponse(
        safe_route_coords=safe_coords,
        direct_route_coords=direct_coords,
        safe_distance=safe_distance,
        direct_distance=direct_distance,
        percentage_lit=percentage_lit, 
        detour_time_seconds=detour_time_seconds
    )
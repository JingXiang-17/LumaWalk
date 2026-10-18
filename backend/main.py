from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import networkx as nx
from pydantic import BaseModel
from typing import List

# --- TEAMMATE'S CODE: Virtual Buddy Router ---
from buddy_service.router import router as buddy_router

# --- MEMBER 2 CODE: Global Variable & Dummy Map ---
route_graph = None

def create_dummy_graph():
    G = nx.Graph()
    G.add_nodes_from(range(1, 11))
    G.add_edge(1, 2, weight=50, is_lit=True, safety_score=0.9)
    G.add_edge(2, 3, weight=100, is_lit=False, safety_score=0.2)
    G.add_edge(1, 3, weight=120, is_lit=True, safety_score=0.8)
    G.add_edge(3, 4, weight=40, is_lit=True, safety_score=0.95)
    G.add_edge(4, 5, weight=200, is_lit=False, safety_score=0.1)
    G.add_edge(2, 5, weight=150, is_lit=True, safety_score=0.85)
    G.add_edge(5, 6, weight=60, is_lit=True, safety_score=0.9)
    G.add_edge(6, 7, weight=80, is_lit=False, safety_score=0.3)
    G.add_edge(7, 8, weight=110, is_lit=True, safety_score=0.8)
    G.add_edge(8, 9, weight=90, is_lit=True, safety_score=0.85)
    G.add_edge(9, 10, weight=30, is_lit=True, safety_score=0.9)
    G.add_edge(4, 8, weight=130, is_lit=False, safety_score=0.4)
    G.add_edge(6, 10, weight=170, is_lit=True, safety_score=0.7)
    return G

# --- MEMBER 2 CODE: Server Startup / Memory Loading ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    global route_graph
    try:
        route_graph = nx.read_graphml("campus_network.graphml")
        print("Success: Map data loaded into memory!")
    except FileNotFoundError:
        print("Waiting for Member 1's file. Loading the 10-node dummy map instead.")
        route_graph = create_dummy_graph() 
    yield 
    route_graph.clear()

# --- THE INTEGRATED APP ---
# We combine your lifespan memory-loading with the main app setup
app = FastAPI(
    title="LumaWalk - Integrated API", 
    lifespan=lifespan
)

# Teammate's CORS setup (Do not delete)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Teammate's Virtual Buddy API mounted (Do not delete)
app.include_router(buddy_router, prefix="/api/v1/buddy", tags=["Virtual Buddy"])

# --- MEMBER 2 CODE: Pathfinding Math ---
def custom_safety_cost(u, v, edge_data):
    distance = edge_data.get('weight', 1)
    safety_score = edge_data.get('safety_score', 0.1)
    safe_s = max(safety_score, 0.01) 
    return distance / safe_s

def find_safest_route(G, start_node, end_node):
    direct_distance = nx.shortest_path_length(G, start_node, end_node, weight='weight')
    max_allowed_distance = direct_distance * 1.25
    
    safe_path = nx.shortest_path(G, start_node, end_node, weight=custom_safety_cost)
    
    safe_distance = 0
    for i in range(len(safe_path) - 1):
        u = safe_path[i]
        v = safe_path[i+1]
        safe_distance += G[u][v]['weight']
        
    if safe_distance > max_allowed_distance:
        return nx.shortest_path(G, start_node, end_node, weight='weight'), direct_distance
        
    return safe_path, safe_distance

# --- MEMBER 2 CODE: Pydantic Data Models ---
class RouteRequest(BaseModel):
    start_node: int
    end_node: int

class RouteResponse(BaseModel):
    path_intersections: List[int]
    total_distance_meters: float
    percentage_lit: float
    detour_time_seconds: int

# --- MEMBER 2 CODE: The Official REST Endpoint ---
# We add tags=["Routing Engine"] so it is grouped neatly in the Swagger UI
@app.post("/api/v1/route", response_model=RouteResponse, tags=["Routing Engine"])
def get_safe_route(request: RouteRequest):
    path, final_distance = find_safest_route(route_graph, request.start_node, request.end_node)
    
    lit_distance = 0
    for i in range(len(path) - 1):
        u = path[i]
        v = path[i+1]
        if route_graph[u][v].get('is_lit', False):
            lit_distance += route_graph[u][v].get('weight', 0)
            
    if final_distance > 0:
        percentage_lit = round((lit_distance / final_distance) * 100, 2)
    else:
        percentage_lit = 0.0

    shortest_distance = nx.shortest_path_length(route_graph, request.start_node, request.end_node, weight='weight')
    extra_distance_meters = final_distance - shortest_distance
    walking_speed_mps = 1.4 
    detour_time_seconds = int(extra_distance_meters / walking_speed_mps)
    
    return RouteResponse(
        path_intersections=path,
        total_distance_meters=final_distance,
        percentage_lit=percentage_lit, 
        detour_time_seconds=detour_time_seconds
    )
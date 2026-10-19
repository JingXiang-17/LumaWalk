import os
from fastapi import FastAPI
from buddy_service.router import router as buddy_router

# --- ADDED FOR ROUTING ENGINE (Imports & Memory Loading) ---
from contextlib import asynccontextmanager
import networkx as nx
import osmnx as ox
from routing_service.router import router as routing_router
from routing_service import algo

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        # 1. Get the absolute path of the folder containing main.py
        current_dir = os.path.dirname(os.path.abspath(__file__))
        
        # 2. Build the exact path to the graphml file
        graph_path = os.path.join(current_dir, "..", "data_pipeline", "output", "pj_network.graphml")
        
        # 3. Load the graph using OSMnx exactly as the pipeline instructed
        edge_dtypes = {"w_light": float, "w_haven": float, "w_crowd": float, "w_hazard": float}
        algo.route_graph = ox.load_graphml(graph_path, edge_dtypes=edge_dtypes)
        print("Success: Map data loaded into memory!")
    except FileNotFoundError:
        print(f"Failed to find file at: {graph_path}")
        print("Loading the 10-node dummy map instead.")
        algo.route_graph = algo.create_dummy_graph() 
    yield 
    algo.route_graph.clear()
# -----------------------------------------------------------

# Added lifespan=lifespan here, but kept their exact title
app = FastAPI(title="LumaWalk - Virtual Buddy API", lifespan=lifespan)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows Member 4's frontend to connect from any local port
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the modular router onto the main app
app.include_router(buddy_router, prefix="/api/v1/buddy", tags=["Virtual Buddy"])

# --- ADDED FOR ROUTING ENGINE (Mounting Your Endpoint) ---
app.include_router(routing_router, prefix="/api/v1/route", tags=["Routing Engine"])
# ---------------------------------------------------------

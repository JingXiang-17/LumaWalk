from fastapi import FastAPI
from buddy_service.router import router as buddy_router

<<<<<<< HEAD
# --- ADDED FOR ROUTING ENGINE (Imports & Memory Loading) ---
from contextlib import asynccontextmanager
import networkx as nx
from routing_service.router import router as routing_router
from routing_service import algo

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        algo.route_graph = nx.read_graphml("campus_network.graphml")
        print("Success: Map data loaded into memory!")
    except FileNotFoundError:
        print("Waiting for Member 1's file. Loading the 10-node dummy map instead.")
        algo.route_graph = algo.create_dummy_graph() 
    yield 
    algo.route_graph.clear()
# -----------------------------------------------------------

# Added lifespan=lifespan here, but kept their exact title
app = FastAPI(title="LumaWalk - Virtual Buddy API", lifespan=lifespan)

=======
app = FastAPI(title="LumaWalk - Virtual Buddy API")

>>>>>>> 136fc216d86f686d71f29f0f487367d1c3c43bc5
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows Member 4's frontend to connect from any local port
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the modular router onto the main app
<<<<<<< HEAD
app.include_router(buddy_router, prefix="/api/v1/buddy", tags=["Virtual Buddy"])

# --- ADDED FOR ROUTING ENGINE (Mounting Your Endpoint) ---
app.include_router(routing_router, prefix="/api/v1/route", tags=["Routing Engine"])
# ---------------------------------------------------------
=======
app.include_router(buddy_router, prefix="/api/v1/buddy", tags=["Virtual Buddy"])
>>>>>>> 136fc216d86f686d71f29f0f487367d1c3c43bc5

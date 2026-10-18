from fastapi import FastAPI
from buddy_service.router import router as buddy_router

app = FastAPI(title="LumaWalk - Virtual Buddy API")

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
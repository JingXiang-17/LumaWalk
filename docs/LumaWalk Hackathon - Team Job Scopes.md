# **LumaWalk Hackathon \- Team Job Scopes & Workload Distribution**

# **Member 1: The Offline Data Pipeline (Data Engineering)**

**Job Scope:** Transforming messy, real-world OpenStreetMap (OSM) data into a clean, routable mathematical graph enriched with safety metadata (e.g., lighting, safe havens). Creates the static graph file consumed by the API.

Tech Stack: Python, OSMnx, GeoPandas, Shapely, PostGIS (optional).

## **Features & PRD Sections**

* **Features:** Ambient Safety Scoring, Safe Haven Routing.  
* **PRD Sections:** Section 8 (Data Models & Database Schemas), Section 10 (Limitations & Project Risks), Section 11 (Demo Truthfulness).  
* **Math & Calculations:** Responsible for topological graph construction and spatial buffering math (e.g., calculating 30-50 meter geometric radius polygons around Safe Havens).

## **Do's and Don'ts**

* **DO** ensure the output is a single portable file (e.g., `campus_network.graphml`) for easy handoff.  
* **DO** apply heuristic patching (Day 0 Patch) to simulate lighting data where OSM is sparse.  
* **DON'T** build any APIs or web servers; focus strictly on offline data preparation and algorithmic spatial tagging.

# **Member 2: The Routing Engine (API Lead)**

**Job Scope:** Building the core mathematical pathfinding logic (cost functions handling safety parameters, detour bounds) and exposing it as a fast REST endpoint. You define the "API-as-a-Product" logic.

Tech Stack: Python, FastAPI, NetworkX, Uvicorn, Pydantic.

## **Features & PRD Sections**

* **Features:** Explainable Safety Routing, B2B Township API.  
* **PRD Sections:** Section 1 (Innovation Claim), Section 8 (Data Models \- Route Response Schema), Section 9 (7-Day Sprint \- Day 3: Routing Math).  
* **Math & Calculations:** Responsible for the core pathfinding algorithms. This includes the Composite Safety Factor calculation (\$S(e)\$), the modified A\* cost function (\$C(e)\$), and the Maximum Detour Constraint logic (e.g., ensuring safe route length ≤ 125% of direct route).

## **Do's and Don'ts**

* **DO** start testing pathfinding logic immediately on a tiny 10-node dummy graph (Don't wait for Member 1's final data).  
* **DO** structure responses to include explainable metrics (e.g., % lit, detour time).  
* **DON'T** overcomplicate the database; memory-loading the GraphML on startup is perfectly fine for a sprint demo.

# **Member 3: Virtual Buddy API (State & Telemetry)**

**Job Scope:** Building the real-time monitoring system, telemetry ingestion, state machines, spatial deviation triggers, and simulated emergency alerts. Treats the user as a moving coordinate dot.

Tech Stack: Python, FastAPI, Shapely (for cross-track distance).

## **Features & PRD Sections**

* **Features:** Virtual Buddy, Active Route Monitoring.  
* **PRD Sections:** Section 5 (Virtual Buddy API & Deviation Logic), Section 8 (Data Models \- Request Logs / PDPA Compliance), Section 11 (Demo Truthfulness \- Emergency Alert Dispatch).  
* **Math & Calculations:** Responsible for spatial deviation math, specifically the cross-track error calculation (computing the perpendicular distance in meters between live GPS coordinates and the active route polyline).

## **Do's and Don'ts**

* **DO** lock in your JSON request/response schema with Member 4 on Hour 1\.  
* **DO** use hardcoded route polylines to test cross-track deviation logic in isolation.  
* **DON'T** tightly couple your code with Member 2's routing engine; keep this as an independent router/module.

# **Member 4: Frontend Web/App Demo (Flutter Integration)**

**Job Scope:** Building the split-screen dashboard using Flutter (compiling to web/desktop) to visualize the backend math. This includes rendering the map canvas on one side and a JSON/telemetry inspector on the other to prove the API works.

**Tech Stack:** Flutter, `flutter_map`, `latlong2`, `http`/`dio`, Provider/Riverpod.

## **Features & PRD Sections**

* **Features:** B2B Developer Dashboard, Visual Explainability.  
* **PRD Sections:** Section 7 (Web App & Demo Interface Specifications), Section 9 (7-Day Sprint \- Day 6 Validation & Demo).  
* **Math & Calculations:** Responsible for UI-side visualization math, such as interpolating coordinates for the 'Simulate Walk' marker animation.

## **Do's and Don'ts**

* **DO** use a dark map tile base (Nighttime Theme) so neon safe routes (Cyan) and unsafe routes (Crimson) visually pop.  
* **DO** build the UI components with static, mock JSON files first before attempting live API integration.  
* **DO** utilize AI for micro-components (like a 20s countdown modal), but assemble them into the widget tree yourself.  
* **DON'T** get stuck perfecting UI styling if you are running out of time; prioritize the JSON inspector and map markers over aesthetics.


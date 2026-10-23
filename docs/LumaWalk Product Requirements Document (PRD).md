# **LumaWalk: Safety-Aware Routing & Spatial Intelligence Engine**

# **Product Requirements Document (PRD)**

> **Implementation status (2026-10):** This document includes the original
> product vision and planned roadmap. The current demo uses a Petaling Jaya
> GraphML graph loaded by NetworkX, FastAPI, Flutter Map, local safe-haven
> GeoJSON, and in-memory session state. PostgreSQL/PostGIS, MapLibre,
> authentication, crowdsourced reports, production dispatch, and multi-tenant
> analytics remain planned rather than implemented.

# **1\. Project Overview & Problem Statement**

## **Executive Summary**

LumaWalk is a safety-aware routing engine and API suite designed to optimize pedestrian navigation for master-planned townships and smart communities. Traditional navigation systems default to the shortest path, frequently routing pedestrians through poorly lit or isolated corridors. LumaWalk dynamically calculates optimal paths using a weighted safety cost matrix, incorporating lighting infrastructure, crowdsourced incidents, and verified Safe-Haven Points of Interest (POIs).

## **The Innovation Claim (Why not just Google Maps?)** 

Unlike generic consumer navigation apps (e.g., Google Maps) or standalone safety auditing apps (e.g., Safetipin), LumaWalk is designed as a **B2B API for township operators**. It utilizes township-owned infrastructure data, provides a proprietary dashboard for operators to visualize spatial risks, and uses a transparent, tunable safety scoring algorithm rather than a black-box model. 

## **Problem Context**

* **The Shortest Path Fallacy**: Standard routing engines prioritize Euclidean distance, ignoring safety context like lighting or isolation.  
* **Cyclical Nighttime Risks**: Vulnerability spikes in dynamic "dark zones"—areas with broken streetlights or closed commercial fronts.  
* **Lack of Township Safety Integration**: Property developers and smart-city operators build "Super Apps" for residents but lack plug-and-play APIs to inject safety-aware routing into these community platforms.

## **Target Personas**

* **End Users (Residents & Students)**: Require reliable, well-lit walking routes within their community, live path deviation monitoring (Virtual Buddy), and access to safe shelter locations.  
* **B2B Clients (Township Operators & Developers)**: Require an API to embed safety routing in resident apps, plus spatial analytics dashboards to identify infrastructure deficits (e.g., broken streetlights) and optimize security patrols.

## **Success Criteria & KPIs**

* **Detour:** safe route ≤ 125% of direct route length (enforced by stepped-alpha fallback).   
* **Safety gain:** over 200 random origin-destination pairs in the pilot area, report mean lit-share and mean active-share of the safe vs direct route, mean detour %, and % of pairs where the cap forced a lower alpha. Use a paired test (Wilcoxon). "Lit" \= segments with W\_light ≥ 0.9. "Active" \= segments with W\_haven ≥ 0.5 (within 150 m of an open safe haven).   
* **Virtual Buddy (target):** path-drift \>35 m detected within 30 s in simulated walks; false check-in prompts ≤ 5 per 100 simulated walks. The current backend implementation uses a 50 m deviation threshold and 180-second stationary threshold.
* **Demo-scale latency (target):** the current route endpoint is `/api/v1/route/`; latency benchmarking remains a validation task.

## **Theme Alignment (Hackathon Pillars)**

* **People (Primary):** Promotes inclusive mobility, community connection, and personal safety by ensuring residents can navigate their environment confidently at night.

---

# **2\. System Architecture & Tech Stack Specifications**

Optimized for a 7-day rapid implementation sprint.

* **Backend API Framework**: Python (FastAPI) \- For native async processing and scientific/spatial library integration.  
* **Database & Spatial Engine (planned)**: PostgreSQL 16 \+ PostGIS 3.4 \- For future spatial indexing (GIST) and topological queries. The current demo uses GraphML loaded into NetworkX in memory.  
* **Routing Graph Engine**: NetworkX (Python) \- Enables real-time dynamic edge-weight recalculations.  
* **Frontend Framework**: Flutter \- For the dual-panel web demo.  
* **Map Rendering Library**: Flutter Map with OpenStreetMap tiles in the current client. MapLibre GL JS remains an alternative for a future web-specific client.  

---

# **3\. Geospatial Data Ingestion & Enrichment Pipeline**

## **Base Map Sourcing & Day 0 Data Patch**

Base network data is extracted from OpenStreetMap (OSM) PBF extracts using **Pyrosm** or **osm2pgsql**.  
*Data Realism Patch:* Because `lit=yes & lit=no` tags are sparse in Malaysian OSM data, the engineering team will perform a "Day 0 Patch" by loading the pilot township extract into QGIS, manually flagging primary walking corridors with `lit=yes`, and seeding 15 realistic guardhouses/marts.

## **Safe-Haven POI Database Schema & Classification (confirmed can)(using OSM)(but not sure how)(implement?)**

* **CLASS\_A**: 24/7 Monitored Infrastructure (Police Stations, Hospitals, Guardhouses).  
* **CLASS\_B**: Verified Late-Night Commercial (24-hour Pharmacies, Convenience Stores).  
* **CLASS\_C**: Community Partner Safe Zones (monitored transit hubs, clubhouse reception, township security booths). 

---

# **4\. Core Algorithm & Routing Engine Mechanics**

## **Graph Representation**

The network is a directed graph \$G \= (V, E)\$. Each edge \$e\$ has:

* \$L(e)\$: Physical length in meters.  
* \$S(e)\$: Composite Safety Factor, clamped strictly within \$\[0.1, 1.0\]\$.

## **Mathematical Safety Cost Function**

The total edge traversal cost \$C(e)\$ guarantees admissibility for A\* search:  
\$\$ C(e) \= L(e) \\times \\left(1 \+ \\alpha \\cdot \\left(1 \- S(e)\\right)^\\beta \\right) \$\$  
**Safety Factor Calibration & Clamping:**  
\$\$ S\_{raw} \= (0.5 \\cdot W\_{light}) \+ (0.2 \\cdot W\_{crowd}) \+ (0.3 \\cdot W\_{haven}) \- (0.6 \\cdot W\_{hazard}) \$\$  
\$\$ S(e) \= \\max(0.1, \\min(1.0, S\_{raw})) \$\$  
*\*(Where \$\\alpha \= 2.5\$, \$\\beta \= 2.0\$, and \$W\$ inputs are normalized \$0.0 \- 1.0\$)\**

## **Dual-Path Routing & Detour Cap**

The engine calculates both the Direct Route (\$\\alpha=0\$) and the LumaWalk Safe Route (\$\\alpha=2.5\$).

* **Maximum Detour Constraint:** If \$L\_{safe} \> L\_{direct} \\times 1.25\$, the engine rejects the safe route and falls back to the direct route to prevent unrealistic detours.

---

# **5\. API Specification & System Contracts**

## **Core REST Endpoints**

**POST /api/v1/route/** (Implemented; calculates dual routes and route metrics)

```json
{
  "routes": {
    "lumawalk_safe": {
      "distance_meters": 1382.5,
      "explainability": {
        "safety_gain_relative_pct": "+47.1%",
        "extra_distance_meters": 142.0,
        "key_factors": ["Utilized 85% illuminated segments vs 32% on direct route."]
      }
    }
  }
}
```

**GET /v1/safe-havens/near** (Planned; the current frontend reads local GeoJSON markers)

```
Queries nearest operational safe havens relative to a given point.
Query Parameters: 
- lat (float, required): Latitude 
- lng (float, required): Longitude 
- radius_meters (int, optional): Search radius (default 500m) 
- class (string, optional): Filter by CLASS_A, CLASS_B, CLASS_C 
```

**POST /v1/reports/crowd** (Planned; no crowd-report endpoint is currently implemented)  
(Submits crowdsourced safety feedback (e.g., broken lights, active hazards).// Request Body )

```json
{
 "location": { "lat": 37.776102, "lng": 122.417382 }, 
 "hazard_type": "LIGHTING_FAILURE", 
 "severity": "HIGH", 
 "description": "All streetlights out on 8th Street block." 
}
```

## **Machine-Readable Error Handling**

Errors follow RFC 9457 Problem Details standards, including `Retry-After` headers for rate limits.  
---

# **6\. Interactive Features & Stateful Logic**

## **Virtual Buddy (Shadow Walk) Escalation State Machine**

* **Target state machine**: User stays within 35m of the route, then receives a check-in prompt after deviation or a stationary period. This remains the product target.  
* **Current backend behavior**: The implemented service starts an in-memory session, uses a 50m deviation threshold or a gap of more than 180 seconds between pings, returns `WARNING_DEVIATED` or `WARNING_STATIONARY`, and logs a simulated emergency dispatch in a background task. The stationary check does not compare successive ping positions for movement.
* **Frontend demo behavior**: During navigation, the Flutter app prompts after three minutes without meaningful movement. If the user does not confirm they are safe within 20 seconds, local SOS mode activates. These local simulation, SOS, hazard, and check-in flows are not connected to a production alert service.
  * *If "I'm Safe" clicked:* Resolves to State 1\.  
  * *If 20s expires:* Moves to State 4\. Backend sends  `CRITICAL`  
* **State 4 (Alert Dispatch)**: Backend retrieves the user's `trusted_contacts` record and dispatches an emergency Webhook/SMS with the exact location.

## **/\* Safe-Haven Finder (KNN Spatial Search)**

Utilizes PostGIS `ST_DistanceSphere` for accurate metric calculation:

```sql
SELECT id, name, category, location,
       ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)) AS distance_meters
FROM safe_havens
WHERE is_active = TRUE
ORDER BY location <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
LIMIT 5;
```

## **Crowdsourced Safety Refinement (Bayesian Decay)**

To prevent abuse, crowd reports use a bounded logistic decay function:  
\$\$ C(t) \= \\min\\left(1.0, \\left(C\_0 \\cdot e^{-0.05 t}\\right) \+ (0.1 \\cdot N\_{corroborations})\\right) \$\$  
\*/  
---

# **7\. Web App & Demo Interface Specifications (UI/UX/DX)**

## **Two-Panel Split-Screen Layout**

* **Left Panel (Interactive Map \- Flutter Map)**: Displays Direct vs. Safe routes and local safe-haven POIs.  
* **Right Panel (Live API JSON Inspector)**: Real-time request/response payloads, Alpha slider, and Time-of-Day simulator.

## **Safety Check-In & Trusted Contact Views**

* **Safety Check-In Modal (demo target)**: A high-contrast popup with a visual countdown ring and an "I am Safe" button. The current frontend flow is local simulation.  
* **Trusted Contact View**: A mock secondary view showing what the emergency contact receives (a locked map with a pulsing red deviation indicator).

## **/\*B2B Township Insights Dashboard**

Focuses on property developers: displays infrastructure deficit heatmaps (dark zones where users frequently reroute) to guide facility management and security patrols.\*/  
---

# **8\. Data Models & Database Schemas**

## **PostgreSQL / PostGIS DDL Specifications (Excerpts)**

* **API Keys & Tenants**: Standard auth tables.  
* **Safe Havens & Crowd Reports**: Geographic points indexed with `GIST(location)`.  
* **Trusted Contacts**:  
  * `id UUID, user_id UUID, contact_name VARCHAR, contact_endpoint VARCHAR`  
* **Request Logs (PDPA Compliance):**  
  * `origin_location GEOMETRY, destination_location GEOMETRY`  
  * *Privacy Note:* Designed with Malaysian Personal Data Protection Act (PDPA) principles in mind (e.g., a background cron job truncates coordinate precision to 3 decimal places (\~100m) after 24 hours to prevent individual tracking). A full legal review is needed for production.

---

# **9\. 7-Day Sprint Implementation Roadmap**

* **Day 1: Foundation**: PostGIS setup, Pyrosm data ingestion, manual QGIS `lit=yes` and `lit=no` data patch, and database schema creation. Measure and report the share of walkable edges with a lit tag before patching. All patched values and seeded POIs are labelled MOCK in the demo.   
* **Day 2: Algorithm**: NetworkX graph building, dual-path A\* engine, and clamped mathematical cost function.  
* **Day 3: API Gateway**: FastAPI endpoints, mock middleware, explainability metrics, and JSON contracts.  
* **Day 4: Map Demo**: MapLibre integration, split-screen layout, and polyline rendering.  
* **Day 5: Stateful Logic**: Virtual Buddy spatial deviation buffer, 20-second state machine, and Trusted Contact View.  
* **Day 6: Validation & Integration (The Proof):** Perform batch KPI runs on the pilot area (verifying detour % and lit-segment share). Conduct false-alarm simulation for Virtual Buddy. Resolve map rendering/CORS bugs. *(If time permits, tie in the B2B Township Dashboard).*   
* **Day 7: Rehearsal**: Hardcode presentation coordinates and polish the pitch deck.

---

# **10\. Limitations & Project Risks**

* **Sparse Data Reality:** Map completeness relies heavily on OpenStreetMap tags, which lack comprehensive and up-to-date municipal lighting data.  
* **GPS Drift & OS Constraints:** Urban canyons and mobile OS background-tracking throttling can cause severe GPS inaccuracy, complicating the reliability of the 35m deviation threshold.  
* **Proxy Metric Dependency:** The safety score is a logical proxy based on lighting and POIs; it remains unvalidated against actual historical crime incident datasets.  
* **Privacy:** Storing real-time origin/destination telemetry is inherently high-risk and requires strict, audited data sanitization.

---

# **11\. Demo Truthfulness (Real vs. Mock Data)**

To maintain transparency with technical judges, the following elements are explicitly defined as real computation versus mock data.

| Component | Status | Description |
| :---- | :---- | :---- |
| **Routing Graph & Pathfinding** | **REAL** | Extracted from real OpenStreetMap topology; algorithm computes live routes. |
| **API Gateway & JSON Explainability** | **REAL** | Network requests, latency, payload generation, and JSON metrics are generated dynamically. |
| **Streetlight (lit=yes) Data** | **MOCK** | Patched manually via QGIS for the pilot area to simulate municipal data. |
| **Safe Haven POIs  /\**& Crowd Reports\**/** | **REAL / MOCK** | Seeded manually (approx. 15 locations) to demonstrate the algorithm. |
| **Virtual Buddy GPS Movement** | **SIMULATED** | Coordinates follow the polyline programmatically for the demo (not a real person walking). |
| **Emergency Alert Dispatch** | **MOCK** | Simulated via a terminal console log or webhook ping (no actual paid SMS gateway integrated). |

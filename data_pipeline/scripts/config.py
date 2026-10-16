"""Shared settings for the LumaWalk data pipeline. Change values here, not in the scripts."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT / "output"
DATA_DIR = ROOT / "data"
OUTPUT_DIR.mkdir(exist_ok=True)

PLACE_NAME = "Petaling Jaya"

# OSM way tags to keep. OSMnx drops 'lit' by default, so it must be added explicitly.
EXTRA_WAY_TAGS = ["lit", "surface", "footway", "sidewalk"]

# --- W_light (PRD section 3 fallback heuristic; these are tunable assumptions) ---
LIT_TAG_TO_W = {            # OSM lit=* values
    "yes": 1.0, "24/7": 1.0, "automatic": 1.0, "sunset-sunrise": 1.0,
    "limited": 0.5,
    "no": 0.0, "disused": 0.0,
}
MAJOR_ROADS = {"primary", "secondary", "tertiary", "primary_link", "secondary_link", "tertiary_link"}
HEURISTIC_MAJOR = 0.6       # untagged major road
HEURISTIC_OTHER = 0.1       # untagged anything else (night default)

# --- W_haven ---
HAVEN_RADIUS_M = 300        # score falls linearly from 1 (at the haven) to 0 (at this distance)
CLASS_MULTIPLIER = {"A": 1.0, "B": 0.8, "C": 0.8}

# --- neutral defaults until crowd reports exist ---
W_CROWD_DEFAULT = 0.5
W_HAZARD_DEFAULT = 0.0

# GraphML round-trips custom attributes as strings unless told otherwise.
# Pass this to ox.load_graphml(..., edge_dtypes=EDGE_DTYPES) everywhere the graph is read (including routing code).
EDGE_DTYPES = {"w_light": float, "w_haven": float, "w_crowd": float, "w_hazard": float}
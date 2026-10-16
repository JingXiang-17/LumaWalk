"""Compute W_haven (distance-based), set neutral W_crowd/W_hazard, validate, and export."""
import json
import re
import time

import geopandas as gpd
import networkx as nx
import numpy as np
import osmnx as ox
import pandas as pd
from config import (DATA_DIR, OUTPUT_DIR, HAVEN_RADIUS_M, CLASS_MULTIPLIER,
                    W_CROWD_DEFAULT, W_HAZARD_DEFAULT, EDGE_DTYPES)

ox.settings.use_cache = True
ox.settings.overpass_url = "https://overpass.kumi.systems/api"   # base URL, no /interpreter
ox.settings.overpass_rate_limit = True    # already the default: waits for a free slot
ox.settings.requests_timeout = 180        # already the default; keep it only to make the value visible

# NEW: servers tried in order when one fails (base URLs, no /interpreter). Check they are up.
SERVERS = [
    "https://overpass.private.coffee/api",
    "https://overpass-api.de/api",
]


def fetch_features(place, tags, tries=3):
    """NEW: features_from_place with retry/backoff, then fall back to the next server."""
    last = None
    for url in SERVERS:
        ox.settings.overpass_url = url
        for i in range(tries):
            try:
                return ox.features_from_place(place, tags=tags)
            except ox._errors.InsufficientResponseError:     # nothing found: a valid answer, don't retry
                return gpd.GeoDataFrame(geometry=[], crs="EPSG:4326")
            except Exception as e:                           # 500 / 429 / 504 / timeouts
                last = e
                print(f"{url} try {i + 1}/{tries} failed: {type(e).__name__}")
                time.sleep(5 * 2 ** i)                       # waits 5 s, 10 s, 20 s
    raise RuntimeError("All Overpass servers failed. Wait a few minutes and run again.") from last


def load_real_havens_from_osm(place_name):
    # NEW: reuse the saved result instead of downloading again (the file name includes the place,
    # so changing PLACE_NAME never silently reuses another area's data).
    slug = re.sub(r"[^a-z0-9]+", "_", place_name.lower()).strip("_")
    cache_file = OUTPUT_DIR / f"real_havens_{slug}.geojson"
    if cache_file.exists():
        print(f"Using saved havens: {cache_file.name} (delete the file to download again)")
        return gpd.read_file(cache_file)

    print(f"Downloading real POIs for {place_name}...")

    tags = {
        'amenity': ['police', 'hospital', 'clinic', 'college'],
        'shop': ['convenience']
    }

    pois = fetch_features(place_name, tags)                  # CHANGED: was ox.features_from_place(...)
    if pois.empty:
        raise SystemExit(f"No POIs found for {place_name}. Check the place name or the tags.")

    def assign_class(row):
        # Safely extract the hours tag
        hours = str(row.get('opening_hours', '')).lower().strip()

        # 1. Explicit 24/7 tag or inherently 24/7 facilities = Class A
        if '24/7' in hours or row.get('amenity') in ['police', 'hospital']:
            return 'A'
        # 2. Convenience stores without explicitly tagged hours = Class B
        elif row.get('shop') == 'convenience':
            return 'B'
        # 3. Daytime or standard hours = Class C
        else:
            return 'C'

    pois['class'] = pois.apply(assign_class, axis=1)
    # Project to flat meters, find the exact center, then project back to GPS coordinates
    pois['geometry'] = pois.to_crs(pois.estimate_utm_crs()).geometry.centroid.to_crs("EPSG:4326")

    havens = pois[['geometry', 'class']]
    havens.to_file(cache_file, driver="GeoJSON")             # NEW: save for next run
    print(f"Saved {len(havens)} havens to {cache_file.name}")
    return havens


def compute_w_haven(edges, havens):
    """W_haven = max over havens of class_multiplier * max(0, 1 - d / R), d measured from the edge midpoint."""
    utm = edges.estimate_utm_crs()                      # metric CRS chosen from the data itself
    mids = edges.to_crs(utm).geometry.interpolate(0.5, normalized=True)
    hv = havens.to_crs(utm)
    scores = np.zeros(len(edges))
    for geom, cls in zip(hv.geometry, hv["class"]):
        d = mids.distance(geom).to_numpy()
        s = CLASS_MULTIPLIER.get(cls, 0.8) * np.clip(1 - d / HAVEN_RADIUS_M, 0, 1)
        scores = np.maximum(scores, s)
    return pd.Series(scores, index=edges.index)


def validate(edges):
    for col in ("w_light", "w_haven", "w_crowd", "w_hazard"):
        vals = pd.to_numeric(edges[col])
        assert vals.notna().all(), f"{col} has missing values"
        assert vals.between(0, 1).all(), f"{col} outside [0, 1]"
    assert (pd.to_numeric(edges["length"]) > 0).all(), "non-positive edge length"


def main():
    G = ox.load_graphml(OUTPUT_DIR / "02_lit_network.graphml", edge_dtypes=EDGE_DTYPES)
    from config import PLACE_NAME
    havens = load_real_havens_from_osm(PLACE_NAME)

    edges = ox.graph_to_gdfs(G, nodes=False)            # geometry is filled in for straight edges too
    w_haven = compute_w_haven(edges, havens)

    nx.set_edge_attributes(G, w_haven.to_dict(), "w_haven")
    nx.set_edge_attributes(G, W_CROWD_DEFAULT, "w_crowd")
    nx.set_edge_attributes(G, W_HAZARD_DEFAULT, "w_hazard")

    edges = ox.graph_to_gdfs(G, nodes=False)            # re-read with all attributes
    validate(edges)

    summary = {
        "edges": len(edges),
        "edges_with_w_haven_gt_0": int((edges["w_haven"] > 0).sum()),
        "edges_with_w_haven_ge_0.5": int((edges["w_haven"] >= 0.5).sum()),
        "share_w_light_ge_0.9": round(float((edges["w_light"] >= 0.9).mean()), 3),
    }
    print(json.dumps(summary, indent=2))

    ox.save_graphml(G, filepath=OUTPUT_DIR / "pj_network.graphml")   # real edge geometry is kept

    cols = ["osmid", "highway", "length", "w_light", "lit_source", "w_haven", "w_crowd", "w_hazard", "geometry"]
    flat = edges[cols].copy()
    flat["osmid"] = flat["osmid"].astype(str)
    flat["highway"] = flat["highway"].astype(str)
    flat.to_file(OUTPUT_DIR / "pj_edges.geojson", driver="GeoJSON")  # open in QGIS / MapLibre to eyeball
    print("Saved pj_network.graphml and pj_edges.geojson")


if __name__ == "__main__":
    main()
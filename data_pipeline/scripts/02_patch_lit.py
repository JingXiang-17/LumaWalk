"""Assign W_light to every edge, with provenance.

Priority: manual QGIS override > OSM lit tag > deterministic heuristic.
No random values: results must be reproducible, and a lit-share KPI computed on random
labels would be meaningless.
"""
import csv
import json
from collections import Counter

import osmnx as ox
from config import (DATA_DIR, OUTPUT_DIR, LIT_TAG_TO_W, MAJOR_ROADS,
                    HEURISTIC_MAJOR, HEURISTIC_OTHER)


def as_list(value):
    """Simplified OSMnx edges hold a list when several OSM ways were merged."""
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def load_overrides(path):
    """CSV columns: osmid, lit  (lit = yes/no). Exported from the manual QGIS patch."""
    overrides = {}
    if path.exists():
        with open(path, newline="") as f:
            for row in csv.DictReader(f):
                overrides[str(row["osmid"]).strip()] = row["lit"].strip().lower()
    return overrides


def tag_to_w(values):
    """Map lit tag value(s) to W_light. If merged ways disagree, take the darkest (conservative)."""
    ws = [LIT_TAG_TO_W[v] for v in map(str, values) if v in LIT_TAG_TO_W]
    return min(ws) if ws else None


def w_light_for_edge(data, overrides):
    osmids = [str(o) for o in as_list(data.get("osmid"))]
    manual = [LIT_TAG_TO_W[overrides[o]] for o in osmids if overrides.get(o) in LIT_TAG_TO_W]
    if manual:
        return min(manual), "manual"
    tagged = tag_to_w(as_list(data.get("lit")))
    if tagged is not None:
        return tagged, "osm"
    highways = set(as_list(data.get("highway")))
    return (HEURISTIC_MAJOR if highways & MAJOR_ROADS else HEURISTIC_OTHER), "heuristic"


def apply_patch(G, overrides):
    sources = Counter()
    for _, _, _, data in G.edges(keys=True, data=True):
        w, src = w_light_for_edge(data, overrides)
        data["w_light"] = w          # the original 'lit' tag is left untouched
        data["lit_source"] = src
        sources[src] += 1
    return sources


def main():
    G = ox.load_graphml(OUTPUT_DIR / "01_raw_network.graphml")  # raw graph has no custom numeric attrs yet
    overrides = load_overrides(DATA_DIR / "lit_overrides.csv")
    sources = apply_patch(G, overrides)

    total = sum(sources.values())
    report = {
        "edges_total": total,
        "edges_by_source": dict(sources),
        "share_with_real_osm_lit_tag": round(sources["osm"] / total, 3) if total else 0,
        "share_manual_override": round(sources["manual"] / total, 3) if total else 0,
        "share_heuristic": round(sources["heuristic"] / total, 3) if total else 0,
    }
    (OUTPUT_DIR / "lit_coverage_report.json").write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))

    out = OUTPUT_DIR / "02_lit_network.graphml"
    ox.save_graphml(G, filepath=out)
    print(f"Lighting patch applied. Saved: {out}")


if __name__ == "__main__":
    main()
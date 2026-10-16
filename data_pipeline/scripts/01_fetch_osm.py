import osmnx as ox
from config import PLACE_NAME, OUTPUT_DIR, EXTRA_WAY_TAGS


def main():
    ox.settings.use_cache = True
    # Without this, the 'lit' tag is silently discarded and every edge looks untagged.
    ox.settings.useful_tags_way = sorted(set(ox.settings.useful_tags_way) | set(EXTRA_WAY_TAGS))

    print(f"Fetching walking network for: {PLACE_NAME} ...")
    G = ox.graph_from_place(PLACE_NAME, network_type="walk")

    # Keep one strongly connected component so every origin/destination pair is routable.
    n_before = len(G)
    G = ox.truncate.largest_component(G, strongly=True)
    print(f"Nodes: {n_before} -> {len(G)} after keeping the largest connected component")

    out = OUTPUT_DIR / "01_raw_network.graphml"
    ox.save_graphml(G, filepath=out)
    print(f"Raw network saved: {out}")


if __name__ == "__main__":
    main()
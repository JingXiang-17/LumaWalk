import osmnx as ox
from config import OUTPUT_DIR, EDGE_DTYPES

def main():
    # Safely construct the exact path using your config file
    graph_path = OUTPUT_DIR / "campus_network.graphml"
    
    print(f"Looking for graph at: {graph_path}")
    
    # Load with edge_dtypes so w_light and w_haven are read as floats, not strings!
    G = ox.load_graphml(graph_path, edge_dtypes=EDGE_DTYPES)

    # Print the data of the first 5 edges to verify attributes exist
    for i, (u, v, key, data) in enumerate(G.edges(keys=True, data=True)):
        print(f"Edge {u}->{v} | Length: {data.get('length')}m | W_Light: {data.get('w_light')} | W_Haven: {data.get('w_haven')}")
        if i == 4:
            break

if __name__ == "__main__":
    main()
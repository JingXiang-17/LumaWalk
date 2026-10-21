import networkx as nx
import math

route_graph = None

def edge_attributes(data):
    if data and all(isinstance(value, dict) for value in data.values()):
        return next(iter(data.values()))
    return data

def create_dummy_graph():
    G = nx.Graph()
    for i in range(1, 11):
        G.add_node(i, y=3.12 + (i*0.001), x=101.65 + (i*0.001))
    G.add_edge(1, 2, length=50, is_lit=True, safety_score=0.9)
    G.add_edge(2, 3, length=100, is_lit=False, safety_score=0.2)
    G.add_edge(1, 3, length=120, is_lit=True, safety_score=0.8)
    G.add_edge(3, 4, length=40, is_lit=True, safety_score=0.95)
    G.add_edge(4, 5, length=200, is_lit=False, safety_score=0.1)
    G.add_edge(2, 5, length=150, is_lit=True, safety_score=0.85)
    G.add_edge(5, 6, length=60, is_lit=True, safety_score=0.9)
    G.add_edge(6, 7, length=80, is_lit=False, safety_score=0.3)
    G.add_edge(7, 8, length=110, is_lit=True, safety_score=0.8)
    G.add_edge(8, 9, length=90, is_lit=True, safety_score=0.85)
    G.add_edge(9, 10, length=30, is_lit=True, safety_score=0.9)
    G.add_edge(4, 8, length=130, is_lit=False, safety_score=0.4)
    G.add_edge(6, 10, length=170, is_lit=True, safety_score=0.7)
    return G

def custom_safety_cost(u, v, d):
    edge_data = edge_attributes(d)
    
    distance = float(edge_data.get('length', 1.0))
    if edge_data.get('lighting_failure', False):
        return distance * 1_000_000

    w_light = float(edge_data.get('w_light', 0.1))
    w_haven = float(edge_data.get('w_haven', 0.1))
    safety_score = (w_light + w_haven) / 2
    
    safe_s = max(safety_score, 0.01) 
    return distance / safe_s

def find_safest_route(
    G, start_node, end_node, *, allow_longer_safe_detour=False
):
    weight_fn = lambda u, v, d: float(
        edge_attributes(d).get('length', 1.0)
    )
    direct_distance = nx.shortest_path_length(G, start_node, end_node, weight=weight_fn)
    max_allowed_distance = direct_distance * 1.25
    
    safe_path = nx.shortest_path(G, start_node, end_node, weight=custom_safety_cost)
    
    safe_distance = 0
    for i in range(len(safe_path) - 1):
        u = safe_path[i]
        v = safe_path[i+1]
        # Bypass the string/int key issue by forcing a list conversion
        edge_data = edge_attributes(G[u][v])
        safe_distance += float(edge_data.get('length', 0.0))
        
    if safe_distance > max_allowed_distance and not allow_longer_safe_detour:
        return nx.shortest_path(G, start_node, end_node, weight=weight_fn), direct_distance
        
    return safe_path, safe_distance

def apply_lighting_failures(G, failure_points):
    """Return a request-local graph copy with edges beside failed lamps disabled."""
    if not failure_points:
        return G

    affected_nodes = {
        get_closest_node(G, latitude, longitude)
        for latitude, longitude in failure_points
    }
    affected_nodes.discard(None)
    graph = G.copy()

    if graph.is_multigraph():
        edges = list(graph.edges(keys=True))
        for start, end, key in edges:
            if start in affected_nodes or end in affected_nodes:
                edge_data = graph[start][end][key]
                edge_data['w_light'] = 0.0
                edge_data['lighting_failure'] = True
    else:
        for start, end in list(graph.edges()):
            if start in affected_nodes or end in affected_nodes:
                edge_data = graph[start][end]
                edge_data['w_light'] = 0.0
                edge_data['lighting_failure'] = True

    return graph

def get_closest_node(G, lat, lng):
    """Snaps raw GPS coordinates to the nearest valid graph node."""
    closest_node = None
    min_dist = float('inf')
    
    for node, data in G.nodes(data=True):
        # Fallback to 0.0 if the node is missing coordinate data
        node_lat = float(data.get('y', 0.0))
        node_lng = float(data.get('x', 0.0))
        
        # Simple Euclidean distance for coordinate snapping
        dist = math.hypot(node_lat - lat, node_lng - lng)
        if dist < min_dist:
            min_dist = dist
            closest_node = node
            
    return closest_node
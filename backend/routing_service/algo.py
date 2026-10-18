import networkx as nx

route_graph = None

def create_dummy_graph():
    G = nx.Graph()
    G.add_nodes_from(range(1, 11))
    G.add_edge(1, 2, weight=50, is_lit=True, safety_score=0.9)
    G.add_edge(2, 3, weight=100, is_lit=False, safety_score=0.2)
    G.add_edge(1, 3, weight=120, is_lit=True, safety_score=0.8)
    G.add_edge(3, 4, weight=40, is_lit=True, safety_score=0.95)
    G.add_edge(4, 5, weight=200, is_lit=False, safety_score=0.1)
    G.add_edge(2, 5, weight=150, is_lit=True, safety_score=0.85)
    G.add_edge(5, 6, weight=60, is_lit=True, safety_score=0.9)
    G.add_edge(6, 7, weight=80, is_lit=False, safety_score=0.3)
    G.add_edge(7, 8, weight=110, is_lit=True, safety_score=0.8)
    G.add_edge(8, 9, weight=90, is_lit=True, safety_score=0.85)
    G.add_edge(9, 10, weight=30, is_lit=True, safety_score=0.9)
    G.add_edge(4, 8, weight=130, is_lit=False, safety_score=0.4)
    G.add_edge(6, 10, weight=170, is_lit=True, safety_score=0.7)
    return G

def custom_safety_cost(u, v, edge_data):
    distance = edge_data.get('weight', 1)
    safety_score = edge_data.get('safety_score', 0.1)
    safe_s = max(safety_score, 0.01) 
    return distance / safe_s

def find_safest_route(G, start_node, end_node):
    direct_distance = nx.shortest_path_length(G, start_node, end_node, weight='weight')
    max_allowed_distance = direct_distance * 1.25
    
    safe_path = nx.shortest_path(G, start_node, end_node, weight=custom_safety_cost)
    
    safe_distance = 0
    for i in range(len(safe_path) - 1):
        u = safe_path[i]
        v = safe_path[i+1]
        safe_distance += G[u][v]['weight']
        
    if safe_distance > max_allowed_distance:
        return nx.shortest_path(G, start_node, end_node, weight='weight'), direct_distance
        
    return safe_path, safe_distance
import unittest

import networkx as nx

from routing_service import algo
from routing_service.router import get_safe_route
from routing_service.schemas import RouteRequest


class SafeRouteLightingTests(unittest.TestCase):
    def setUp(self):
        self.original_graph = algo.route_graph
        self.addCleanup(self.restore_graph)

    def restore_graph(self):
        algo.route_graph = self.original_graph

    def test_uses_distance_weighted_continuous_lighting_scores(self):
        graph = nx.Graph()
        graph.add_node(1, y=3.10, x=101.60)
        graph.add_node(2, y=3.11, x=101.61)
        graph.add_node(3, y=3.12, x=101.62)
        graph.add_edge(1, 2, length=100, w_light=0.2, w_haven=0.5)
        graph.add_edge(2, 3, length=100, w_light=0.4, w_haven=0.5)
        algo.route_graph = graph

        response = get_safe_route(
            RouteRequest(start_lat=3.10, start_lng=101.60, end_lat=3.12, end_lng=101.62)
        )

        self.assertEqual(response.percentage_lit, 30.0)

    def test_supports_legacy_dummy_graph_lighting_flags(self):
        graph = nx.Graph()
        graph.add_node(1, y=3.10, x=101.60)
        graph.add_node(2, y=3.11, x=101.61)
        graph.add_edge(1, 2, length=100, is_lit=True, safety_score=0.9)
        algo.route_graph = graph

        response = get_safe_route(
            RouteRequest(start_lat=3.10, start_lng=101.60, end_lat=3.11, end_lng=101.61)
        )

        self.assertEqual(response.percentage_lit, 100.0)


if __name__ == "__main__":
    unittest.main()

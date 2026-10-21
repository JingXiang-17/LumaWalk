import unittest

import networkx as nx

from routing_service.algo import apply_lighting_failures, find_safest_route
from routing_service import algo
from routing_service.router import get_safe_route
from routing_service.schemas import RouteRequest


class LightingFailureRoutingTests(unittest.TestCase):
    def setUp(self):
        self.graph = nx.MultiGraph()
        self.graph.add_node(1, y=3.1, x=101.6)
        self.graph.add_node(2, y=3.11, x=101.61)
        self.graph.add_node(3, y=3.12, x=101.62)
        self.graph.add_edge(
            1, 2, length=50, w_light=1.0, w_haven=1.0
        )
        self.graph.add_edge(
            2, 3, length=50, w_light=1.0, w_haven=1.0
        )
        self.graph.add_edge(
            1, 3, length=130, w_light=1.0, w_haven=1.0
        )

    def test_failure_marks_only_the_request_graph_copy(self):
        affected = apply_lighting_failures(self.graph, [(3.11, 101.61)])

        self.assertIsNot(affected, self.graph)
        self.assertTrue(affected[1][2][0]["lighting_failure"])
        self.assertTrue(affected[2][3][0]["lighting_failure"])
        self.assertNotIn("lighting_failure", self.graph[1][2][0])
        self.assertEqual(self.graph[1][2][0]["w_light"], 1.0)

    def test_safe_route_avoids_failed_lights_even_with_a_longer_detour(self):
        affected = apply_lighting_failures(self.graph, [(3.11, 101.61)])

        path, distance = find_safest_route(
            affected,
            1,
            3,
            allow_longer_safe_detour=True,
        )

        self.assertEqual(path, [1, 3])
        self.assertEqual(distance, 130.0)

    def test_route_endpoint_recalculates_without_mutating_shared_graph(self):
        original_graph = algo.route_graph
        algo.route_graph = self.graph
        try:
            response = get_safe_route(
                RouteRequest(
                    start_lat=3.1,
                    start_lng=101.6,
                    end_lat=3.12,
                    end_lng=101.62,
                    lighting_failure_points=[(3.11, 101.61)],
                )
            )
        finally:
            algo.route_graph = original_graph

        self.assertEqual(
            response.safe_route_coords,
            [[3.1, 101.6], [3.12, 101.62]],
        )
        self.assertEqual(response.safe_distance, 130.0)
        self.assertNotIn("lighting_failure", self.graph[1][2][0])
        self.assertEqual(self.graph[1][2][0]["w_light"], 1.0)

    def test_simple_graph_edges_are_supported_too(self):
        simple_graph = nx.Graph(self.graph)
        affected = apply_lighting_failures(simple_graph, [(3.11, 101.61)])

        path, distance = find_safest_route(
            affected,
            1,
            3,
            allow_longer_safe_detour=True,
        )

        self.assertEqual(path, [1, 3])
        self.assertEqual(distance, 130.0)


if __name__ == "__main__":
    unittest.main()

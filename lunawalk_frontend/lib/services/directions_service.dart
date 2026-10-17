class DirectionsService {
  static const double destinationLat = 3.1279;
  static const double destinationLng = 101.6501;
  static const String destinationName = 'UM FSKTM';

  static Future<Map<String, dynamic>> fetchDirections({
    required double alpha,
    required bool avoidUnlit,
    required bool prioritizeHavens,
    required double originLat,
    required double originLng,
    required String originLabel,
  }) async {
    // Simulate API round-trip latency
    await Future.delayed(const Duration(milliseconds: 350));

    // DYNAMIC MOCK DATA: Origin matches real user location, Destination is UM FSKTM
    return {
      "status": "success",
      "engine_version": "mock-route-preview",
      "is_mock": true,
      "route_geometry_type": "straight_line_preview",
      "data": {
        "origin": {
          "lat": originLat,
          "lng": originLng,
          "label": originLabel,
        },
        "destination": {
          "lat": destinationLat,
          "lng": destinationLng,
          "label": destinationName,
        },
        "routes": {
          "lumawalk_safe": {
            "distance_meters": 2450.0,
            "estimated_duration_sec": 1740,
            "overall_safety_score": double.parse(
              (0.78 + (alpha * 0.03)).clamp(0.0, 0.98).toStringAsFixed(2),
            ),
            "explainability": {
              "safety_gain_relative_pct": "+42.3%",
              "extra_distance_meters": 310.0,
              "well_lit_coverage_pct": 86.0,
              "safe_havens_encountered": 3,
              "key_factors": [
                "Prioritized illuminated main pedestrian corridors.",
                "Routed within 40m of verified 24/7 security posts.",
                "Bypassed unlit perimeter pathways."
              ]
            }
          },
          "direct_shortest": {
            "distance_meters": 2140.0,
            "estimated_duration_sec": 1520,
            "overall_safety_score": 0.52,
            "well_lit_coverage_pct": 41.0
          }
        }
      }
    };
  }
}

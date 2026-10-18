import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class OsmSafeHaven {
  const OsmSafeHaven({
    required this.point,
    required this.classification,
    required this.id,
  });
  final LatLng point;
  final String classification;
  final String id;
}

class SafeHavenService {
  static const _havensAsset = 'assets/mock_data/real_havens_petaling_jaya.geojson';

  Future<List<OsmSafeHaven>> loadSafeHavens() async {
    final rawString = await rootBundle.loadString(_havensAsset);
    final decoded = jsonDecode(rawString) as Map<String, dynamic>;
    final havens = <OsmSafeHaven>[];

    for (final feature in decoded['features'] as List<dynamic>) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      
      if (geometry?['type'] == 'Point') {
        final coords = geometry!['coordinates'] as List<dynamic>;
        havens.add(OsmSafeHaven(
          point: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
          classification: '${properties['class'] ?? 'C'}',
          id: '${properties['id'] ?? ''}',
        ));
      }
    }
    return havens;
  }
}

class BackendRoute {
  BackendRoute({required this.points, required this.distanceMeters, required this.lightingScore, required this.havenScore});
  final List<LatLng> points;
  final double distanceMeters;
  final double lightingScore;
  final double havenScore;
}
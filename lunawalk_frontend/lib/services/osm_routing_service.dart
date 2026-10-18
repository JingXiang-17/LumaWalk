import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class OsmRoute {
  const OsmRoute({
    required this.points,
    required this.distanceMeters,
    required this.lightingScore,
    required this.havenScore,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double lightingScore;
  final double havenScore;
}

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

class OsmRouteOptions {
  const OsmRouteOptions({
    required this.safe,
    required this.direct,
  });

  final OsmRoute safe;
  final OsmRoute direct;
}

class OsmRoutingService {
  static const _roadsAsset = 'assets/mock_data/pj_edges.geojson';
  static const _havensAsset =
      'assets/mock_data/real_havens_petaling_jaya.geojson';
  static const _earthRadiusMeters = 6371000.0;
  static const _maximumSnapDistanceMeters = 1200.0;

  static Future<_OsmGraph>? _graphFuture;

  Future<List<OsmSafeHaven>> loadSafeHavens() async =>
      (await _loadGraph()).safeHavens;

  Future<OsmRouteOptions> findRoutes({
    required LatLng origin,
    required LatLng destination,
    required double safetyWeight,
    required bool avoidUnlit,
    required bool prioritizeHavens,
  }) async {
    final graph = await _loadGraph();
    final startNode = _nearestNode(graph.nodes, origin);
    final endNode = _nearestNode(graph.nodes, destination);
    if (startNode.distanceMeters > _maximumSnapDistanceMeters ||
        endNode.distanceMeters > _maximumSnapDistanceMeters) {
      throw StateError(
        'The OSM walking dataset does not cover this origin or destination.',
      );
    }

    return OsmRouteOptions(
      safe: _findRoute(
        graph,
        startNode.nodeId,
        endNode.nodeId,
        origin,
        destination,
        safe: true,
        safetyWeight: safetyWeight,
        avoidUnlit: avoidUnlit,
        prioritizeHavens: prioritizeHavens,
      ),
      direct: _findRoute(
        graph,
        startNode.nodeId,
        endNode.nodeId,
        origin,
        destination,
        safe: false,
        safetyWeight: safetyWeight,
        avoidUnlit: avoidUnlit,
        prioritizeHavens: prioritizeHavens,
      ),
    );
  }

  Future<_OsmGraph> _loadGraph() {
    return _graphFuture ??= _readGraph().catchError((Object error) {
      _graphFuture = null;
      throw error;
    });
  }

  Future<_OsmGraph> _readGraph() async {
    final rawAssets = await Future.wait([
      rootBundle.loadString(_roadsAsset),
      rootBundle.loadString(_havensAsset),
    ]);
    final decoded = await compute(
      _decodeGeoJson,
      <String, String>{
        'roads': rawAssets[0],
        'havens': rawAssets[1],
      },
    );

    final nodes = <int, LatLng>{};
    final adjacency = <int, List<_RouteArc>>{};
    final edgeRecords = decoded['edges']! as List<dynamic>;
    for (final record in edgeRecords) {
      final values = record as List<dynamic>;
      final from = (values[0] as num).toInt();
      final to = (values[1] as num).toInt();
      final length = (values[2] as num).toDouble();
      final light = (values[3] as num).toDouble().clamp(0.0, 1.0);
      final haven = (values[4] as num).toDouble().clamp(0.0, 1.0);
      final hazard = (values[5] as num).toDouble().clamp(0.0, 1.0);
      final points = (values[6] as List<dynamic>).map((coordinate) {
        final pair = coordinate as List<dynamic>;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList(growable: false);
      if (points.length < 2 || length <= 0) continue;

      nodes.putIfAbsent(from, () => points.first);
      nodes.putIfAbsent(to, () => points.last);
      adjacency.putIfAbsent(from, () => []).add(
            _RouteArc(
              to: to,
              points: points,
              lengthMeters: length,
              lightingScore: light,
              havenScore: haven,
              hazardScore: hazard,
            ),
          );
    }

    final safeHavens = (decoded['havens']! as List<dynamic>).map((record) {
      final values = record as List<dynamic>;
      return OsmSafeHaven(
        point: LatLng(
          (values[0] as num).toDouble(),
          (values[1] as num).toDouble(),
        ),
        classification: values[2] as String,
        id: values[3] as String,
      );
    }).toList(growable: false);

    if (nodes.isEmpty || adjacency.isEmpty) {
      throw const FormatException(
          'The OSM GeoJSON contains no routable edges.');
    }
    return _OsmGraph(
        nodes: nodes, adjacency: adjacency, safeHavens: safeHavens);
  }

  _NearestNode _nearestNode(Map<int, LatLng> nodes, LatLng point) {
    var nearestId = -1;
    var nearestDistance = double.infinity;
    for (final entry in nodes.entries) {
      final distance = _distanceMeters(entry.value, point);
      if (distance < nearestDistance) {
        nearestId = entry.key;
        nearestDistance = distance;
      }
    }
    return _NearestNode(nearestId, nearestDistance);
  }

  OsmRoute _findRoute(
    _OsmGraph graph,
    int start,
    int goal,
    LatLng origin,
    LatLng destination, {
    required bool safe,
    required double safetyWeight,
    required bool avoidUnlit,
    required bool prioritizeHavens,
  }) {
    final costs = <int, double>{start: 0};
    final previous = <int, _PreviousArc>{};
    final queue = _MinPriorityQueue()..add(_QueueEntry(start, 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.cost != costs[current.nodeId]) continue;
      if (current.nodeId == goal) break;

      for (final arc in graph.adjacency[current.nodeId] ?? const []) {
        final riskPenalty = avoidUnlit ? safetyWeight : safetyWeight * 0.2;
        final havenBenefit = prioritizeHavens ? arc.havenScore * 0.35 : 0.0;
        final costFactor = safe
            ? math.max(
                0.1,
                1 +
                    riskPenalty * (1 - arc.lightingScore) +
                    arc.hazardScore * 4 -
                    havenBenefit,
              )
            : 1.0;
        final newCost = current.cost + arc.lengthMeters * costFactor;
        if (newCost >= (costs[arc.to] ?? double.infinity)) continue;
        costs[arc.to] = newCost;
        previous[arc.to] = _PreviousArc(current.nodeId, arc);
        queue.add(_QueueEntry(arc.to, newCost));
      }
    }

    if (!costs.containsKey(goal)) {
      throw StateError(
          'No OSM walking route connects the current location to the destination.');
    }

    final arcs = <_RouteArc>[];
    var currentNode = goal;
    while (currentNode != start) {
      final previousArc = previous[currentNode];
      if (previousArc == null) {
        throw StateError('Could not reconstruct the OSM walking route.');
      }
      arcs.add(previousArc.arc);
      currentNode = previousArc.from;
    }
    final orderedArcs = arcs.reversed.toList(growable: false);
    final routePoints = <LatLng>[origin];
    var totalDistance = 0.0;
    var weightedLight = 0.0;
    var weightedHaven = 0.0;
    for (final arc in orderedArcs) {
      totalDistance += arc.lengthMeters;
      weightedLight += arc.lightingScore * arc.lengthMeters;
      weightedHaven += arc.havenScore * arc.lengthMeters;
      for (final point in arc.points) {
        if (_distanceMeters(routePoints.last, point) > 0.5) {
          routePoints.add(point);
        }
      }
    }
    if (_distanceMeters(routePoints.last, destination) > 0.5) {
      routePoints.add(destination);
    }

    return OsmRoute(
      points: List.unmodifiable(routePoints),
      distanceMeters: totalDistance,
      lightingScore: totalDistance == 0 ? 0 : weightedLight / totalDistance,
      havenScore: totalDistance == 0 ? 0 : weightedHaven / totalDistance,
    );
  }

  static double _distanceMeters(LatLng first, LatLng second) {
    final latitudeDelta = _degreesToRadians(second.latitude - first.latitude);
    final longitudeDelta =
        _degreesToRadians(second.longitude - first.longitude);
    final firstLatitude = _degreesToRadians(first.latitude);
    final secondLatitude = _degreesToRadians(second.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
            math.cos(firstLatitude) *
                math.cos(secondLatitude) *
                math.sin(longitudeDelta / 2) *
                math.sin(longitudeDelta / 2);
    return _earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

Map<String, Object?> _decodeGeoJson(Map<String, String> rawAssets) {
  final roads = jsonDecode(rawAssets['roads']!) as Map<String, dynamic>;
  final havens = jsonDecode(rawAssets['havens']!) as Map<String, dynamic>;
  final edgeRecords = <List<Object?>>[];

  for (final feature in roads['features'] as List<dynamic>) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    if (geometry?['type'] != 'LineString') continue;

    final from = int.tryParse('${properties['u']}');
    final to = int.tryParse('${properties['v']}');
    final length = (properties['length'] as num?)?.toDouble();
    if (from == null || to == null || length == null || length <= 0) continue;
    final coordinates = (geometry!['coordinates'] as List<dynamic>)
        .whereType<List<dynamic>>()
        .where((coordinate) => coordinate.length >= 2)
        .map((coordinate) => <double>[
              (coordinate[0] as num).toDouble(),
              (coordinate[1] as num).toDouble(),
            ])
        .toList(growable: false);
    if (coordinates.length < 2) continue;

    edgeRecords.add(<Object?>[
      from,
      to,
      length,
      (properties['w_light'] as num?)?.toDouble() ?? 0.1,
      (properties['w_haven'] as num?)?.toDouble() ?? 0.0,
      (properties['w_hazard'] as num?)?.toDouble() ?? 0.0,
      coordinates,
    ]);
  }

  final havenRecords = <List<Object?>>[];
  for (final feature in havens['features'] as List<dynamic>) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    if (geometry?['type'] != 'Point') continue;
    final coordinates = geometry!['coordinates'] as List<dynamic>;
    if (coordinates.length < 2) continue;
    havenRecords.add(<Object?>[
      (coordinates[1] as num).toDouble(),
      (coordinates[0] as num).toDouble(),
      '${properties['class'] ?? 'C'}',
      '${properties['id'] ?? ''}',
    ]);
  }

  return <String, Object?>{
    'edges': edgeRecords,
    'havens': havenRecords,
  };
}

class _OsmGraph {
  const _OsmGraph({
    required this.nodes,
    required this.adjacency,
    required this.safeHavens,
  });

  final Map<int, LatLng> nodes;
  final Map<int, List<_RouteArc>> adjacency;
  final List<OsmSafeHaven> safeHavens;
}

class _RouteArc {
  const _RouteArc({
    required this.to,
    required this.points,
    required this.lengthMeters,
    required this.lightingScore,
    required this.havenScore,
    required this.hazardScore,
  });

  final int to;
  final List<LatLng> points;
  final double lengthMeters;
  final double lightingScore;
  final double havenScore;
  final double hazardScore;
}

class _NearestNode {
  const _NearestNode(this.nodeId, this.distanceMeters);

  final int nodeId;
  final double distanceMeters;
}

class _PreviousArc {
  const _PreviousArc(this.from, this.arc);

  final int from;
  final _RouteArc arc;
}

class _QueueEntry {
  const _QueueEntry(this.nodeId, this.cost);

  final int nodeId;
  final double cost;
}

class _MinPriorityQueue {
  final _items = <_QueueEntry>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(_QueueEntry entry) {
    _items.add(entry);
    var index = _items.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_items[parent].cost <= _items[index].cost) break;
      _swap(index, parent);
      index = parent;
    }
  }

  _QueueEntry removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var index = 0;
      while (true) {
        final left = index * 2 + 1;
        final right = left + 1;
        var smallest = index;
        if (left < _items.length && _items[left].cost < _items[smallest].cost) {
          smallest = left;
        }
        if (right < _items.length &&
            _items[right].cost < _items[smallest].cost) {
          smallest = right;
        }
        if (smallest == index) break;
        _swap(index, smallest);
        index = smallest;
      }
    }
    return first;
  }

  void _swap(int first, int second) {
    final temporary = _items[first];
    _items[first] = _items[second];
    _items[second] = temporary;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DestinationSearchResult {
  const DestinationSearchResult({
    required this.name,
    required this.point,
  });

  final String name;
  final LatLng point;
}

class DestinationSearchService {
  DestinationSearchService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  DateTime? _lastRequestAt;

  Future<List<DestinationSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final wait = const Duration(seconds: 1) -
          DateTime.now().difference(lastRequestAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequestAt = DateTime.now();

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': trimmedQuery,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'my',
      },
    );
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'LumaWalk/1.0 (walking navigation demo)',
      },
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Destination search failed with HTTP ${response.statusCode}.',
        uri,
      );
    }

    final records = jsonDecode(response.body) as List<dynamic>;
    return records.map((record) {
      final result = record as Map<String, dynamic>;
      return DestinationSearchResult(
        name: result['display_name'] as String,
        point: LatLng(
          double.parse(result['lat'] as String),
          double.parse(result['lon'] as String),
        ),
      );
    }).toList(growable: false);
  }

  void dispose() {
    _client.close();
  }
}

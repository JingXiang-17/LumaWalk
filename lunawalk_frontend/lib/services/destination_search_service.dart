import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _historyPreferenceKey = 'destination_search_history';

  final http.Client _client;
  DateTime? _lastRequestAt;

  Future<List<DestinationSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final wait =
          const Duration(seconds: 1) - DateTime.now().difference(lastRequestAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequestAt = DateTime.now();

    final uri = Uri.https(
      'photon.komoot.io',
      '/api/',
      {
        'q': trimmedQuery,
        'limit': '8',
        'lang': 'en',
        'lat': '3.118',
        'lon': '101.623',
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>;
    return features
        .map((feature) => _parseFeature(feature as Map<String, dynamic>))
        .whereType<DestinationSearchResult>()
        .toList(growable: false);
  }

  Future<List<DestinationSearchResult>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final serializedHistory = preferences.getString(_historyPreferenceKey);
    if (serializedHistory == null) return const [];

    final records = jsonDecode(serializedHistory) as List<dynamic>;
    return records.map((record) {
      final item = record as Map<String, dynamic>;
      return DestinationSearchResult(
        name: item['name'] as String,
        point: LatLng(
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        ),
      );
    }).toList(growable: false);
  }

  Future<List<DestinationSearchResult>> addToHistory(
    DestinationSearchResult destination,
  ) async {
    final history = (await loadHistory()).toList();
    final normalizedName = _normalize(destination.name);
    history.removeWhere((item) => _normalize(item.name) == normalizedName);
    final updatedHistory = [destination, ...history].take(5).toList();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _historyPreferenceKey,
      jsonEncode(
        updatedHistory
            .map((item) => {
                  'name': item.name,
                  'latitude': item.point.latitude,
                  'longitude': item.point.longitude,
                })
            .toList(growable: false),
      ),
    );
    return updatedHistory;
  }

  DestinationSearchResult? _parseFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final countryCode = properties['countrycode'] as String?;
    if (countryCode != null && countryCode.toUpperCase() != 'MY') return null;

    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (geometry?['type'] != 'Point' || coordinates == null) return null;

    final name = properties['name'] as String?;
    final locality = properties['city'] as String? ??
        properties['district'] as String? ??
        properties['county'] as String?;
    final state = properties['state'] as String?;
    final country = properties['country'] as String?;
    final labelParts = <String>[];
    for (final part in [name, locality, state, country]) {
      if (part != null &&
          part.trim().isNotEmpty &&
          !labelParts.any(
            (existing) => _normalize(existing) == _normalize(part),
          )) {
        labelParts.add(part.trim());
      }
    }
    if (labelParts.isEmpty) return null;

    return DestinationSearchResult(
      name: labelParts.join(', '),
      point: LatLng(
        (coordinates[1] as num).toDouble(),
        (coordinates[0] as num).toDouble(),
      ),
    );
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  void dispose() {
    _client.close();
  }
}

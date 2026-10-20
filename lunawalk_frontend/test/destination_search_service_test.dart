import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:lunawalk_frontend/services/destination_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses fuzzy OpenStreetMap search and returns named coordinates',
      () async {
    Uri? requestedUri;
    final service = DestinationSearchService(
      client: MockClient((request) async {
        requestedUri = request.url;
        expect(request.headers['User-Agent'], contains('LumaWalk'));
        return http.Response(
          '{"features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[101.6559,3.1258]},"properties":{"name":"University of Malaya","city":"Kuala Lumpur","country":"Malaysia","countrycode":"MY"}}]}',
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    final results = await service.search('Universiy of Malaya');

    expect(requestedUri?.host, 'photon.komoot.io');
    expect(requestedUri?.path, '/api/');
    expect(requestedUri?.queryParameters['q'], 'Universiy of Malaya');
    expect(results, hasLength(1));
    expect(results.single.name, 'University of Malaya, Kuala Lumpur, Malaysia');
    expect(results.single.point.latitude, 3.1258);
    expect(results.single.point.longitude, 101.6559);
  });

  test('rejects non-success geocoding responses', () async {
    final service = DestinationSearchService(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.search('Petaling Jaya'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('does not make a search request for an empty query', () async {
    final service = DestinationSearchService(
      client: MockClient((_) async {
        fail('An empty query should not trigger a network request.');
      }),
    );
    addTearDown(service.dispose);

    expect(await service.search('  '), isEmpty);
  });

  test('keeps only selected places as recent search history', () async {
    SharedPreferences.setMockInitialValues({});
    final service = DestinationSearchService(
      client: MockClient((_) async {
        fail('Saving history should not trigger a network request.');
      }),
    );
    addTearDown(service.dispose);

    expect(await service.loadHistory(), isEmpty);
    const university = DestinationSearchResult(
      name: 'University of Malaya',
      point: LatLng(3.1258, 101.6559),
    );
    const mall = DestinationSearchResult(
      name: '1 Utama',
      point: LatLng(3.1579, 101.6117),
    );
    await service.addToHistory(university);
    await service.addToHistory(mall);

    final history = await service.loadHistory();

    expect(history.map((item) => item.name),
        const ['1 Utama', 'University of Malaya']);
    expect(history.last.point, university.point);
  });

  test('moves a repeated destination to the start of search history', () async {
    SharedPreferences.setMockInitialValues({});
    final service = DestinationSearchService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(service.dispose);
    const university = DestinationSearchResult(
      name: 'University of Malaya',
      point: LatLng(3.1258, 101.6559),
    );
    await service.addToHistory(university);
    await service.addToHistory(
      const DestinationSearchResult(
        name: 'Petaling Jaya',
        point: LatLng(3.1073, 101.6067),
      ),
    );

    final history = await service.addToHistory(
      const DestinationSearchResult(
        name: 'University of Malaya',
        point: LatLng(3.1258, 101.6559),
      ),
    );

    expect(history.first.name, 'University of Malaya');
    expect(history, hasLength(2));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lunawalk_frontend/services/destination_search_service.dart';

void main() {
  test('searches OpenStreetMap and returns named coordinates', () async {
    Uri? requestedUri;
    final service = DestinationSearchService(
      client: MockClient((request) async {
        requestedUri = request.url;
        expect(request.headers['User-Agent'], contains('LumaWalk'));
        return http.Response(
          '[{"display_name":"Kuala Lumpur, Malaysia","lat":"3.139","lon":"101.687"}]',
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    final results = await service.search('Kuala Lumpur');

    expect(requestedUri?.host, 'nominatim.openstreetmap.org');
    expect(requestedUri?.queryParameters['q'], 'Kuala Lumpur');
    expect(requestedUri?.queryParameters['countrycodes'], 'my');
    expect(results, hasLength(1));
    expect(results.single.name, 'Kuala Lumpur, Malaysia');
    expect(results.single.point.latitude, 3.139);
    expect(results.single.point.longitude, 101.687);
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
}

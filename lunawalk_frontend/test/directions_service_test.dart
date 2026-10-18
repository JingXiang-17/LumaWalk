import 'package:flutter_test/flutter_test.dart';
import 'package:lunawalk_frontend/services/directions_service.dart';

void main() {
  test('uses the supplied origin and destination', () async {
    final response = await DirectionsService.fetchDirections(
      alpha: 2.5,
      avoidUnlit: true,
      prioritizeHavens: true,
      originLat: 3.139,
      originLng: 101.6869,
      originLabel: 'Current GPS Location',
      destinationLat: 3.1279,
      destinationLng: 101.6501,
      destinationName: 'Pinned destination',
    );
    final data = response['data'] as Map<String, dynamic>;

    expect(data['origin'], {
      'lat': 3.139,
      'lng': 101.6869,
      'label': 'Current GPS Location',
    });
    expect(data['destination'], {
      'lat': 3.1279,
      'lng': 101.6501,
      'label': 'Pinned destination',
    });
    expect(response['is_mock'], isTrue);
  });
}

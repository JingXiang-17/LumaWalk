import 'package:flutter_test/flutter_test.dart';
import 'package:lunawalk_frontend/services/directions_service.dart';

void main() {
  test('uses the supplied origin and fixed UM FSKTM destination', () async {
    final response = await DirectionsService.fetchDirections(
      alpha: 2.5,
      avoidUnlit: true,
      prioritizeHavens: true,
      originLat: 3.139,
      originLng: 101.6869,
      originLabel: 'Current GPS Location',
    );
    final data = response['data'] as Map<String, dynamic>;

    expect(data['origin'], {
      'lat': 3.139,
      'lng': 101.6869,
      'label': 'Current GPS Location',
    });
    expect(data['destination'], {
      'lat': DirectionsService.destinationLat,
      'lng': DirectionsService.destinationLng,
      'label': 'UM FSKTM',
    });
    expect(response['is_mock'], isTrue);
  });
}

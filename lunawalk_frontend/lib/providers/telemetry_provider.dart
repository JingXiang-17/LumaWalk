import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // NEW IMPORT
import 'package:latlong2/latlong.dart';
import '../services/directions_service.dart';

class TelemetryProvider extends ChangeNotifier {
  static const double _simulationStartLat = 3.1180;
  static const double _simulationStartLng = 101.6230;

  // 1. User Profile & Preferences
  String _userName = "Luna Walker";
  String _studentId = "STD-2024-88412";
  String _phoneNumber = "+60 12-345 6789";
  int _detourCapPct = 25;
  bool _preferClassAHavens = true;

  bool _pushAlertsEnabled = true;
  String _locationSharingSetting = "Active during night journeys only";

  final List<Map<String, String>> _emergencyContacts = [
    {
      "name": "Campus Security Escort",
      "phone": "+1 (800) 586-2925",
      "type": "default"
    },
    {
      "name": "Student Health Center",
      "phone": "+1 (800) 555-0199",
      "type": "default"
    },
    {
      "name": "Primary Emergency Contact",
      "phone": "+1 (555) 012-3456",
      "type": "default"
    },
  ];

  bool _isSimulationMode = false;
  double _currentLat = 3.1180;
  double _currentLng = 101.6230;
  bool _hasCurrentLocation = false;
  bool _isLocating = false;
  String? _locationError;
  StreamSubscription<Position>? _locationSubscription;

  bool _isOffTrack = false;
  bool _showOffTrackModal = false;
  bool _showBackOnTrackBanner = false;
  bool _offTrackAlertDismissed = false;
  Timer? _backOnTrackTimer;

  String _targetEnvironment = "localhost:8000";
  bool _mockJsonInspector = true;

  bool _virtualBuddyEnabled = true;
  bool _safeHavensVisible = true;
  bool _showHeatmap = false;
  bool _showLightingOverlay = true;
  bool _showCrowdOverlay = false;

  int _selectedRouteIndex = 0;
  bool _hasSelectedRoute = false;
  List<LatLng> _selectedRoutePoints = const [];
  double _alphaSafetyWeight = 2.5;
  bool _avoidUnlitAlleys = true;
  bool _isNavigating = false;
  bool _isFetchingApi = false;
  int _lastResponseMs = 356;

  String _buddyConsoleStatus = "MONITORING";
  bool _isSosActive = false;
  DateTime? _sosTriggeredAt;

  bool _showAreYouOkModal = false;
  int _areYouOkCountdown = 19;
  Timer? _modalTimer;

  TelemetryProvider() {
    unawaited(refreshCurrentLocation());
  }

  Future<void> refreshCurrentLocation() async {
    _isLocating = true;
    _locationError = null;
    notifyListeners();
    await _locationSubscription?.cancel();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError = 'Turn on location services to find your position.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError =
            'Location permission is required to plan a route from your position.';
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _updateCurrentLocation(position);
      if (_isSimulationMode) return;
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateCurrentLocation,
        onError: (Object error, StackTrace stackTrace) {
          _locationError = 'Live location updates stopped: $error';
          debugPrintStack(label: _locationError, stackTrace: stackTrace);
          notifyListeners();
        },
      );
    } catch (error, stackTrace) {
      _locationError = 'Unable to get your location: $error';
      debugPrintStack(label: _locationError, stackTrace: stackTrace);
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  void _updateCurrentLocation(Position position) {
    if (_isSimulationMode) return;
    _currentLat = position.latitude;
    _currentLng = position.longitude;
    _hasCurrentLocation = true;
    _locationError = null;
    _checkRouteDeviation();
    notifyListeners();
  }

  @override
  void dispose() {
    _modalTimer?.cancel();
    _backOnTrackTimer?.cancel();
    unawaited(_locationSubscription?.cancel());
    super.dispose();
  }

  // --- GETTERS ---
  String get userName => _userName;
  String get studentId => _studentId;
  String get phoneNumber => _phoneNumber;
  int get detourCapPct => _detourCapPct;
  bool get preferClassAHavens => _preferClassAHavens;
  bool get pushAlertsEnabled => _pushAlertsEnabled;
  String get locationSharingSetting => _locationSharingSetting;
  List<Map<String, String>> get emergencyContacts => _emergencyContacts;

  bool get isSimulationMode => _isSimulationMode;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  bool get hasCurrentLocation => _hasCurrentLocation;
  bool get isLocating => _isLocating;
  String? get locationError => _locationError;
  bool get isOffTrack => _isOffTrack;
  bool get showOffTrackModal => _showOffTrackModal;
  bool get showBackOnTrackBanner => _showBackOnTrackBanner;
  bool get hasSelectedRoute => _hasSelectedRoute;
  List<LatLng> get routePoints => _hasSelectedRoute
      ? List.unmodifiable(_selectedRoutePoints)
      : _buildRoutePoints(
          _selectedRouteIndex,
          LatLng(_currentLat, _currentLng),
        );

  String get targetEnvironment => _targetEnvironment;
  bool get mockJsonInspector => _mockJsonInspector;
  bool get virtualBuddyEnabled => _virtualBuddyEnabled;
  bool get safeHavensVisible => _safeHavensVisible;
  bool get showHeatmap => _showHeatmap;
  bool get showLightingOverlay => _showLightingOverlay;
  bool get showCrowdOverlay => _showCrowdOverlay;
  int get selectedRouteIndex => _selectedRouteIndex;
  double get alphaSafetyWeight => _alphaSafetyWeight;
  bool get avoidUnlitAlleys => _avoidUnlitAlleys;
  String get destinationName => DirectionsService.destinationName;
  double get destinationLat => DirectionsService.destinationLat;
  double get destinationLng => DirectionsService.destinationLng;
  bool get isNavigating => _isNavigating;
  bool get isFetchingApi => _isFetchingApi;
  int get lastResponseMs => _lastResponseMs;
  String get buddyConsoleStatus => _buddyConsoleStatus;
  bool get isSosActive => _isSosActive;
  DateTime? get sosTriggeredAt => _sosTriggeredAt;
  bool get showAreYouOkModal => _showAreYouOkModal;
  int get areYouOkCountdown => _areYouOkCountdown;

  // --- SETTERS & ACTIONS ---
  void setSimulationMode(bool isSim) {
    if (_isSimulationMode == isSim) return;
    _isSimulationMode = isSim;
    _isNavigating = false;
    _isOffTrack = false;
    _showOffTrackModal = false;
    _showBackOnTrackBanner = false;
    _offTrackAlertDismissed = false;
    _hasSelectedRoute = false;
    _selectedRoutePoints = const [];
    _selectedRouteIndex = 0;
    _backOnTrackTimer?.cancel();
    if (isSim) {
      _currentLat = _simulationStartLat;
      _currentLng = _simulationStartLng;
      _hasCurrentLocation = true;
      unawaited(_locationSubscription?.cancel());
      _locationSubscription = null;
    } else {
      _hasCurrentLocation = false;
      unawaited(refreshCurrentLocation());
    }
    notifyListeners();
  }

  void moveAvatar(double deltaLat, double deltaLng) {
    _currentLat += deltaLat;
    _currentLng += deltaLng;
    _checkRouteDeviation();
    notifyListeners();
  }

  static const double _routeDeviationThresholdMeters = 35;
  static const double _earthRadiusMeters = 6371000;

  List<LatLng> _buildRoutePoints(int routeIndex, LatLng origin) {
    final destination = LatLng(destinationLat, destinationLng);
    if (routeIndex != 0) return [origin, destination];

    final averageLatitudeRadians = (origin.latitude + destination.latitude) *
        0.5 *
        (3.141592653589793 / 180);
    final longitudeScale = math.cos(averageLatitudeRadians);
    final deltaX = (destination.longitude - origin.longitude) * longitudeScale;
    final deltaY = destination.latitude - origin.latitude;
    final length = math.sqrt(deltaX * deltaX + deltaY * deltaY);
    if (length == 0) return [origin, destination];

    const safetyDetourDegrees = 0.00045;
    final offsetLatitude = deltaX / length * safetyDetourDegrees;
    final offsetLongitude =
        -deltaY / length * safetyDetourDegrees / longitudeScale;
    final midpoint = LatLng(
      (origin.latitude + destination.latitude) / 2 + offsetLatitude,
      (origin.longitude + destination.longitude) / 2 + offsetLongitude,
    );
    return [origin, midpoint, destination];
  }

  double _distanceFromRouteMeters(LatLng position, List<LatLng> route) {
    var nearestDistance = double.infinity;
    for (var index = 0; index < route.length - 1; index++) {
      final start = route[index];
      final end = route[index + 1];
      final averageLatitudeRadians =
          position.latitude * (3.141592653589793 / 180);
      final longitudeScale = math.cos(averageLatitudeRadians);
      final startX = (start.longitude - position.longitude) *
          longitudeScale *
          _earthRadiusMeters *
          (3.141592653589793 / 180);
      final startY = (start.latitude - position.latitude) *
          _earthRadiusMeters *
          (3.141592653589793 / 180);
      final endX = (end.longitude - position.longitude) *
          longitudeScale *
          _earthRadiusMeters *
          (3.141592653589793 / 180);
      final endY = (end.latitude - position.latitude) *
          _earthRadiusMeters *
          (3.141592653589793 / 180);
      final segmentX = endX - startX;
      final segmentY = endY - startY;
      final segmentLengthSquared = segmentX * segmentX + segmentY * segmentY;
      final projection = segmentLengthSquared == 0
          ? 0.0
          : ((-startX * segmentX - startY * segmentY) / segmentLengthSquared)
              .clamp(0.0, 1.0);
      final nearestX = startX + projection * segmentX;
      final nearestY = startY + projection * segmentY;
      final distance = math.sqrt(nearestX * nearestX + nearestY * nearestY);
      if (distance < nearestDistance) nearestDistance = distance;
    }
    return nearestDistance;
  }

  void _checkRouteDeviation() {
    if (!_isNavigating || !_hasSelectedRoute) return;
    final distance = _distanceFromRouteMeters(
      LatLng(_currentLat, _currentLng),
      _selectedRoutePoints,
    );
    if (distance > _routeDeviationThresholdMeters) {
      _backOnTrackTimer?.cancel();
      _showBackOnTrackBanner = false;
      if (!_isOffTrack && !_offTrackAlertDismissed) {
        _isOffTrack = true;
        _showOffTrackModal = true;
        _buddyConsoleStatus = "OFF ROUTE";
      }
    } else if (_isOffTrack) {
      _isOffTrack = false;
      _showOffTrackModal = false;
      _offTrackAlertDismissed = false;
      _showBackOnTrackBanner = true;
      _buddyConsoleStatus = "MONITORING";
      _backOnTrackTimer?.cancel();
      _backOnTrackTimer = Timer(const Duration(seconds: 4), () {
        _showBackOnTrackBanner = false;
        notifyListeners();
      });
    } else {
      _offTrackAlertDismissed = false;
    }
  }

  void selectRoute(int index) {
    if (_isNavigating || _isFetchingApi || (index != 0 && index != 1)) return;
    _selectedRouteIndex = index;
    _selectedRoutePoints = _buildRoutePoints(
      index,
      LatLng(_currentLat, _currentLng),
    );
    _hasSelectedRoute = true;
    _showOffTrackModal = false;
    _showBackOnTrackBanner = false;
    notifyListeners();
  }

  void setOffTrack(bool value, {bool showModal = true}) {
    _isOffTrack = value;
    if (value) {
      _showOffTrackModal = showModal;
      _showBackOnTrackBanner = false;
      _offTrackAlertDismissed = !showModal;
      _buddyConsoleStatus = showModal ? "OFF TRACK" : "MONITORING";
    } else {
      _showOffTrackModal = false;
      _showBackOnTrackBanner = false;
      _offTrackAlertDismissed = false;
      _buddyConsoleStatus = "MONITORING";
    }
    notifyListeners();
  }

  void triggerOffTrackAlert() {
    _isOffTrack = true;
    _showOffTrackModal = true;
    _showBackOnTrackBanner = false;
    _offTrackAlertDismissed = false;
    _buddyConsoleStatus = "OFF TRACK";
    notifyListeners();
  }

  void dismissOffTrackModal() {
    _showOffTrackModal = false;
    _offTrackAlertDismissed = true;
    _buddyConsoleStatus = "OFF ROUTE";
    notifyListeners();
  }

  void setBackOnTrackBanner(bool value) {
    _showBackOnTrackBanner = value;
    if (value) {
      _showOffTrackModal = false;
      _isOffTrack = false;
      _offTrackAlertDismissed = false;
      _buddyConsoleStatus = "BACK ON TRACK";
    }
    notifyListeners();
  }

  void updateProfileInfo(String newName, String newId) {
    _userName = newName;
    _studentId = newId;
    notifyListeners();
  }

  void updatePhoneNumber(String newPhone) {
    _phoneNumber = newPhone;
    notifyListeners();
  }

  void togglePushAlerts() {
    _pushAlertsEnabled = !_pushAlertsEnabled;
    notifyListeners();
  }

  void setLocationSharingSetting(String setting) {
    _locationSharingSetting = setting;
    notifyListeners();
  }

  void addEmergencyContact(String name, String phone) {
    _emergencyContacts.add({"name": name, "phone": phone, "type": "custom"});
    notifyListeners();
  }

  void setDetourCap(int cap) {
    _detourCapPct = cap.clamp(0, 100);
    notifyListeners();
  }

  void setPreferClassAHavens(bool val) {
    _preferClassAHavens = val;
    notifyListeners();
  }

  void setAvoidUnlitAlleys(bool value) {
    _avoidUnlitAlleys = value;
    notifyListeners();
  }

  void toggleAvoidUnlitAlleys() {
    setAvoidUnlitAlleys(!_avoidUnlitAlleys);
  }

  void setTargetEnvironment(String env) {
    _targetEnvironment = env;
    notifyListeners();
  }

  void toggleVirtualBuddy() {
    _virtualBuddyEnabled = !_virtualBuddyEnabled;
    notifyListeners();
  }

  void toggleSafeHavensVisible() {
    _safeHavensVisible = !_safeHavensVisible;
    notifyListeners();
  }

  void toggleHeatmap() {
    _showHeatmap = !_showHeatmap;
    notifyListeners();
  }

  void toggleLightingOverlay([bool? value]) {
    _showLightingOverlay = value ?? !_showLightingOverlay;
    notifyListeners();
  }

  void toggleCrowdOverlay([bool? value]) {
    _showCrowdOverlay = value ?? !_showCrowdOverlay;
    notifyListeners();
  }

  void setSelectedRoute(int index) {
    selectRoute(index);
  }

  void setAlphaWeight(double weight) {
    _alphaSafetyWeight = weight.clamp(0.0, 5.0);
    notifyListeners();
  }

  void simulateWalkGpsDrift() {
    _showAreYouOkModal = true;
    _areYouOkCountdown = 19;
    _buddyConsoleStatus = "CHECKING IN";
    notifyListeners();

    _modalTimer?.cancel();
    _modalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_areYouOkCountdown > 1) {
        _areYouOkCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
        _showAreYouOkModal = false;
        toggleSosAlert();
      }
    });
  }

  void dismissAreYouOkModal() {
    _modalTimer?.cancel();
    _showAreYouOkModal = false;
    _buddyConsoleStatus = "MONITORING";
    notifyListeners();
  }

  void toggleSosAlert() {
    _isSosActive = !_isSosActive;
    if (_isSosActive) {
      _sosTriggeredAt = DateTime.now();
      _buddyConsoleStatus = "CRITICAL SOS";
    } else {
      _buddyConsoleStatus = "MONITORING";
    }
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _isOffTrack = false;
    _showOffTrackModal = false;
    _showBackOnTrackBanner = false;
    _offTrackAlertDismissed = false;
    _hasSelectedRoute = false;
    _selectedRoutePoints = const [];
    _backOnTrackTimer?.cancel();
    _buddyConsoleStatus = "MONITORING";
    notifyListeners();
  }

  Future<void> triggerNavigationApiCall() async {
    if (!_hasSelectedRoute) {
      _locationError = 'Choose a route before starting navigation.';
      notifyListeners();
      return;
    }
    if (!_hasCurrentLocation && !_isSimulationMode) {
      _locationError =
          'A current GPS location is needed before requesting a route.';
      notifyListeners();
      return;
    }

    _isFetchingApi = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      await DirectionsService.fetchDirections(
        alpha: _alphaSafetyWeight,
        avoidUnlit: _avoidUnlitAlleys,
        prioritizeHavens: _preferClassAHavens,
        originLat: _currentLat, // Sends real GPS Lat
        originLng: _currentLng, // Sends real GPS Lng
        originLabel: _isSimulationMode
            ? "Simulated User Location"
            : "Current GPS Location",
      );
      _isNavigating = true;
      _checkRouteDeviation();
    } catch (error, stackTrace) {
      _isNavigating = false;
      debugPrint('Failed to fetch directions: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      stopwatch.stop();
      _lastResponseMs = stopwatch.elapsedMilliseconds;
      _isFetchingApi = false;
      notifyListeners();
    }
  }

  // --- LIVE B2B JSON PAYLOAD GENERATOR ---
  String get formattedJsonPayload {
    const encoder = JsonEncoder.withIndent('  ');
    if (_isSosActive) {
      return encoder.convert(
          {"event": "CRITICAL_SOS_TRIGGERED", "status": "active_broadcast"});
    }

    final Map<String, dynamic> payload = {
      "status": "success",
      "target_environment": _targetEnvironment,
      "navigation_mode": _isNavigating ? "ACTIVE_GUIDANCE" : "ROUTE_PREVIEW",
      "request": {
        "origin": {
          "lat": _hasCurrentLocation || _isSimulationMode ? _currentLat : null,
          "lng": _hasCurrentLocation || _isSimulationMode ? _currentLng : null,
          "label": _isSimulationMode
              ? "Simulated User Location"
              : _hasCurrentLocation
                  ? "Current GPS Location"
                  : "Waiting for GPS",
        },
        "destination": {
          "lat": destinationLat,
          "lng": destinationLng,
          "label": destinationName
        },
        "alpha_safety_weight":
            double.parse(_alphaSafetyWeight.toStringAsFixed(1)),
      },
      "active_route":
          _selectedRouteIndex == 0 ? "lumawalk_safe" : "direct_shortest",
      "routes": {
        "lumawalk_safe": {
          "distance_meters": 2450.0,
          "estimated_duration_sec": 1740,
          "safety_score_avg": double.parse((0.78 + (_alphaSafetyWeight * 0.03))
              .clamp(0.0, 0.98)
              .toStringAsFixed(2)),
        },
        "direct_shortest": {
          "distance_meters": 2140.0,
          "estimated_duration_sec": 1520,
          "safety_score_avg": 0.52,
        }
      }
    };
    return encoder.convert(payload);
  }
}

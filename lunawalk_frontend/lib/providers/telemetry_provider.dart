import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; 
import '../services/safe_haven_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class TelemetryProvider extends ChangeNotifier {
  static const double _simulationStartLat = 3.1180;
  static const double _simulationStartLng = 101.6230;
  final SafeHavenService _safeHavenService = SafeHavenService();

  // 1. User Profile & Preferences
  String _userName = "Luma Walker";
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
  double _currentHeading = 0;
  bool _hasCurrentLocation = false;
  bool _isLocating = false;
  String? _locationError;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _routeRefreshTimer;
  int _routeRequestId = 0;
  bool _isDisposed = false;
  bool _isMapDataLoading = true;
  bool _isRouteLoading = false;
  String? _routeError;
  List<OsmSafeHaven> _safeHavens = const [];
  BackendRoute? _safeRoute;
  BackendRoute? _directRoute;
  BackendRoute? _selectedRoute;
  LatLng? _destination;
  String? _destinationName;
  bool _hasReachedDestination = false;
  String? _navigationInstruction;
  int? _lastAnnouncedTurnIndex;

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

  String _buddyConsoleStatus = "MONITORING";
  bool _isSosActive = false;
  DateTime? _sosTriggeredAt;

  bool _showAreYouOkModal = false;
  int _areYouOkCountdown = 19;
  Timer? _modalTimer;

  final http.Client _client;

  TelemetryProvider({http.Client? client}) : _client = client ?? http.Client() {
    unawaited(_loadOsmData());
    unawaited(refreshCurrentLocation());
  }

  Future<void> _loadOsmData() async {
    try {
      final safeHavens = await _safeHavenService.loadSafeHavens();
      if (_isDisposed) return;
      _safeHavens = safeHavens;
      _isMapDataLoading = false;
      _routeError = null;
      _scheduleRouteRefresh();
    } catch (error) {
      _isMapDataLoading = false;
      _routeError = 'Could not load Safe Havens: $error';
    } finally {
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> refreshCurrentLocation() async {
    if (_isDisposed) return;
    _isLocating = true;
    _locationError = null;
    notifyListeners();
    await _locationSubscription?.cancel();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError = 'Turn on location services to find your position.';
        return;
      }
      if (_isDisposed) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (_isDisposed) return;
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
      if (_isDisposed) return;
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
          if (_isDisposed) return;
          _locationError = 'Live location updates stopped: $error';
          debugPrintStack(label: _locationError, stackTrace: stackTrace);
          notifyListeners();
        },
      );
    } catch (error, stackTrace) {
      if (_isDisposed) return;
      _locationError = 'Unable to get your location: $error';
      debugPrintStack(label: _locationError, stackTrace: stackTrace);
    } finally {
      _isLocating = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _updateCurrentLocation(Position position) {
    if (_isSimulationMode || _isDisposed) return;
    _currentLat = position.latitude;
    _currentLng = position.longitude;
    if (position.heading.isFinite && position.heading >= 0) {
      _currentHeading = position.heading;
    }
    _hasCurrentLocation = true;
    _locationError = null;
    _checkRouteDeviation();
    _scheduleRouteRefresh();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _modalTimer?.cancel();
    _backOnTrackTimer?.cancel();
    _routeRefreshTimer?.cancel();
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
  double get currentHeading => _currentHeading;
  bool get hasCurrentLocation => _hasCurrentLocation;
  bool get isLocating => _isLocating;
  String? get locationError => _locationError;
  bool get isOffTrack => _isOffTrack;
  bool get showOffTrackModal => _showOffTrackModal;
  bool get showBackOnTrackBanner => _showBackOnTrackBanner;
  bool get hasSelectedRoute => _hasSelectedRoute;
  bool get hasDestination => _destination != null;
  bool get hasReachedDestination => _hasReachedDestination;
  String? get navigationInstruction => _navigationInstruction;
  bool get isMapDataLoading => _isMapDataLoading;
  bool get isRouteLoading => _isRouteLoading;
  String? get routeError => _routeError;
  BackendRoute? get safeRoute => _safeRoute;
  BackendRoute? get directRoute => _directRoute;
  List<LatLng> get routePoints =>
      _selectedRoute?.points ??
      (_selectedRouteIndex == 0 ? _safeRoute?.points : _directRoute?.points) ??
      const [];
  List<OsmSafeHaven> get nearbySafeHavens {
    if (!_safeHavensVisible || _safeRoute == null) return const [];
    final points = _selectedRoute?.points ?? _safeRoute!.points;
    if (points.isEmpty) return const [];
    final minLatitude =
        points.map((point) => point.latitude).reduce(math.min) - 0.006;
    final maxLatitude =
        points.map((point) => point.latitude).reduce(math.max) + 0.006;
    final minLongitude =
        points.map((point) => point.longitude).reduce(math.min) - 0.006;
    final maxLongitude =
        points.map((point) => point.longitude).reduce(math.max) + 0.006;
    return _safeHavens
        .where((haven) =>
            haven.point.latitude >= minLatitude &&
            haven.point.latitude <= maxLatitude &&
            haven.point.longitude >= minLongitude &&
            haven.point.longitude <= maxLongitude)
        .take(100)
        .toList(growable: false);
  }

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
  String get destinationName =>
      _destinationName ?? 'Enter a destination';
  double get destinationLat => _destination?.latitude ?? _simulationStartLat;
  double get destinationLng => _destination?.longitude ?? _simulationStartLng;
  bool get isNavigating => _isNavigating;
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
    _selectedRoute = null;
    _selectedRoutePoints = const [];
    _navigationInstruction = null;
    _hasReachedDestination = false;
    _selectedRouteIndex = 0;
    _backOnTrackTimer?.cancel();
    _routeRequestId++;
    _isRouteLoading = false;
    _safeRoute = null;
    _directRoute = null;
    if (isSim) {
      _currentLat = _simulationStartLat;
      _currentLng = _simulationStartLng;
      _hasCurrentLocation = true;
      unawaited(_locationSubscription?.cancel());
      _locationSubscription = null;
      _scheduleRouteRefresh();
    } else {
      _hasCurrentLocation = false;
      _safeRoute = null;
      _directRoute = null;
      _selectedRoute = null;
      unawaited(refreshCurrentLocation());
    }
    notifyListeners();
  }

  void moveAvatar(double deltaLat, double deltaLng) {
    if (deltaLat != 0 || deltaLng != 0) {
      _currentHeading =
          (math.atan2(deltaLng, deltaLat) * 180 / math.pi + 360) % 360;
    }
    _currentLat += deltaLat;
    _currentLng += deltaLng;
    _checkRouteDeviation();
    _scheduleRouteRefresh();
    notifyListeners();
  }

  static const double _routeDeviationThresholdMeters = 35;

  double _distanceFromRouteMeters(LatLng position, List<LatLng> route) {
    var nearestDistance = double.infinity;
    for (var index = 0; index < route.length - 1; index++) {
      final start = route[index];
      final end = route[index + 1];
      final latitudeRadians = position.latitude * (math.pi / 180);
      final longitudeScale = math.cos(latitudeRadians);
      final startX =
          (start.longitude - position.longitude) * longitudeScale * 111195;
      final startY = (start.latitude - position.latitude) * 111195;
      final endX =
          (end.longitude - position.longitude) * longitudeScale * 111195;
      final endY = (end.latitude - position.latitude) * 111195;
      final segmentX = endX - startX;
      final segmentY = endY - startY;
      final lengthSquared = segmentX * segmentX + segmentY * segmentY;
      final projection = lengthSquared == 0
          ? 0.0
          : ((-startX * segmentX - startY * segmentY) / lengthSquared)
              .clamp(0.0, 1.0);
      nearestDistance = math.min(
        nearestDistance,
        math.sqrt(
          math.pow(startX + projection * segmentX, 2) +
              math.pow(startY + projection * segmentY, 2),
        ),
      );
    }
    return nearestDistance;
  }

  void _scheduleRouteRefresh() {
    if (_isDisposed ||
        _isMapDataLoading ||
        _destination == null ||
        !_hasCurrentLocation ||
        _isNavigating ||
        _hasSelectedRoute) {
      return;
    }
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadRoutesForCurrentLocation());
    });
  }

  Future<void> _loadRoutesForCurrentLocation() async {
    if (_isDisposed || _isMapDataLoading || _destination == null || !_hasCurrentLocation || _isNavigating || _hasSelectedRoute) return;
    
    final requestId = ++_routeRequestId;
    _isRouteLoading = true;
    _routeError = null;
    notifyListeners();
    
    try {
      // NOTE: 10.0.2.2 is required for Android Emulators to hit localhost on your machine
      String baseUrl;
      
      if (kIsWeb) {
        baseUrl = 'http://localhost:8000';
      } else if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
      } else {
        baseUrl = 'http://localhost:8000'; // iOS Simulator, macOS, Windows
      }

      // If testing on a physical phone, manually override here with your Wi-Fi IP:
      // baseUrl = 'http://192.168.1.X:8000'; 

      final url = Uri.parse('$baseUrl/api/v1/route/');
      
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "start_lat": _currentLat,
          "start_lng": _currentLng,
          "end_lat": _destination!.latitude,
          "end_lng": _destination!.longitude,
        }),
      );

      if (_isDisposed || requestId != _routeRequestId) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Map the backend JSON coordinates into LatLng objects for Flutter to draw
        _safeRoute = BackendRoute(
          points: (data['safe_route_coords'] as List).map((c) => LatLng(c[0], c[1])).toList(),
          distanceMeters: data['safe_distance'].toDouble(),
          lightingScore: data['percentage_lit'] / 100.0,
          havenScore: 0.9, 
        );
        
        _directRoute = BackendRoute(
          points: (data['direct_route_coords'] as List).map((c) => LatLng(c[0], c[1])).toList(),
          distanceMeters: data['direct_distance'].toDouble(),
          lightingScore: 0.3,
          havenScore: 0.1,
        );
      } else {
        _routeError = 'Backend returned error: ${response.statusCode}';
      }
    } catch (error) {
      if (_isDisposed || requestId != _routeRequestId) return;
      _routeError = 'Failed to connect to FastAPI backend: $error';
    } finally {
      if (!_isDisposed && requestId == _routeRequestId) {
        _isRouteLoading = false;
        notifyListeners();
      }
    }
  }

  void _checkRouteDeviation() {
    if (!_isNavigating || !_hasSelectedRoute) return;
    if (_destination != null &&
        _distanceBetweenMeters(
              LatLng(_currentLat, _currentLng),
              _destination!,
            ) <=
            25) {
      _isNavigating = false;
      _hasReachedDestination = true;
      _isOffTrack = false;
      _showOffTrackModal = false;
      _navigationInstruction = 'You have reached your destination.';
      _buddyConsoleStatus = 'ARRIVED';
      return;
    }
    _updateNavigationInstruction();
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

  void _updateNavigationInstruction() {
    final route = _selectedRoute;
    if (route == null || route.points.length < 3) return;
    final points = route.points;
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    final current = LatLng(_currentLat, _currentLng);
    for (var index = 0; index < points.length; index++) {
      final distance = _distanceBetweenMeters(current, points[index]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }

    var distanceAlongRoute = 0.0;
    final cumulativeDistances = List<double>.filled(points.length, 0);
    for (var index = 1; index < points.length; index++) {
      distanceAlongRoute +=
          _distanceBetweenMeters(points[index - 1], points[index]);
      cumulativeDistances[index] = distanceAlongRoute;
    }
    final currentDistance = cumulativeDistances[nearestIndex];

    for (var index = math.max(1, nearestIndex);
        index < points.length - 1;
        index++) {
      final firstBearing = _bearingDegrees(points[index - 1], points[index]);
      final secondBearing = _bearingDegrees(points[index], points[index + 1]);
      final turn = ((secondBearing - firstBearing + 540) % 360) - 180;
      if (turn.abs() < 45 || _lastAnnouncedTurnIndex == index) continue;
      final metersToTurn = cumulativeDistances[index] - currentDistance;
      if (metersToTurn < 0) continue;
      if (metersToTurn <= 100) {
        final direction = turn > 0 ? 'right' : 'left';
        _navigationInstruction =
            'In ${metersToTurn.round()} meters, turn $direction.';
        _lastAnnouncedTurnIndex = index;
      } else {
        _navigationInstruction =
            'Continue on your selected route to $destinationName.';
      }
      return;
    }

    _navigationInstruction = 'Continue toward $destinationName.';
  }

  static double _distanceBetweenMeters(LatLng first, LatLng second) {
    const earthRadiusMeters = 6371000.0;
    final firstLatitude = first.latitude * math.pi / 180;
    final secondLatitude = second.latitude * math.pi / 180;
    final latitudeDelta = (second.latitude - first.latitude) * math.pi / 180;
    final longitudeDelta = (second.longitude - first.longitude) * math.pi / 180;
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
            math.cos(firstLatitude) *
                math.cos(secondLatitude) *
                math.sin(longitudeDelta / 2) *
                math.sin(longitudeDelta / 2);
    return 2 *
        earthRadiusMeters *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  static double _bearingDegrees(LatLng from, LatLng to) {
    final latitude1 = from.latitude * math.pi / 180;
    final latitude2 = to.latitude * math.pi / 180;
    final longitudeDelta = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(longitudeDelta) * math.cos(latitude2);
    final x = math.cos(latitude1) * math.sin(latitude2) -
        math.sin(latitude1) * math.cos(latitude2) * math.cos(longitudeDelta);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void setDestination(LatLng destination, {required String name}) {
    if (_isNavigating) return;
    _destination = destination;
    _destinationName = name;
    _hasReachedDestination = false;
    _isOffTrack = false;
    _showOffTrackModal = false;
    _showBackOnTrackBanner = false;
    _selectedRouteIndex = 0;
    _navigationInstruction = null;
    _lastAnnouncedTurnIndex = null;
    _hasSelectedRoute = false;
    _selectedRoute = null;
    _selectedRoutePoints = const [];
    _safeRoute = null;
    _directRoute = null;
    _routeError = null;
    _routeRequestId++;
    _isRouteLoading = false;
    _scheduleRouteRefresh();
    notifyListeners();
  }

  void selectRoute(int index) {
    if (_isNavigating) return;
    final route = switch (index) {
      0 => _safeRoute,
      1 => _directRoute,
      _ => null,
    };
    if (route == null) return;
    _selectedRouteIndex = index;
    _selectedRoute = route;
    _selectedRoutePoints = route.points;
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
    _scheduleRouteRefresh();
    notifyListeners();
  }

  void setAvoidUnlitAlleys(bool value) {
    _avoidUnlitAlleys = value;
    _scheduleRouteRefresh();
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
    _scheduleRouteRefresh();
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
    _selectedRoute = null;
    _navigationInstruction = null;
    _lastAnnouncedTurnIndex = null;
    _hasReachedDestination = false;
    _backOnTrackTimer?.cancel();
    _buddyConsoleStatus = "MONITORING";
    notifyListeners();
  }

  void startNavigation() {
    if (_destination == null) {
      _routeError = 'Search for and select a destination before navigating.';
      notifyListeners();
      return;
    }
    if (!_hasSelectedRoute || _selectedRoute == null) {
      _routeError = 'Choose an OSM route before starting navigation.';
      notifyListeners();
      return;
    }
    if (!_hasCurrentLocation && !_isSimulationMode) {
      _locationError =
          'A current GPS location is needed before requesting a route.';
      notifyListeners();
      return;
    }
    _isNavigating = true;
    _hasReachedDestination = false;
    _lastAnnouncedTurnIndex = null;
    _navigationInstruction = 'Start walking toward $destinationName.';
    _checkRouteDeviation();
    notifyListeners();
  }

  // --- LIVE B2B JSON PAYLOAD GENERATOR ---
  String get formattedJsonPayload {
    const encoder = JsonEncoder.withIndent('  ');
    if (_isSosActive) {
      return encoder.convert(
          {"event": "CRITICAL_SOS_TRIGGERED", "status": "active_broadcast"});
    }

    final Map<String, dynamic> payload = {
      "status": _destination == null
          ? "destination_required"
          : _safeRoute == null
              ? _isRouteLoading
                  ? "loading_route_data"
                  : "route_unavailable"
              : "success",
      "target_environment": _targetEnvironment,
      "navigation_mode": _isNavigating ? "ACTIVE_GUIDANCE" : "ROUTE_PREVIEW",
      "route_source": "OpenStreetMap walking network GeoJSON",
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
          "lat": _destination?.latitude,
          "lng": _destination?.longitude,
          "label": destinationName
        },
        "alpha_safety_weight":
            double.parse(_alphaSafetyWeight.toStringAsFixed(1)),
      },
      "active_route": !_hasSelectedRoute
          ? null
          : _selectedRouteIndex == 0
              ? "lumawalk_safe"
              : "direct_shortest",
      "routes": {
        "lumawalk_safe": _routePayload(_safeRoute),
        "direct_shortest": _routePayload(_directRoute),
      },
      if (_selectedRoute != null)
        "selected_route_geometry": _selectedRoute!.points
            .map((point) => {"lat": point.latitude, "lng": point.longitude})
            .toList(growable: false),
    };
    return encoder.convert(payload);
  }

  Map<String, dynamic> _routePayload(BackendRoute? route) {
    if (route == null) return {"available": false};
    return {
      "available": true,
      "distance_meters": route.distanceMeters.round(),
      "estimated_duration_sec": (route.distanceMeters / 1.2).round(),
      "lighting_score": double.parse(route.lightingScore.toStringAsFixed(2)),
      "nearby_haven_score": double.parse(route.havenScore.toStringAsFixed(2)),
    };
  }
}

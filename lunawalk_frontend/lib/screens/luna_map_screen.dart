import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class LunaMapScreen extends StatefulWidget {
  const LunaMapScreen({super.key});

  @override
  State<LunaMapScreen> createState() => _LunaMapScreenState();
}

class _LunaMapScreenState extends State<LunaMapScreen> {
  final MapController _mapController = MapController();
  final FocusNode _focusNode = FocusNode();

  // Joystick Drag State
  Offset _joystickDelta = Offset.zero;
  bool _mapReady = false;
  bool _hasAutoFittedRoute = false;
  LatLng? _lastMapCenter;

  @override
  void initState() {
    super.initState();
    Provider.of<TelemetryProvider>(context, listen: false)
        .addListener(_followCurrentLocation);
  }

  @override
  void dispose() {
    Provider.of<TelemetryProvider>(context, listen: false)
        .removeListener(_followCurrentLocation);
    _focusNode.dispose();
    super.dispose();
  }

  void _followCurrentLocation() {
    final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    if (!telemetry.hasCurrentLocation && !telemetry.isSimulationMode) return;

    final position = LatLng(telemetry.currentLat, telemetry.currentLng);
    if (position == _lastMapCenter) return;
    _lastMapCenter = position;

    if (!_mapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapReady) {
        if (!_hasAutoFittedRoute) {
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: [
                position,
                LatLng(telemetry.destinationLat, telemetry.destinationLng),
              ],
              padding: const EdgeInsets.fromLTRB(60, 110, 60, 180),
              maxZoom: 15.8,
            ),
          );
          _hasAutoFittedRoute = true;
        } else {
          _mapController.move(position, _mapController.camera.zoom);
        }
      }
    });
  }

  // Keyboard Movement Handler (WASD & Arrow Keys)
  void _handleKeyEvent(RawKeyEvent event, TelemetryProvider telemetry) {
    // FIX 1: Prevent keyboard controls from working in Normal Mode
    if (!telemetry.isSimulationMode) return;

    if (event is RawKeyDownEvent) {
      double speed = 0.00008;
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        telemetry.moveAvatar(speed, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        telemetry.moveAvatar(-speed, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        telemetry.moveAvatar(0, -speed);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        telemetry.moveAvatar(0, speed);
      }
      _mapController.move(LatLng(telemetry.currentLat, telemetry.currentLng),
          _mapController.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: telemetry.isSosActive
                    ? Colors.redAccent
                    : AppColors.primaryGold.withOpacity(0.85),
                width: telemetry.isSosActive ? 2.8 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: telemetry.isSosActive
                      ? Colors.redAccent.withOpacity(0.75)
                      : AppColors.primaryGold.withOpacity(0.35),
                  blurRadius: telemetry.isSosActive ? 28 : 18,
                  spreadRadius: telemetry.isSosActive ? 4 : 2,
                ),
              ],
            ),
            child: RawKeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKey: (event) => _handleKeyEvent(event, telemetry),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // 1. INTERACTIVE MAP CANVAS
                    FlutterMap(
                      // FIX 3: ValueKey prevents the map from rebuilding and losing zoom/pan state
                      key: const ValueKey('luma_map_layer'),
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: telemetry.hasCurrentLocation ||
                                telemetry.isSimulationMode
                            ? LatLng(telemetry.currentLat, telemetry.currentLng)
                            : LatLng(
                                telemetry.destinationLat,
                                telemetry.destinationLng,
                              ),
                        initialZoom: 15.8,
                        keepAlive: true, // Helps preserve camera state
                        onMapReady: () {
                          _mapReady = true;
                          _lastMapCenter = null;
                          _followCurrentLocation();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.lunawalk.app',
                        ),

                        // Polylines
                        PolylineLayer(
                          polylines: telemetry.hasCurrentLocation ||
                                  telemetry.isSimulationMode
                              ? [
                                  Polyline(
                                    points: telemetry.routePoints,
                                    strokeWidth: 5,
                                    color: telemetry.selectedRouteIndex == 0
                                        ? AppColors.routeSafe
                                        : AppColors.routeUnsafe,
                                  ),
                                ]
                              : const [],
                        ),

                        // Map Markers
                        MarkerLayer(
                          markers: [
                            // DYNAMIC USER AVATAR MARKER
                            if (telemetry.hasCurrentLocation ||
                                telemetry.isSimulationMode)
                              Marker(
                                point: LatLng(
                                  telemetry.currentLat,
                                  telemetry.currentLng,
                                ),
                                width: 46,
                                height: 46,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.background,
                                    border: Border.all(
                                      color: AppColors.primaryGold,
                                      width: 2.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGold
                                            .withOpacity(0.7),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            Marker(
                              point: LatLng(
                                telemetry.destinationLat,
                                telemetry.destinationLng,
                              ),
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.location_on,
                                  color: Colors.redAccent, size: 32),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 2. STARLIGHT CORNER ACCENTS
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Icon(
                        Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Icon(
                        Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Icon(
                        Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18,
                      ),
                    ),

                    // 3. TOP SEARCH BAR OR TURN-BY-TURN HUD
                    if (!telemetry.isNavigating)
                      Positioned(
                        top: 24,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school,
                                  color: AppColors.primaryGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Destination',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      telemetry.destinationName,
                                      style: const TextStyle(
                                        color: AppColors.textMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (telemetry.isLocating)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGold,
                                  ),
                                )
                              else if (!telemetry.isSimulationMode)
                                IconButton(
                                  tooltip: telemetry.locationError ??
                                      'Get current location',
                                  onPressed: telemetry.refreshCurrentLocation,
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 24,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2B1D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.routeSafe, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 10)
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.routeSafe,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.route,
                                    color: Colors.black, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Following selected route",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Stay on your selected route to ${telemetry.destinationName}",
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 4. OFF-TRACK ALERTS & NOTIFICATIONS
                    if (telemetry.showOffTrackModal)
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.redAccent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.5),
                                    blurRadius: 20)
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.redAccent, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  "⚠️ Path Deviation Detected",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "You are off the selected ${telemetry.selectedRouteIndex == 0 ? "Safe" : "Direct"} route. Are you safe?",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textMain, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGold),
                                        onPressed: () =>
                                            telemetry.dismissOffTrackModal(),
                                        child: const Text("I'm Safe",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent),
                                        onPressed: () {
                                          telemetry.dismissOffTrackModal();
                                          telemetry.toggleSosAlert();
                                        },
                                        child: const Text("Escalate SOS",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (telemetry.showBackOnTrackBanner &&
                        !telemetry.showOffTrackModal)
                      Positioned(
                        top: 90,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.routeSafe.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "✨ Safe Corridor Reconnected: You are back on the recommended path.",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ========================================================
                    // 5. INTERACTIVE JOYSTICK + CLICKABLE ARROW PAD
                    // ========================================================
                    if (telemetry.isSimulationMode)
                      Positioned(
                        bottom: 16,
                        left: 10,
                        child: Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputBackground.withOpacity(0.85),
                            border: Border.all(
                                color: AppColors.primaryGold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primaryGold.withOpacity(0.4),
                                  blurRadius: 12),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    telemetry.moveAvatar(0.00008, 0);
                                    _mapController.move(
                                        LatLng(telemetry.currentLat,
                                            telemetry.currentLng),
                                        _mapController.zoom);
                                  },
                                  child: const Icon(Icons.arrow_drop_up,
                                      color: AppColors.primaryGold, size: 26),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    telemetry.moveAvatar(-0.00008, 0);
                                    _mapController.move(
                                        LatLng(telemetry.currentLat,
                                            telemetry.currentLng),
                                        _mapController.zoom);
                                  },
                                  child: const Icon(Icons.arrow_drop_down,
                                      color: AppColors.primaryGold, size: 26),
                                ),
                              ),
                              Positioned(
                                left: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    telemetry.moveAvatar(0, -0.00008);
                                    _mapController.move(
                                        LatLng(telemetry.currentLat,
                                            telemetry.currentLng),
                                        _mapController.zoom);
                                  },
                                  child: const Icon(Icons.arrow_left,
                                      color: AppColors.primaryGold, size: 26),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    telemetry.moveAvatar(0, 0.00008);
                                    _mapController.move(
                                        LatLng(telemetry.currentLat,
                                            telemetry.currentLng),
                                        _mapController.zoom);
                                  },
                                  child: const Icon(Icons.arrow_right,
                                      color: AppColors.primaryGold, size: 26),
                                ),
                              ),
                              GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _joystickDelta += details.delta;
                                    if (_joystickDelta.distance > 25) {
                                      _joystickDelta = Offset.fromDirection(
                                          _joystickDelta.direction, 25);
                                    }
                                  });
                                  double speed = 0.00003;
                                  telemetry.moveAvatar(
                                      -_joystickDelta.dy * speed,
                                      _joystickDelta.dx * speed);
                                  _mapController.move(
                                      LatLng(telemetry.currentLat,
                                          telemetry.currentLng),
                                      _mapController.zoom);
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _joystickDelta = Offset.zero;
                                  });
                                },
                                child: Transform.translate(
                                  offset: _joystickDelta,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGold,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 6)
                                      ],
                                    ),
                                    child: const Icon(Icons.open_with,
                                        color: Colors.black, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ========================================================
                    // 6. BOTTOM CONTROL PANEL
                    // ========================================================
                    Positioned(
                      bottom: 16,
                      left: telemetry.isSimulationMode ? 135 : 16,
                      right: 16,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                              telemetry.isSimulationMode ? 10 : 12),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: telemetry.isNavigating
                                  ? AppColors.routeSafe
                                  : AppColors.primaryGold.withOpacity(0.3),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: telemetry.isNavigating
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            telemetry.selectedRouteIndex == 0
                                                ? Icons.shield
                                                : Icons.route,
                                            color:
                                                telemetry.selectedRouteIndex ==
                                                        0
                                                    ? AppColors.routeSafe
                                                    : AppColors.routeUnsafe,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Following ${telemetry.selectedRouteIndex == 0 ? "Safe" : "Direct"} route to ${telemetry.destinationName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textMain,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent
                                                .withOpacity(0.85),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(21),
                                            ),
                                          ),
                                          onPressed: telemetry.stopNavigation,
                                          icon: const Icon(Icons.close,
                                              color: Colors.white, size: 18),
                                          label: const Text(
                                            "End Navigation",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.navigation,
                                              color: AppColors.primaryGold,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Route to: ${telemetry.destinationName}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textMain,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Choose a route. Your choice stays fixed during the walk.',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _RouteChoiceButton(
                                              title: 'Safe',
                                              subtitle: 'Safety simulation',
                                              selected: telemetry
                                                      .hasSelectedRoute &&
                                                  telemetry
                                                          .selectedRouteIndex ==
                                                      0,
                                              color: AppColors.routeSafe,
                                              onTap: !telemetry.isFetchingApi &&
                                                      (telemetry
                                                              .hasCurrentLocation ||
                                                          telemetry
                                                              .isSimulationMode)
                                                  ? () =>
                                                      telemetry.selectRoute(0)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _RouteChoiceButton(
                                              title: 'Direct',
                                              subtitle: 'Direct simulation',
                                              selected: telemetry
                                                      .hasSelectedRoute &&
                                                  telemetry
                                                          .selectedRouteIndex ==
                                                      1,
                                              color: AppColors.routeUnsafe,
                                              onTap: !telemetry.isFetchingApi &&
                                                      (telemetry
                                                              .hasCurrentLocation ||
                                                          telemetry
                                                              .isSimulationMode)
                                                  ? () =>
                                                      telemetry.selectRoute(1)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!telemetry.hasCurrentLocation &&
                                          !telemetry.isSimulationMode) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          telemetry.locationError ??
                                              'Waiting for your GPS location',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGold,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          onPressed: telemetry.isFetchingApi ||
                                                  !telemetry.hasSelectedRoute
                                              ? null
                                              : () async {
                                                  await telemetry
                                                      .triggerNavigationApiCall();
                                                },
                                          child: telemetry.isFetchingApi
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : const Text(
                                                  "Start Navigation",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteChoiceButton extends StatelessWidget {
  const _RouteChoiceButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          border: Border.all(
            color: selected
                ? color
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

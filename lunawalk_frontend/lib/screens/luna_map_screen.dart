import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/telemetry_provider.dart';
import '../services/destination_search_service.dart';
import '../theme/app_colors.dart';

class LunaMapScreen extends StatefulWidget {
  const LunaMapScreen({super.key});

  @override
  State<LunaMapScreen> createState() => _LunaMapScreenState();
}

class _LunaMapScreenState extends State<LunaMapScreen> {
  final MapController _mapController = MapController();
  final FocusNode _focusNode = FocusNode();

  final TextEditingController _destinationController = TextEditingController();
  final DestinationSearchService _destinationSearchService =
      DestinationSearchService();
  Timer? _destinationSearchDebounce;
  int _destinationSearchRequestId = 0;
  bool _mapReady = false;
  bool _hasAutoFittedRoute = false;
  bool _hasShownArrivalDialog = false;
  bool _isSearchingDestinations = false;
  String? _destinationSearchError;
  List<DestinationSearchResult> _destinationSuggestions = const [];
  List<DestinationSearchResult> _destinationHistory = const [];
  LatLng? _lastMapCenter;
  final FlutterTts _speech = FlutterTts();
  String? _lastSpokenInstruction;
  late final TelemetryProvider _telemetry;

  @override
  void initState() {
    super.initState();
    _telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    _telemetry.addListener(_handleTelemetryChanged);
    _telemetry.avatarPosition.addListener(_handleAvatarPositionChanged);
    unawaited(_loadDestinationHistory());
  }

  @override
  void dispose() {
    _telemetry.removeListener(_handleTelemetryChanged);
    _telemetry.avatarPosition.removeListener(_handleAvatarPositionChanged);
    unawaited(_speech.stop());
    _destinationSearchDebounce?.cancel();
    _destinationSearchService.dispose();
    _destinationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTelemetryChanged() {
    if (mounted) setState(() {});
    final telemetry = _telemetry;
    _followCurrentLocation();
    if (!telemetry.hasReachedDestination) {
      _hasShownArrivalDialog = false;
    } else if (!_hasShownArrivalDialog) {
      _hasShownArrivalDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDestinationReachedDialog();
      });
    }

    if (!telemetry.isNavigating && !telemetry.hasReachedDestination) {
      _lastSpokenInstruction = null;
    } else {
      final instruction = telemetry.navigationInstruction;
      if (instruction != null && instruction != _lastSpokenInstruction) {
        _lastSpokenInstruction = instruction;
        unawaited(_speakInstruction(instruction));
      }
    }
  }

  void _handleAvatarPositionChanged() {
    if (mounted) _followCurrentLocation();
  }

  Future<void> _speakInstruction(String instruction) async {
    try {
      await _speech.setLanguage('en-US');
      await _speech.speak(instruction);
    } catch (error, stackTrace) {
      debugPrint('Could not play navigation instruction: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showDestinationReachedDialog() {
    final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        icon: const Icon(Icons.check_circle,
            color: AppColors.routeSafe, size: 44),
        title: const Text(
          'You have reached your destination!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          'You have arrived at ${telemetry.destinationName}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _destinationController.clear();
            },
            child: const Text('Search another destination'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _handleDestinationQueryChanged(String query) {
    _destinationSearchDebounce?.cancel();
    final requestId = ++_destinationSearchRequestId;
    setState(() {
      _isSearchingDestinations = false;
      _destinationSearchError = null;
      _destinationSuggestions =
          query.trim().isEmpty ? _destinationHistory : const [];
    });

    if (query.trim().isEmpty ||
        query.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').length < 2) {
      return;
    }
    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _searchDestinations(query: query, requestId: requestId),
    );
  }

  Future<void> _searchDestinations({
    String? query,
    int? requestId,
  }) async {
    final searchQuery = (query ?? _destinationController.text).trim();
    if (requestId == null) _destinationSearchDebounce?.cancel();
    final currentRequestId = requestId ?? ++_destinationSearchRequestId;
    if (searchQuery.isEmpty) {
      setState(() {
        _destinationSearchError = null;
        _destinationSuggestions = _destinationHistory;
      });
      return;
    }

    setState(() {
      _isSearchingDestinations = true;
      _destinationSearchError = null;
      _destinationSuggestions = const [];
    });
    try {
      final results = await _destinationSearchService.search(searchQuery);
      if (!mounted || currentRequestId != _destinationSearchRequestId) return;
      setState(() {
        _destinationSuggestions = results;
        if (results.isEmpty) {
          _destinationSearchError =
              'No destinations found. Try a nearby place or address.';
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Destination search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || currentRequestId != _destinationSearchRequestId) return;
      setState(() {
        _destinationSearchError =
            'Could not search destinations. Check your internet connection and try again.';
      });
    } finally {
      if (mounted && currentRequestId == _destinationSearchRequestId) {
        setState(() => _isSearchingDestinations = false);
      }
    }
  }

  void _selectDestination(
      DestinationSearchResult result, TelemetryProvider telemetry) {
    _destinationSearchDebounce?.cancel();
    _destinationSearchRequestId++;
    telemetry.setDestination(result.point, name: result.name);
    _destinationController.text = result.name;
    setState(() {
      _destinationSuggestions = const [];
      _destinationSearchError = null;
      _hasAutoFittedRoute = false;
    });
    unawaited(_saveDestinationToHistory(result));
  }

  Future<void> _loadDestinationHistory() async {
    try {
      final history = await _destinationSearchService.loadHistory();
      if (!mounted) return;
      setState(() {
        _destinationHistory = history;
        if (_destinationController.text.isEmpty) {
          _destinationSuggestions = history;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load destination search history: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _destinationSearchError = 'Could not load recent destinations.';
      });
    }
  }

  Future<void> _saveDestinationToHistory(
    DestinationSearchResult destination,
  ) async {
    try {
      final history = await _destinationSearchService.addToHistory(destination);
      if (!mounted) return;
      setState(() => _destinationHistory = history);
    } catch (error, stackTrace) {
      debugPrint('Could not save destination search history: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _destinationSearchError =
            'Destination selected, but could not save it to recent searches.';
      });
    }
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
          if (telemetry.hasDestination) {
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
          } else {
            _mapController.move(position, 15.8);
          }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = _telemetry;

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
                          userAgentPackageName: 'com.lumawalk.app',
                        ),
                        const SimpleAttributionWidget(
                          source: Text('OpenStreetMap contributors'),
                        ),

                        // Polylines
                        PolylineLayer(
                          polylines: [
                            if ((!telemetry.isNavigating ||
                                    telemetry.selectedRouteIndex == 1) &&
                                telemetry.directRoute != null)
                              Polyline(
                                points: telemetry.directRoute!.points,
                                strokeWidth: telemetry.hasSelectedRoute &&
                                        telemetry.selectedRouteIndex == 1
                                    ? 5
                                    : 3,
                                color: AppColors.routeUnsafe.withOpacity(
                                  telemetry.hasSelectedRoute &&
                                          telemetry.selectedRouteIndex == 1
                                      ? 0.95
                                      : 0.45,
                                ),
                              ),
                            if ((!telemetry.isNavigating ||
                                    telemetry.selectedRouteIndex == 0) &&
                                telemetry.safeRoute != null)
                              Polyline(
                                points: telemetry.safeRoute!.points,
                                strokeWidth: telemetry.hasSelectedRoute &&
                                        telemetry.selectedRouteIndex == 0
                                    ? 5
                                    : 3,
                                color: AppColors.routeSafe.withOpacity(
                                  telemetry.isNavigating ||
                                          (telemetry.hasSelectedRoute &&
                                              telemetry.selectedRouteIndex == 0)
                                      ? 0.95
                                      : 0.55,
                                ),
                              ),
                          ],
                        ),

                        ValueListenableBuilder<AvatarPosition>(
                          valueListenable: telemetry.avatarPosition,
                          builder: (context, avatarPosition, _) => MarkerLayer(
                            markers: [
                              if (telemetry.hasCurrentLocation ||
                                  telemetry.isSimulationMode)
                                Marker(
                                  point: avatarPosition.point,
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
                                    child: telemetry.isSimulationMode
                                        ? ClipOval(
                                            child: Image.asset(
                                              'assets/images/logo.jpeg',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Transform.rotate(
                                            angle: avatarPosition.heading *
                                                math.pi /
                                                180,
                                            child: const Icon(
                                              Icons.navigation,
                                              color: AppColors.primaryGold,
                                              size: 28,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Destination and safe-haven markers update with map state.
                        MarkerLayer(
                          markers: [
                            if (telemetry.hasDestination)
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
                            for (final haven in telemetry.nearbySafeHavens)
                              Marker(
                                point: haven.point,
                                width: 28,
                                height: 28,
                                child: Tooltip(
                                  message:
                                      'OSM safe haven • Class ${haven.classification}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: haven.classification == 'A'
                                          ? Colors.amber
                                          : Colors.blueAccent,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shield,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.search,
                                      color: AppColors.primaryGold),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _destinationController,
                                      textInputAction: TextInputAction.search,
                                      onChanged: _handleDestinationQueryChanged,
                                      onSubmitted: (_) => _searchDestinations(),
                                      style: const TextStyle(
                                        color: AppColors.textMain,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: telemetry.hasDestination
                                            ? telemetry.destinationName
                                            : 'Where do you want to go?',
                                        hintStyle: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        suffixIcon: _destinationController
                                                .text.isNotEmpty
                                            ? IconButton(
                                                tooltip: 'Clear destination',
                                                onPressed: () {
                                                  _destinationController
                                                      .clear();
                                                  _handleDestinationQueryChanged(
                                                    '',
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.close,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Search destination',
                                    onPressed: _isSearchingDestinations
                                        ? null
                                        : _searchDestinations,
                                    icon: _isSearchingDestinations
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryGold,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.search,
                                            color: AppColors.primaryGold,
                                          ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _destinationController.text.isEmpty
                                      ? (_destinationHistory.isEmpty
                                          ? 'Search places and addresses'
                                          : 'Recent destinations')
                                      : 'Search results update as you type • routes cover Petaling Jaya',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (_destinationSearchError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _destinationSearchError!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_destinationSuggestions.isNotEmpty)
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 190),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _destinationSuggestions.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final result =
                                          _destinationSuggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.primaryGold,
                                        ),
                                        title: Text(
                                          result.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMain,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onTap: () => _selectDestination(
                                          result,
                                          telemetry,
                                        ),
                                      );
                                    },
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
                                    if (telemetry.navigationInstruction != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          telemetry.navigationInstruction!,
                                          style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                        child: _SimulationJoystick(
                          onUp: () => telemetry.moveAvatar(0.00008, 0),
                          onDown: () => telemetry.moveAvatar(-0.00008, 0),
                          onLeft: () => telemetry.moveAvatar(0, -0.00008),
                          onRight: () => telemetry.moveAvatar(0, 0.00008),
                          onMove: (offset) {
                            const maxDistancePerTick = 0.0000012;
                            telemetry.moveAvatar(
                              -offset.dy /
                                  _SimulationJoystickState._maxKnobOffset *
                                  maxDistancePerTick,
                              offset.dx /
                                  _SimulationJoystickState._maxKnobOffset *
                                  maxDistancePerTick,
                            );
                          },
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
                                        'Choose a destination on the map, then select a route. Your route stays fixed during the walk.',
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
                                              subtitle: telemetry.safeRoute ==
                                                      null
                                                  ? !telemetry.hasDestination
                                                      ? 'Choose destination first'
                                                      : (telemetry.isRouteLoading ||
                                                              telemetry
                                                                  .isMapDataLoading
                                                          ? 'Loading OSM data…'
                                                          : 'Unavailable')
                                                  : '${(telemetry.safeRoute!.distanceMeters / 1000).toStringAsFixed(1)} km • ${(telemetry.safeRoute!.lightingScore * 100).round()}% lit',
                                              selected: telemetry
                                                      .hasSelectedRoute &&
                                                  telemetry
                                                          .selectedRouteIndex ==
                                                      0,
                                              color: AppColors.routeSafe,
                                              onTap: telemetry.safeRoute !=
                                                          null &&
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
                                              subtitle: telemetry.directRoute ==
                                                      null
                                                  ? !telemetry.hasDestination
                                                      ? 'Choose destination first'
                                                      : (telemetry.isRouteLoading ||
                                                              telemetry
                                                                  .isMapDataLoading
                                                          ? 'Loading OSM data…'
                                                          : 'Unavailable')
                                                  : '${(telemetry.directRoute!.distanceMeters / 1000).toStringAsFixed(1)} km • ${(telemetry.directRoute!.lightingScore * 100).round()}% lit',
                                              selected: telemetry
                                                      .hasSelectedRoute &&
                                                  telemetry
                                                          .selectedRouteIndex ==
                                                      1,
                                              color: AppColors.routeUnsafe,
                                              onTap: telemetry.directRoute !=
                                                          null &&
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
                                      if (telemetry.routeError != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          telemetry.routeError!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (telemetry.routeError!.startsWith(
                                          'FastAPI is unreachable',
                                        ))
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed:
                                                  telemetry.isRouteLoading
                                                      ? null
                                                      : telemetry.retryRoute,
                                              icon: const Icon(
                                                Icons.refresh,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Retry backend connection',
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primaryGold,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
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
                                          onPressed: !telemetry
                                                      .hasDestination ||
                                                  !telemetry.hasSelectedRoute ||
                                                  telemetry.routePoints.isEmpty
                                              ? null
                                              : telemetry.startNavigation,
                                          child: const Text(
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

class _SimulationJoystick extends StatefulWidget {
  const _SimulationJoystick({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onMove,
  });

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final ValueChanged<Offset> onMove;

  @override
  State<_SimulationJoystick> createState() => _SimulationJoystickState();
}

class _SimulationJoystickState extends State<_SimulationJoystick> {
  static const _moveInterval = Duration(milliseconds: 50);
  static const _maxKnobOffset = 25.0;

  Offset _knobOffset = Offset.zero;
  Timer? _movementTimer;

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _startMovement() {
    _movementTimer ??= Timer.periodic(
      _moveInterval,
      (_) => widget.onMove(_knobOffset),
    );
  }

  void _updateKnob(DragUpdateDetails details) {
    setState(() {
      final nextOffset = _knobOffset + details.delta;
      _knobOffset = nextOffset.distance > _maxKnobOffset
          ? Offset.fromDirection(nextOffset.direction, _maxKnobOffset)
          : nextOffset;
    });
  }

  void _stopMovement() {
    _movementTimer?.cancel();
    _movementTimer = null;
    setState(() => _knobOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      height: 115,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputBackground.withOpacity(0.85),
        border: Border.all(color: AppColors.primaryGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: GestureDetector(
              onTap: widget.onUp,
              child: const Icon(
                Icons.arrow_drop_up,
                color: AppColors.primaryGold,
                size: 26,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: GestureDetector(
              onTap: widget.onDown,
              child: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primaryGold,
                size: 26,
              ),
            ),
          ),
          Positioned(
            left: 4,
            child: GestureDetector(
              onTap: widget.onLeft,
              child: const Icon(
                Icons.arrow_left,
                color: AppColors.primaryGold,
                size: 26,
              ),
            ),
          ),
          Positioned(
            right: 4,
            child: GestureDetector(
              onTap: widget.onRight,
              child: const Icon(
                Icons.arrow_right,
                color: AppColors.primaryGold,
                size: 26,
              ),
            ),
          ),
          GestureDetector(
            onPanStart: (_) => _startMovement(),
            onPanUpdate: _updateKnob,
            onPanEnd: (_) => _stopMovement(),
            onPanCancel: _stopMovement,
            child: Transform.translate(
              offset: _knobOffset,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold,
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
                child: const Icon(
                  Icons.open_with,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

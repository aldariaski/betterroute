import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/route_result.dart';
import '../services/api.dart';
import '../widgets/map_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();
  final originSearch = TextEditingController();
  final destinationSearch = TextEditingController();
  Timer? _searchTimer;
  int _originSearchVersion = 0;
  int _destinationSearchVersion = 0;
  List<Place> originSuggestions = [];
  List<Place> destinationSuggestions = [];
  Place? origin;
  Place? destination;
  List<RouteResult> routes = [];
  int selectedRoute = 0;
  bool loading = false;
  bool searchingOrigin = false;
  bool searchingDestination = false;
  bool navigating = false;
  String? error;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? livePosition;
  int currentStep = 0;
  DateTime? _lastReroute;

  RouteResult? get route =>
      routes.isEmpty ? null : routes[selectedRoute.clamp(0, routes.length - 1)];

  @override
  void dispose() {
    _searchTimer?.cancel();
    _positionSubscription?.cancel();
    originSearch.dispose();
    destinationSearch.dispose();
    super.dispose();
  }

  void _search(bool forOrigin, String query) {
    final version =
        forOrigin ? ++_originSearchVersion : ++_destinationSearchVersion;
    _searchTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        if (forOrigin)
          originSuggestions = [];
        else
          destinationSuggestions = [];
      });
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        if (forOrigin)
          searchingOrigin = true;
        else
          searchingDestination = true;
      });
      try {
        final matches = await api.searchPlaces(trimmed);
        if (!mounted) return;
        if (version !=
            (forOrigin ? _originSearchVersion : _destinationSearchVersion))
          return;
        setState(() {
          if (forOrigin)
            originSuggestions = matches;
          else
            destinationSuggestions = matches;
        });
      } catch (e) {
        if (mounted &&
            version ==
                (forOrigin ? _originSearchVersion : _destinationSearchVersion))
          setState(() => error = e.toString());
      } finally {
        if (mounted &&
            version ==
                (forOrigin ? _originSearchVersion : _destinationSearchVersion))
          setState(() {
            if (forOrigin)
              searchingOrigin = false;
            else
              searchingDestination = false;
          });
      }
    });
  }

  void _selectPlace(Place place, bool forOrigin) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (forOrigin) {
        origin = place;
        originSearch.text = place.name;
        originSuggestions = [];
      } else {
        destination = place;
        destinationSearch.text = place.name;
        destinationSuggestions = [];
      }
      routes = [];
      error = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception(
          'Turn on location services to use your current location.',
        );
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw Exception(
          'Location permission was not granted. Enable it in Settings to use your location.',
        );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final place = Place(
        name: 'Current location',
        address: 'GPS position',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        origin = place;
        originSearch.text = place.name;
        routes = [];
        error = null;
      });
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _calculateRoutes() async {
    if (origin == null || destination == null) {
      setState(() => error = 'Choose an origin and destination first.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await api.routes(
        originLat: origin!.latitude,
        originLng: origin!.longitude,
        destinationLat: destination!.latitude,
        destinationLng: destination!.longitude,
      );
      if (!mounted) return;
      setState(() {
        routes = results;
        selectedRoute = 0;
        currentStep = 0;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _startNavigation() async {
    if (route == null) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Turn on location services to start navigation.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw Exception('Location permission was not granted.');
      final firstFix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _positionSubscription?.cancel();
      setState(() {
        navigating = true;
        livePosition = LatLng(firstFix.latitude, firstFix.longitude);
        error = null;
      });
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen(
        _onPosition,
        onError: (Object e) {
          if (mounted) setState(() => error = 'Location updates stopped: $e');
        },
      );
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onPosition(Position position) {
    final current = LatLng(position.latitude, position.longitude);
    if (mounted)
      setState(() {
        livePosition = current;
        _advanceStep(current);
      });
    _checkOffRoute(position);
  }

  void _advanceStep(LatLng position) {
    final steps = route?.steps ?? [];
    while (currentStep < steps.length - 1) {
      final point = _stepPoint(route!.geometry, currentStep + 1);
      if (point == null ||
          Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                point.latitude,
                point.longitude,
              ) >
              45)
        break;
      currentStep++;
    }
  }

  LatLng? _stepPoint(Map<String, dynamic> geometry, int index) {
    final coordinates = geometry['coordinates'] as List?;
    if (coordinates == null || coordinates.isEmpty) return null;
    final p =
        coordinates[(coordinates.length * index / (route?.steps.length ?? 1))
                .floor()
                .clamp(0, coordinates.length - 1)]
            as List;
    return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
  }

  void _checkOffRoute(Position position) {
    final coordinates = route?.geometry['coordinates'] as List?;
    if (coordinates == null || coordinates.isEmpty) return;
    var nearest = double.infinity;
    for (final item in coordinates) {
      final p = item as List;
      final d = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        (p[1] as num).toDouble(),
        (p[0] as num).toDouble(),
      );
      if (d < nearest) nearest = d;
    }
    if (nearest > 80 &&
        (_lastReroute == null ||
            DateTime.now().difference(_lastReroute!) >
                const Duration(seconds: 30))) {
      _lastReroute = DateTime.now();
      final newOrigin = Place(
        name: 'Current location',
        address: 'GPS position',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        origin = newOrigin;
        routes = [];
        navigating = false;
      });
      _positionSubscription?.cancel();
      _calculateRoutes().then((_) {
        if (mounted && routes.isNotEmpty) _startNavigation();
      });
    }
  }

  Future<void> _stopNavigation() async {
    await _positionSubscription?.cancel();
    if (mounted)
      setState(() {
        navigating = false;
        livePosition = null;
      });
  }

  @override
  Widget build(BuildContext context) {
    final o =
        origin ??
        const Place(
          name: 'Jakarta',
          address: '',
          latitude: -6.2,
          longitude: 106.8166,
        );
    final d =
        destination ??
        const Place(
          name: 'Destination',
          address: '',
          latitude: -6.175392,
          longitude: 106.827153,
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('BetterRoute'),
        centerTitle: true,
        actions: [
          if (navigating)
            IconButton(
              tooltip: 'Stop navigation',
              onPressed: _stopNavigation,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                BetterRouteMap(
                  originLat: o.latitude,
                  originLng: o.longitude,
                  destinationLat: d.latitude,
                  destinationLng: d.longitude,
                  livePosition: livePosition,
                  route: route,
                  routeIndex: selectedRoute,
                ),
                if (navigating && route != null && route!.steps.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NEXT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              route!
                                  .steps[currentStep.clamp(
                                    0,
                                    route!.steps.length - 1,
                                  )]
                                  .instruction,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (route!
                                .steps[currentStep.clamp(
                                  0,
                                  route!.steps.length - 1,
                                )]
                                .name
                                .isNotEmpty)
                              Text(
                                route!
                                    .steps[currentStep.clamp(
                                      0,
                                      route!.steps.length - 1,
                                    )]
                                    .name,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: navigating ? 4 : 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black12),
                ],
              ),
              child: ListView(
                children: [
                  const Text(
                    'Plan your trip',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _placeField(
                    controller: originSearch,
                    label: 'Starting point',
                    suggestions: originSuggestions,
                    busy: searchingOrigin,
                    onChanged: (v) {
                      origin = null;
                      _search(true, v);
                    },
                    onSelect: (p) => _selectPlace(p, true),
                    suffix: IconButton(
                      tooltip: 'Use my location',
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location),
                    ),
                  ),
                  _placeField(
                    controller: destinationSearch,
                    label: 'Destination',
                    suggestions: destinationSuggestions,
                    busy: searchingDestination,
                    onChanged: (v) {
                      destination = null;
                      _search(false, v);
                    },
                    onSelect: (p) => _selectPlace(p, false),
                  ),
                  const SizedBox(height: 16),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: loading ? null : _calculateRoutes,
                          icon:
                              loading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.alt_route),
                          label: Text(
                            loading ? 'Finding routes…' : 'Find routes',
                          ),
                        ),
                      ),
                      if (route != null && !navigating) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Start guidance',
                          onPressed: _startNavigation,
                          icon: const Icon(Icons.navigation),
                        ),
                      ],
                    ],
                  ),
                  if (routes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    for (var i = 0; i < routes.length; i++) _routeCard(i),
                    if (route!.steps.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          'Directions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (var i = 0; i < route!.steps.length; i++)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 13,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(route!.steps[i].instruction),
                          subtitle: Text(
                            '${_distance(route!.steps[i].distanceM)}${route!.steps[i].name.isEmpty ? '' : ' · ${route!.steps[i].name}'}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeField({
    required TextEditingController controller,
    required String label,
    required List<Place> suggestions,
    required bool busy,
    required ValueChanged<String> onChanged,
    required ValueChanged<Place> onSelect,
    Widget? suffix,
  }) => Column(
    children: [
      TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            label == 'Destination' ? Icons.place_outlined : Icons.trip_origin,
          ),
          suffixIcon:
              busy
                  ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : suffix,
        ),
      ),
      if (suggestions.isNotEmpty)
        Card(
          child: Column(
            children: [
              for (final place in suggestions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(place.name),
                  subtitle: Text(
                    place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelect(place),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _routeCard(int index) {
    final item = routes[index];
    final active = selectedRoute == index;
    return Card(
      color: active ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: () => setState(() => selectedRoute = index),
        leading: Icon(
          active ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(
          '${item.durationMinutes.round()} min · ${item.distanceKm.toStringAsFixed(1)} km',
        ),
        subtitle: Text(
          index == 0 ? 'Recommended route' : 'Alternative ${index + 1}',
        ),
        trailing: Text('Route ${index + 1}'),
      ),
    );
  }

  String _distance(double meters) =>
      meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km'
          : '${meters.round()} m';
}

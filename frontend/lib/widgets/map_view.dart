import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route_result.dart';

class BetterRouteMap extends StatefulWidget {
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final LatLng? livePosition;
  final RouteResult? route;
  final int routeIndex;

  const BetterRouteMap({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.livePosition,
    required this.route,
    required this.routeIndex,
  });

  @override
  State<BetterRouteMap> createState() => _BetterRouteMapState();
}

class _BetterRouteMapState extends State<BetterRouteMap> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void didUpdateWidget(covariant BetterRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;

    final routeChanged =
        oldWidget.route != widget.route ||
        oldWidget.routeIndex != widget.routeIndex;
    if (routeChanged && widget.route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } else if (oldWidget.originLat != widget.originLat ||
        oldWidget.originLng != widget.originLng) {
      _mapController.move(LatLng(widget.originLat, widget.originLng), 12);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (widget.route != null) _fitRoute();
  }

  void _fitRoute() {
    final coordinates = widget.route?.geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return;

    final points = <LatLng>[];
    for (final coordinate in coordinates) {
      if (coordinate is! List || coordinate.length < 2) continue;
      final lng = coordinate[0];
      final lat = coordinate[1];
      if (lng is num && lat is num) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    if (points.length < 2) return;

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(40),
        maxZoom: 16,
      ),
    );
  }

  List<LatLng> _routePoints() {
    final coordinates = widget.route?.geometry['coordinates'];
    if (coordinates is! List) return const [];

    return [
      for (final coordinate in coordinates)
        if (coordinate is List &&
            coordinate.length >= 2 &&
            coordinate[0] is num &&
            coordinate[1] is num)
          LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      _marker(LatLng(widget.originLat, widget.originLng), Colors.blue),
      _marker(
        LatLng(widget.destinationLat, widget.destinationLng),
        Colors.green,
      ),
      if (widget.livePosition != null)
        _marker(widget.livePosition!, Colors.deepOrange, size: 20),
    ];
    final routePoints = _routePoints();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.originLat, widget.originLng),
        initialZoom: 12,
        onMapReady: _onMapReady,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.betterroute',
          maxNativeZoom: 19,
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.white.withValues(alpha: 0.95),
                strokeWidth: 10,
                borderColor: Colors.white,
              ),
              Polyline(
                points: routePoints,
                color: const Color(0xFF1463F3),
                strokeWidth: 6,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
    );
  }

  Marker _marker(LatLng point, Color color, {double size = 18}) => Marker(
    point: point,
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
    ),
  );
}

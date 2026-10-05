import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  MapLibreMapController? controller;
  Circle? _originCircle;
  Circle? _destinationCircle;
  Circle? _liveCircle;
  bool _styleLoaded = false;
  bool _routeSourceAdded = false;
  bool _updating = false;
  static const String _sourceId = 'route-source';
  static const String _layerId = 'route-layer';

  @override
  Widget build(BuildContext context) => MapLibreMap(
    styleString: 'https://demotiles.maplibre.org/style.json',
    initialCameraPosition: CameraPosition(
      target: LatLng(widget.originLat, widget.originLng),
      zoom: 12,
    ),
    onMapCreated: (c) => controller = c,
    onStyleLoadedCallback: _onStyleLoaded,
  );

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    _originCircle = null;
    _destinationCircle = null;
    _liveCircle = null;
    _routeSourceAdded = false;
    await _updateMap(fit: true);
  }

  @override
  void didUpdateWidget(covariant BetterRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_styleLoaded) return;
    final routeChanged =
        oldWidget.route != widget.route ||
        oldWidget.routeIndex != widget.routeIndex;
    _updateMap(fit: routeChanged);
  }

  Future<void> _updateMap({bool fit = false}) async {
    final c = controller;
    if (_updating || c == null || !_styleLoaded) return;
    _updating = true;
    try {
      await _updateCircle(
        c,
        _originCircle,
        LatLng(widget.originLat, widget.originLng),
        '#2563EB',
        (v) => _originCircle = v,
      );
      await _updateCircle(
        c,
        _destinationCircle,
        LatLng(widget.destinationLat, widget.destinationLng),
        '#16A34A',
        (v) => _destinationCircle = v,
      );
      if (widget.livePosition != null) {
        await _updateCircle(
          c,
          _liveCircle,
          widget.livePosition!,
          '#F97316',
          (v) => _liveCircle = v,
          radius: 9,
        );
      }
      await _updateRoute(c);
      if (fit && widget.route != null) await _fitRoute(c);
    } finally {
      _updating = false;
    }
  }

  Future<void> _updateCircle(
    MapLibreMapController c,
    Circle? circle,
    LatLng at,
    String color,
    void Function(Circle?) save, {
    double radius = 7,
  }) async {
    if (circle == null) {
      save(
        await c.addCircle(
          CircleOptions(
            circleRadius: radius,
            circleColor: color,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
            geometry: at,
          ),
        ),
      );
    } else {
      await c.updateCircle(circle, CircleOptions(geometry: at));
    }
  }

  Future<void> _updateRoute(MapLibreMapController c) async {
    final route = widget.route;
    if (route == null) {
      await _removeRoute(c);
      return;
    }
    final geoJson = <String, dynamic>{
      'type': 'Feature',
      'geometry': route.geometry,
      'properties': {},
    };
    if (_routeSourceAdded) {
      await c.setGeoJsonSource(_sourceId, geoJson);
      return;
    }
    await c.addSource(_sourceId, GeojsonSourceProperties(data: jsonEncode(geoJson)));
    await c.addLineLayer(
      _sourceId,
      _layerId,
      LineLayerProperties(
        lineColor: '#2563EB',
        lineWidth: 5,
        lineOpacity: 0.85,
      ),
      enableInteraction: false,
    );
    _routeSourceAdded = true;
  }

  Future<void> _fitRoute(MapLibreMapController c) async {
    final coordinates = widget.route?.geometry['coordinates'] as List?;
    if (coordinates == null || coordinates.isEmpty) return;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final point in coordinates) {
      final p = point as List;
      final lng = (p[0] as num).toDouble(), lat = (p[1] as num).toDouble();
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    if (minLat == maxLat && minLng == maxLng) return;
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 48,
        top: 64,
        right: 48,
        bottom: 260,
      ),
    );
  }

  Future<void> _removeRoute(MapLibreMapController c) async {
    if (!_routeSourceAdded) return;
    try {
      await c.removeLayer(_layerId);
    } catch (_) {}
    try {
      await c.removeSource(_sourceId);
    } catch (_) {}
    _routeSourceAdded = false;
  }

  @override
  void dispose() {
    _originCircle = null;
    _destinationCircle = null;
    _liveCircle = null;
    controller = null;
    super.dispose();
  }
}

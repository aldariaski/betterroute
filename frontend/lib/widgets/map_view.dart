import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/merchant.dart';
import '../models/route_result.dart';

class BetterRouteMap extends StatefulWidget {
  final Merchant? merchant;
  final double buyerLat;
  final double buyerLng;
  final RouteResult? route;

  const BetterRouteMap({
    super.key,
    required this.merchant,
    required this.buyerLat,
    required this.buyerLng,
    required this.route,
  });

  @override
  State<BetterRouteMap> createState() => _BetterRouteMapState();
}

class _BetterRouteMapState extends State<BetterRouteMap> {
  MapLibreMapController? controller;

  Circle? _buyerCircle;
  Circle? _merchantCircle;

  bool _styleLoaded = false;
  bool _updating = false;

  static const String _routeSourceId = 'route-source';
  static const String _routeLayerId = 'route-layer';

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: 'https://demotiles.maplibre.org/style.json',
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.buyerLat,
          widget.buyerLng,
        ),
        zoom: 11,
      ),
      onMapCreated: (controller) {
        this.controller = controller;
      },
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;

    await _updateMap();
  }

  @override
  void didUpdateWidget(covariant BetterRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_styleLoaded) {
      return;
    }

    // The widget itself is reused by Flutter.
    // Update the existing MapLibre objects instead of recreating the map.
    _updateMap();
  }

  Future<void> _updateMap() async {
    if (_updating) {
      return;
    }

    final c = controller;

    if (c == null || !_styleLoaded) {
      return;
    }

    _updating = true;

    try {
      await _updateBuyerMarker(c);
      await _updateMerchantMarker(c);
      await _updateRoute(c);
    } finally {
      _updating = false;
    }
  }

  Future<void> _updateBuyerMarker(
    MapLibreMapController c,
  ) async {
    final position = LatLng(
      widget.buyerLat,
      widget.buyerLng,
    );

    final existingCircle = _buyerCircle;

    if (existingCircle == null) {
      _buyerCircle = await c.addCircle(
        CircleOptions(
          circleRadius: 7,
          circleColor: '#2563EB',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
          geometry: position,
        ),
      );

      return;
    }

    await c.updateCircle(
      existingCircle,
      CircleOptions(
        geometry: position,
      ),
    );
  }

  Future<void> _updateMerchantMarker(
    MapLibreMapController c,
  ) async {
    final merchant = widget.merchant;

    // No merchant selected.
    if (merchant == null) {
      if (_merchantCircle != null) {
        await c.removeCircle(_merchantCircle!);
        _merchantCircle = null;
      }

      return;
    }

    final position = LatLng(
      merchant.latitude,
      merchant.longitude,
    );

    final existingCircle = _merchantCircle;

    // First merchant marker.
    if (existingCircle == null) {
      _merchantCircle = await c.addCircle(
        CircleOptions(
          circleRadius: 7,
          circleColor: '#16A34A',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
          geometry: position,
        ),
      );

      return;
    }

    // Update the existing merchant marker.
    await c.updateCircle(
      existingCircle,
      CircleOptions(
        geometry: position,
      ),
    );
  }

  Future<void> _updateRoute(
    MapLibreMapController c,
  ) async {
    final route = widget.route;

    // No route:
    // remove the existing route if one exists.
    if (route == null) {
      await _removeRoute(c);
      return;
    }

    final geoJson = jsonEncode({
      'type': 'Feature',
      'geometry': route.geometry,
      'properties': {},
    });

    // If the route source/layer already exists,
    // only update the GeoJSON data.
    if (await _hasRouteSource(c)) {
      await c.setGeoJsonSource(
        _routeSourceId,
        geoJson,
      );

      return;
    }

    // First route.
    await c.addSource(
      _routeSourceId,
      GeojsonSourceProperties(
        data: geoJson,
      ),
    );

    await c.addLineLayer(
      _routeSourceId,
      _routeLayerId,
      LineLayerProperties(
        lineColor: '#2563EB',
        lineWidth: 5,
        lineOpacity: 0.85,
      ),
    );
  }

  Future<bool> _hasRouteSource(
    MapLibreMapController c,
  ) async {
    try {
      final source = await c.getSource(_routeSourceId);
      return source != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeRoute(
    MapLibreMapController c,
  ) async {
    try {
      await c.removeLayer(_routeLayerId);
    } catch (_) {
      // Layer doesn't exist.
    }

    try {
      await c.removeSource(_routeSourceId);
    } catch (_) {
      // Source doesn't exist.
    }
  }

  @override
  void dispose() {
    _buyerCircle = null;
    _merchantCircle = null;
    controller = null;

    super.dispose();
  }
}
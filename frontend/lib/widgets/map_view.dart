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
  bool _routeSourceAdded = false;
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

      onMapCreated: (c) {
        controller = c;
      },

      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;

    // The style can be loaded again after the map/activity
    // is recreated, so all style objects need to be recreated.
    _buyerCircle = null;
    _merchantCircle = null;
    _routeSourceAdded = false;

    await _updateMap();
  }

  @override
  void didUpdateWidget(covariant BetterRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_styleLoaded) {
      return;
    }

    // HomeScreen changes the selected merchant or route.
    // The MapLibreMap itself stays alive, but its contents
    // need to be updated.
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

    if (_buyerCircle == null) {
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
      _buyerCircle!,
      CircleOptions(
        geometry: position,
      ),
    );
  }

  Future<void> _updateMerchantMarker(
    MapLibreMapController c,
  ) async {
    final merchant = widget.merchant;

    // Nothing is selected.
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

    // First merchant marker.
    if (_merchantCircle == null) {
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

    // Existing marker:
    // move it to the newly selected merchant.
    await c.updateCircle(
      _merchantCircle!,
      CircleOptions(
        geometry: position,
      ),
    );
  }

  Future<void> _updateRoute(
    MapLibreMapController c,
  ) async {
    final route = widget.route;

    // If there is no route, remove the old route.
    if (route == null) {
      await _removeRoute(c);
      return;
    }

    final geoJson = <String, dynamic>{
      'type': 'Feature',
      'geometry': route.geometry,
      'properties': <String, dynamic>{},
    };

    // Route already exists:
    // replace its GeoJSON without recreating the map.
    if (_routeSourceAdded) {
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
        data: jsonEncode(geoJson),
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
      enableInteraction: false,
    );

    _routeSourceAdded = true;
  }

  Future<void> _removeRoute(
    MapLibreMapController c,
  ) async {
    if (!_routeSourceAdded) {
      return;
    }

    try {
      await c.removeLayer(_routeLayerId);
    } catch (_) {
      // Layer may already have been removed.
    }

    try {
      await c.removeSource(_routeSourceId);
    } catch (_) {
      // Source may already have been removed.
    }

    _routeSourceAdded = false;
  }

  @override
  void dispose() {
    _buyerCircle = null;
    _merchantCircle = null;
    controller = null;

    super.dispose();
  }
}


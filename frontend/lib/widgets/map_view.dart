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
  const BetterRouteMap({super.key, required this.merchant, required this.buyerLat, required this.buyerLng, required this.route});
  @override State<BetterRouteMap> createState() => _BetterRouteMapState();
}

class _BetterRouteMapState extends State<BetterRouteMap> {
  MapLibreMapController? controller;
  @override
  Widget build(BuildContext context) => MapLibreMap(
    styleString: 'https://demotiles.maplibre.org/style.json',
    initialCameraPosition: CameraPosition(target: LatLng(widget.buyerLat, widget.buyerLng), zoom: 11),
    onMapCreated: (c) => controller = c,
    onStyleLoadedCallback: _draw,
  );

  Future<void> _draw() async {
    final c = controller; if (c == null) return;
    await c.addCircle(CircleOptions(circleRadius: 7, circleColor: '#2563EB', geometry: LatLng(widget.buyerLat, widget.buyerLng)));
    if (widget.merchant != null) {
      await c.addCircle(CircleOptions(circleRadius: 7, circleColor: '#16A34A', geometry: LatLng(widget.merchant!.latitude, widget.merchant!.longitude)));
    }
    if (widget.route != null) {
      await c.addSource('route-source', GeojsonSourceProperties(data: jsonEncode({'type':'Feature','geometry':widget.route!.geometry,'properties':{}})));
      await c.addLineLayer('route-source','route-layer',LineLayerProperties(lineColor:'#2563EB',lineWidth:5,lineOpacity:.85));
    }
  }
}

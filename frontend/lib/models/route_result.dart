class RouteResult {
  final double distanceKm;
  final double durationMinutes;
  final Map<String,dynamic> geometry;
  RouteResult({required this.distanceKm, required this.durationMinutes, required this.geometry});
  factory RouteResult.fromJson(Map<String,dynamic> json) => RouteResult(
    distanceKm: (json['distance_km'] as num).toDouble(),
    durationMinutes: (json['duration_minutes'] as num).toDouble(),
    geometry: Map<String,dynamic>.from(json['geometry']),
  );
}

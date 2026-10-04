class RouteStep {
  final String instruction;
  final String name;
  final double distanceM;
  final double durationS;
  final int type;

  const RouteStep({
    required this.instruction,
    required this.name,
    required this.distanceM,
    required this.durationS,
    required this.type,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
    instruction: json['instruction'] as String? ?? '',
    name: json['name'] as String? ?? '',
    distanceM: (json['distance_m'] as num? ?? 0).toDouble(),
    durationS: (json['duration_s'] as num? ?? 0).toDouble(),
    type: json['type'] as int? ?? 0,
  );
}

class RouteResult {
  final double distanceKm;
  final double durationMinutes;
  final Map<String, dynamic> geometry;
  final List<RouteStep> steps;

  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.geometry,
    this.steps = const [],
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) => RouteResult(
    distanceKm: (json['distance_km'] as num).toDouble(),
    durationMinutes: (json['duration_minutes'] as num).toDouble(),
    geometry: Map<String, dynamic>.from(json['geometry'] as Map),
    steps:
        ((json['steps'] as List?) ?? [])
            .map((e) => RouteStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
  );
}

class Place {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const Place({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

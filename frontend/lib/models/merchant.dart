class Merchant {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const Merchant({required this.id, required this.name, required this.address, required this.latitude, required this.longitude});

  factory Merchant.fromJson(Map<String,dynamic> json) => Merchant(
    id: json['id'], name: json['name'], address: json['address'] ?? '',
    latitude: (json['latitude'] as num).toDouble(), longitude: (json['longitude'] as num).toDouble(),
  );
}

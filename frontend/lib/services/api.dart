import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/merchant.dart';
import '../models/route_result.dart';

class ApiService {
  final String baseUrl;
  ApiService({this.baseUrl = 'http://10.0.2.2:8080'});

  Future<List<Merchant>> merchants() async {
    final r = await http.get(Uri.parse('$baseUrl/api/merchants'));
    if (r.statusCode != 200) throw Exception(_message(r));
    return (jsonDecode(r.body) as List)
        .map((e) => Merchant.fromJson(e))
        .toList();
  }

  Future<List<Place>> searchPlaces(String query) async {
    final uri = Uri.parse(
      '$baseUrl/api/places/search',
    ).replace(queryParameters: {'q': query});
    final r = await http.get(uri);
    if (r.statusCode != 200) throw Exception(_message(r));
    return (jsonDecode(r.body) as List).map((e) => Place.fromJson(e)).toList();
  }

  Future<List<RouteResult>> routes({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = Uri.parse('$baseUrl/api/route').replace(
      queryParameters: {
        'origin_lat': '$originLat',
        'origin_lng': '$originLng',
        'destination_lat': '$destinationLat',
        'destination_lng': '$destinationLng',
      },
    );
    final r = await http.get(uri);
    if (r.statusCode != 200) throw Exception(_message(r));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['routes'] as List)
        .map((e) => RouteResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String _message(http.Response r) {
    try {
      return (jsonDecode(r.body) as Map<String, dynamic>)['error'] as String? ??
          r.body;
    } catch (_) {
      return r.body;
    }
  }
}

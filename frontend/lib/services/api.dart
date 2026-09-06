import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/merchant.dart';
import '../models/route_result.dart';

class ApiService {
  // Android emulator -> host machine. For a physical phone, replace with your PC LAN IP.
  final String baseUrl;
  //ApiService({this.baseUrl = 'http://10.0.2.2:8080'});
  ApiService({this.baseUrl = 'http://localhost:8080'});

  Future<List<Merchant>> merchants() async {
    final r = await http.get(Uri.parse('$baseUrl/api/merchants'));
    if (r.statusCode != 200) throw Exception(r.body);
    return (jsonDecode(r.body) as List).map((e) => Merchant.fromJson(e)).toList();
  }

  Future<RouteResult> route({required double buyerLat, required double buyerLng, required Merchant merchant}) async {
    final uri = Uri.parse('$baseUrl/api/route').replace(queryParameters: {
      'buyer_lat': '$buyerLat', 'buyer_lng': '$buyerLng',
      'merchant_lat': '${merchant.latitude}', 'merchant_lng': '${merchant.longitude}',
    });
    final r = await http.get(uri);
    if (r.statusCode != 200) throw Exception(r.body);
    return RouteResult.fromJson(jsonDecode(r.body));
  }
}

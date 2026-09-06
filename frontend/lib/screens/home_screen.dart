import 'package:flutter/material.dart';

import '../models/merchant.dart';
import '../models/route_result.dart';
import '../services/api.dart';
import '../widgets/map_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();

  final lat = TextEditingController(text: '-6.200000');
  final lng = TextEditingController(text: '106.816666');

  List<Merchant> merchants = [];
  Merchant? selected;
  RouteResult? result;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await api.merchants();

      setState(() {
        merchants = m;
        selected = m.isNotEmpty ? m.first : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _route() async {
    if (selected == null) return;

    setState(() {
      error = null;
    });

    try {
      final r = await api.route(
        buyerLat: double.parse(lat.text),
        buyerLng: double.parse(lng.text),
        merchant: selected!,
      );

      setState(() {
        result = r;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerLat = double.tryParse(lat.text) ?? -6.2;
    final buyerLng = double.tryParse(lng.text) ?? 106.8166;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BetterRoute'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: BetterRouteMap(
                    merchant: selected,
                    buyerLat: buyerLat,
                    buyerLng: buyerLng,
                    route: result,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buyer location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lat,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: lng,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<Merchant>(
                        value: selected,
                        decoration: const InputDecoration(
                          labelText: 'Merchant',
                        ),
                        items: merchants
                            .map(
                              (m) => DropdownMenuItem<Merchant>(
                                value: m,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          setState(() {
                            selected = m;
                            result = null;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      if (result != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _metric(
                              '${result!.distanceKm.toStringAsFixed(1)} km',
                              'Distance',
                            ),
                            _metric(
                              '${result!.durationMinutes.toStringAsFixed(0)} min',
                              'ETA',
                            ),
                          ],
                        ),

                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _route,
                          icon: const Icon(Icons.route),
                          label: const Text('Calculate route'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}


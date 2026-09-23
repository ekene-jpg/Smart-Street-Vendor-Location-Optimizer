import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../services/app_state.dart';
import 'location_detail_screen.dart';
import 'preferences_screen.dart';
import 'login_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  List<VendorLocation> _locations = [];
  List<String> _areas = [];
  String? _selectedArea;
  bool _loading = true;
  String? _error;

  static const LatLng _lagosCenter = LatLng(6.5244, 3.3792);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AppState>().api;
      final areas = await api.fetchAreas();
      final locations = await api.fetchLocations(area: _selectedArea);
      setState(() {
        _areas = areas;
        _locations = locations;
      });
    } catch (e) {
      setState(() => _error = 'Could not load locations. Check the backend connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await appState.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedArea,
                    hint: const Text('All areas'),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      labelText: 'Filter by area',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All areas')),
                      ..._areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedArea = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: const MapOptions(initialCenter: _lagosCenter, initialZoom: 11),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.smart_vendor_app',
                      ),
                      MarkerLayer(
                        markers: _locations
                            .map(
                              (loc) => Marker(
                                point: LatLng(loc.latitude, loc.longitude),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LocationDetailScreen(locationId: loc.locationId),
                                    ),
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.tune),
        label: const Text('Get Recommendations'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PreferencesScreen(area: _selectedArea)),
        ),
      ),
    );
  }
}

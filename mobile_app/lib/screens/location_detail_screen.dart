import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../services/app_state.dart';

class LocationDetailScreen extends StatefulWidget {
  final int locationId;
  const LocationDetailScreen({super.key, required this.locationId});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  VendorLocation? _location;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AppState>().api;
      final loc = await api.fetchLocationDetail(widget.locationId);
      setState(() => _location = loc);
    } catch (e) {
      setState(() => _error = 'Could not load location details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _featureRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toStringAsFixed(1)} $unit', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_location?.name ?? 'Location Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_location!.area, style: Theme.of(context).textTheme.titleMedium),
                    if (_location!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(_location!.description!, style: const TextStyle(color: Colors.grey)),
                    ],
                    if (_location!.suitabilityScore != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Suitability score', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('${_location!.suitabilityScore!.toStringAsFixed(1)} / 100',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Location factors', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _featureRow('Pedestrian activity', _location!.pedestrianDensity, ''),
                    _featureRow('Accessibility', _location!.accessibilityScore, ''),
                    _featureRow('Distance to transport', _location!.transportDistance, 'm'),
                    _featureRow('Vendor competition', _location!.competitionLevel, ''),
                    _featureRow('Commercial activity', _location!.commercialActivity, ''),
                    _featureRow('Traffic density', _location!.trafficDensity, ''),
                    const SizedBox(height: 16),
                    Text('Coordinates: ${_location!.latitude.toStringAsFixed(5)}, '
                        '${_location!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/app_state.dart';
import 'results_screen.dart';

/// Lets the user adjust the weights (w_j) used in the suitability formula
/// S_i = sum_j( w_j * x_ij ) from Chapter 3, before requesting a ranked list.
class PreferencesScreen extends StatefulWidget {
  final String? area;
  const PreferencesScreen({super.key, this.area});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final Map<String, double> _weights = {
    'pedestrian_density': 0.25,
    'accessibility_score': 0.20,
    'transport_distance': 0.15,
    'competition_level': 0.15,
    'commercial_activity': 0.15,
    'traffic_density': 0.10,
  };

  static const _labels = {
    'pedestrian_density': 'Pedestrian activity',
    'accessibility_score': 'Accessibility',
    'transport_distance': 'Closeness to transport',
    'competition_level': 'Low vendor competition',
    'commercial_activity': 'Commercial activity',
    'traffic_density': 'Low traffic',
  };

  bool _loading = false;
  String? _error;

  double get _total => _weights.values.fold(0.0, (a, b) => a + b);

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AppState>().api;
      final results = await api.getRecommendations(area: widget.area, weights: _weights);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultsScreen(results: results)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.area == null
                ? 'Ranking candidate locations across all areas'
                : 'Ranking candidate locations in ${widget.area}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust how much each factor matters. Weights are combined using the '
            'weighted suitability model (S = Σ wⱼ·xⱼ).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ..._weights.keys.map((key) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_labels[key]!),
                        Text(_weights[key]!.toStringAsFixed(2)),
                      ],
                    ),
                    Slider(
                      value: _weights[key]!,
                      min: 0,
                      max: 0.5,
                      divisions: 50,
                      label: _weights[key]!.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _weights[key] = v),
                    ),
                  ],
                ),
              )),
          Text('Total weight: ${_total.toStringAsFixed(2)} (normalised automatically on the server)',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: const Text('Rank Locations'),
          ),
        ],
      ),
    );
  }
}

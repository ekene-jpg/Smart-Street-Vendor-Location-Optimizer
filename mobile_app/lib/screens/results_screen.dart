import 'package:flutter/material.dart';

import '../models/location.dart';
import 'location_detail_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<VendorLocation> results;
  const ResultsScreen({super.key, required this.results});

  Color _scoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 45) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Locations')),
      body: results.isEmpty
          ? const Center(child: Text('No candidate locations matched your filters.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final loc = results[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _scoreColor(loc.suitabilityScore ?? 0),
                      child: Text('${loc.rank ?? index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${loc.area} · Score: ${loc.suitabilityScore?.toStringAsFixed(1) ?? '-'} / 100'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LocationDetailScreen(locationId: loc.locationId)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

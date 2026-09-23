class VendorLocation {
  final int locationId;
  final String name;
  final double latitude;
  final double longitude;
  final String area;
  final String? description;
  final double pedestrianDensity;
  final double accessibilityScore;
  final double transportDistance;
  final double competitionLevel;
  final double commercialActivity;
  final double trafficDensity;
  final double? suitabilityScore;
  final int? rank;

  VendorLocation({
    required this.locationId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.area,
    this.description,
    required this.pedestrianDensity,
    required this.accessibilityScore,
    required this.transportDistance,
    required this.competitionLevel,
    required this.commercialActivity,
    required this.trafficDensity,
    this.suitabilityScore,
    this.rank,
  });

  factory VendorLocation.fromJson(Map<String, dynamic> json) {
    return VendorLocation(
      locationId: json['location_id'],
      name: json['location_name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      area: json['area'] ?? '',
      description: json['description'],
      pedestrianDensity: _toD(json['pedestrian_density']),
      accessibilityScore: _toD(json['accessibility_score']),
      transportDistance: _toD(json['transport_distance']),
      competitionLevel: _toD(json['competition_level']),
      commercialActivity: _toD(json['commercial_activity']),
      trafficDensity: _toD(json['traffic_density']),
      suitabilityScore: json['suitability_score'] == null
          ? null
          : (json['suitability_score'] as num).toDouble(),
      rank: json['rank'],
    );
  }

  static double _toD(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
}

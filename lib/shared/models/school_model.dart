class SchoolCollege {
  final String id;
  final String name;
  final String type; // Required in schema
  final String? city;
  final String? state;
  final double? latitude; // Changed from String
  final double? longitude; // Changed from String
  final bool isVerified;
  final DateTime? createdAt;

  SchoolCollege({
    required this.id,
    required this.name,
    this.city,
    this.state,
    required this.type,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.createdAt,
  });

  factory SchoolCollege.fromMap(Map<String, dynamic> map) => SchoolCollege(
    id: map['school_college_id'],
    name: map['name'] ?? '',
    type: map['type'] ?? '',
    city: map['city'],
    state: map['state'],
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    isVerified: map['is_verified'] ?? false,
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
  );
}

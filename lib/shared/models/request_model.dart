import 'app_enums.dart';

class RequestModel {
  final String id;
  final String? userId;
  final StuffType stuffType;
  final String description;
  final UrgentLevel urgencyLevel;
  final double? lat;
  final double? lng;
  final RequestStatus status;
  final VisiScope visibilityScope;
  final double radiusKm;
  final DateTime? createdAt;

  RequestModel({
    required this.id,
    this.userId,
    required this.stuffType,
    required this.description,
    this.urgencyLevel = UrgentLevel.MEDIUM,
    this.lat,
    this.lng,
    this.status = RequestStatus.OPEN,
    this.visibilityScope = VisiScope.PUBLIC,
    this.radiusKm = 2.0,
    this.createdAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['request_id'],
      userId: map['user_id'],
      stuffType: StuffType.values.firstWhere((e) => e.name == map['stuff_type']),
      description: map['description'] ?? '',
      urgencyLevel: UrgentLevel.values.firstWhere((e) => e.name == map['urgency_level'], orElse: () => UrgentLevel.MEDIUM),
      lat: (map['location_latitude'] as num?)?.toDouble(),
      lng: (map['location_longitude'] as num?)?.toDouble(),
      status: RequestStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => RequestStatus.OPEN),
      visibilityScope: VisiScope.values.firstWhere((e) => e.name == map['visibility_scope'], orElse: () => VisiScope.PUBLIC),
      radiusKm: (map['radius_km'] as num?)?.toDouble() ?? 2.0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'stuff_type': stuffType.name,
    'description': description,
    'urgency_level': urgencyLevel.name,
    'location_latitude': lat,
    'location_longitude': lng,
    'status': status.name,
    'visibility_scope': visibilityScope.name,
    'radius_km': radiusKm,
  };
}
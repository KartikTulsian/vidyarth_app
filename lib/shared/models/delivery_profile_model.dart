class DeliveryProfile {
  final String deliveryBoyId;
  final String? vehicleType;
  final String? licenseNumber;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final double averageRating;

  DeliveryProfile({
    required this.deliveryBoyId,
    this.vehicleType,
    this.licenseNumber,
    this.isAvailable = true,
    this.currentLat,
    this.currentLng,
    this.averageRating = 0.0,
  });

  factory DeliveryProfile.fromMap(Map<String, dynamic> map) {
    return DeliveryProfile(
      deliveryBoyId: map['delivery_boy_id'],
      vehicleType: map['vehicle_type'],
      licenseNumber: map['license_number'],
      isAvailable: map['is_available'] ?? true,
      currentLat: (map['current_latitude'] as num?)?.toDouble(),
      currentLng: (map['current_longitude'] as num?)?.toDouble(),
      averageRating: (map['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'delivery_boy_id': deliveryBoyId,
    'vehicle_type': vehicleType,
    'license_number': licenseNumber,
    'is_available': isAvailable,
    'current_latitude': currentLat,
    'current_longitude': currentLng,
  };
}
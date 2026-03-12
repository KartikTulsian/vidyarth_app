class DealerProfile {
  final String dealerId;
  final String shopName;
  final String? gstNumber;
  final String? businessAddress;
  final String? openingTime;
  final String? closingTime;
  final bool isVerified;
  final double? latitude;
  final double? longitude;

  DealerProfile({
    required this.dealerId,
    required this.shopName,
    this.gstNumber,
    this.businessAddress,
    this.openingTime,
    this.closingTime,
    this.isVerified = false,
    this.latitude,
    this.longitude,
  });

  factory DealerProfile.fromMap(Map<String, dynamic> map) {
    return DealerProfile(
      dealerId: map['dealer_id'] as String,
      shopName: map['shop_name'] as String,
      gstNumber: map['gst_number'] as String?,
      businessAddress: map['business_address'] as String?,
      openingTime: map['opening_time'] as String?,
      closingTime: map['closing_time'] as String?,
      isVerified: map['is_verified'] ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'dealer_id': dealerId,
    'shop_name': shopName,
    'gst_number': gstNumber,
    'business_address': businessAddress,
    'opening_time': openingTime,
    'closing_time': closingTime,
    'is_verified': isVerified,
    'latitude': latitude,
    'longitude': longitude,
  };
}
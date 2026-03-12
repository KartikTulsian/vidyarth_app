import 'app_enums.dart';

class Delivery {
  final String id;
  final String tradeId;
  final String? deliveryBoyId;
  final DeliveryStatus status;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? pickupProofUrl;
  final String? deliveryProofUrl;

  Delivery({
    required this.id,
    required this.tradeId,
    this.deliveryBoyId,
    this.status = DeliveryStatus.ASSIGNED,
    this.pickupTime,
    this.deliveryTime,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.pickupProofUrl,
    this.deliveryProofUrl,
  });

  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      id: map['delivery_id'],
      tradeId: map['trade_id'],
      deliveryBoyId: map['delivery_boy_id'],
      status: DeliveryStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DeliveryStatus.ASSIGNED),
      pickupTime: map['pickup_time'] != null ? DateTime.parse(map['pickup_time']) : null,
      deliveryTime: map['delivery_time'] != null ? DateTime.parse(map['delivery_time']) : null,
      pickupLat: (map['pickup_latitude'] as num?)?.toDouble(),
      pickupLng: (map['pickup_longitude'] as num?)?.toDouble(),
      dropLat: (map['drop_latitude'] as num?)?.toDouble(),
      dropLng: (map['drop_longitude'] as num?)?.toDouble(),
      pickupProofUrl: map['pickup_proof_url'],
      deliveryProofUrl: map['delivery_proof_url'],
    );
  }
}
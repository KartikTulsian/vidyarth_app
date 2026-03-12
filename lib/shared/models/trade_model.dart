import 'package:vidyarth_app/shared/models/app_enums.dart';

class Trade {
  final String? tradeId;
  final String offerId;
  final String borrowerId;
  final String lenderId;
  final TradeStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? finalizedPrice;
  final int finalizedQuantity;
  final String? finalizedTerms;
  final double? finalizedDeposit;
  final OfferType? offerType;
  final String? pickupCode;
  final DateTime? createdAt;

  Trade({
    this.tradeId,
    required this.offerId,
    required this.borrowerId,
    required this.lenderId,
    this.status = TradeStatus.PENDING,
    this.startDate,
    this.endDate,
    this.finalizedPrice,
    this.finalizedQuantity = 1,
    this.finalizedTerms,
    this.finalizedDeposit,
    this.offerType,
    this.pickupCode,
    this.createdAt,
  });

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      tradeId: map['trade_id'],
      offerId: map['offer_id'],
      borrowerId: map['borrower_id'],
      lenderId: map['lender_id'],
      finalizedPrice: (map['finalized_price'] as num?)?.toDouble(),
      finalizedQuantity: map['finalized_quantity'] ?? 1,
      finalizedTerms: map['finalized_terms'],
      finalizedDeposit: (map['finalized_deposit'] as num?)?.toDouble(),
      offerType: map['offer_type'] != null ? OfferType.values.byName(map['offer_type']) : null,
      status: TradeStatus.values.firstWhere(
              (e) => e.name == map['status'],
          orElse: () => TradeStatus.PENDING
      ),
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      pickupCode: map['pickup_code'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'offer_id': offerId,
    'borrower_id': borrowerId,
    'lender_id': lenderId,
    'status': status.name,
    'finalized_price': finalizedPrice,
    'finalized_quantity': finalizedQuantity,
    'finalized_terms': finalizedTerms,
    'finalized_deposit': finalizedDeposit,
    'offer_type': offerType?.name,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
  };
}
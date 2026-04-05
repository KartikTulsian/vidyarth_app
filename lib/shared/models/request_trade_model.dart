import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';

class RequestTrade {
  final String? tradeId;
  final String requestId;
  final String lenderId;
  final String borrowerId;
  final double finalizedPrice;
  final int finalizedQuantity;
  final String? finalizedTerms;
  final double finalizedDeposit;
  final DateTime? startDate;
  final DateTime? endDate;
  final double platformFee;
  final TradeStatus status;
  final String? pickupCode;
  final String? ownerPaymentDetails;
  final RequestModel? requestDetails;

  RequestTrade({
    this.tradeId,
    required this.requestId,
    required this.lenderId,
    required this.borrowerId,
    required this.finalizedPrice,
    required this.finalizedQuantity,
    this.finalizedTerms,
    this.finalizedDeposit = 0.0,
    this.startDate,
    this.endDate,
    this.platformFee = 0.0,
    this.status = TradeStatus.PENDING,
    this.pickupCode,
    this.ownerPaymentDetails,
    this.requestDetails,
  });

  factory RequestTrade.fromMap(Map<String, dynamic> map) => RequestTrade(
    tradeId: map['trade_id'],
    requestId: map['request_id'],
    lenderId: map['lender_id'],
    borrowerId: map['borrower_id'],
    finalizedPrice: (map['finalized_price'] as num?)?.toDouble() ?? 0.0,
    finalizedQuantity: map['finalized_quantity'] ?? 1,
    finalizedTerms: map['finalized_terms'],
    finalizedDeposit: (map['finalized_deposit'] as num?)?.toDouble() ?? 0.0,
    startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
    endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
    platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0.0,
    status: TradeStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => TradeStatus.PENDING),
    pickupCode: map['pickup_code'],
    ownerPaymentDetails: map['owner_payment_details'],
  );

  Map<String, dynamic> toMap() => {
    'request_id': requestId,
    'lender_id': lenderId,
    'borrower_id': borrowerId,
    'finalized_price': finalizedPrice,
    'finalized_quantity': finalizedQuantity,
    'finalized_terms': finalizedTerms,
    'finalized_deposit': finalizedDeposit,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'platform_fee': platformFee,
    'status': status.name,
    'owner_payment_details': ownerPaymentDetails,
  };
}
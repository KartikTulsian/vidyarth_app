import 'package:flutter/material.dart';
// import 'package:vidyarth_app/core/services/payment_service.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';

class ContractReviewCard extends StatelessWidget {
  final Trade trade;
  final bool isMe; // Was this sent by the current user?
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const ContractReviewCard({
    super.key,
    required this.trade,
    required this.isMe,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = trade.status == TradeStatus.PENDING;
    final Color accentColor = _getOfferColor(trade.offerType);

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header with Status Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    const Text("TRADE CONTRACT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
                _buildStatusChip(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDataRow("Price", trade.finalizedPrice == 0 ? "FREE" : "₹${trade.finalizedPrice}"),
                _buildDataRow("Quantity", "${trade.finalizedQuantity} Unit(s)"),
                if (trade.startDate != null)
                  _buildDataRow("Duration", "${trade.startDate?.day}/${trade.startDate?.month} to ${trade.endDate?.day}/${trade.endDate?.month}"),
                if (trade.finalizedDeposit != null && trade.finalizedDeposit! > 0)
                  _buildDataRow("Security Deposit", "₹${trade.finalizedDeposit}"),

                if (trade.ownerPaymentDetails != null && !isMe) ...[
                  const Divider(),
                  const Text("PAY DIRECTLY TO OWNER VIA UPI",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  SelectableText(
                    trade.ownerPaymentDetails!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],

                const Divider(height: 30),
                Text(
                  trade.finalizedTerms ?? "Standard terms apply",
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Action Buttons for Borrower
          if (!isMe && isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text("DECLINE"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("ACCEPT & PAY"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: trade.status == TradeStatus.PENDING ? Colors.orange : Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(trade.status.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getOfferColor(OfferType? type) {
    if (type == OfferType.SELL) return Colors.green;
    if (type == OfferType.RENT) return Colors.orange;
    return Colors.blue;
  }
}
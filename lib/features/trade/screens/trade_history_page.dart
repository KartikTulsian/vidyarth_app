import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';

class TradeHistoryPage extends StatefulWidget {
  const TradeHistoryPage({super.key});

  @override
  State<TradeHistoryPage> createState() => _TradeHistoryPageState();
}

class _TradeHistoryPageState extends State<TradeHistoryPage> {
  final _service = SupabaseService();
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _service.client.auth.currentUser!.id;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Trade History & Transactions"),
            bottom: const TabBar(
              tabs: [Tab(text: "Borrowed"), Tab(text: "Lent")],
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
            ),
          ),
          body: FutureBuilder<List<Trade>>(
              future: _service.getFullTradeHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No trades history found"));
                }

                final borrowed = snapshot.data!.where((t) => t.borrowerId == currentUserId).toList();
                final lent = snapshot.data!.where((t) => t.lenderId == currentUserId).toList();

                return TabBarView(
                  children: [
                    _buildTradeList(borrowed, isLending: false),
                    _buildTradeList(lent, isLending: true),
                  ],
                );
              }
          ),
        )
    );
  }

  Widget _buildTradeList(List<Trade> trades, {required bool isLending}) {
    if (trades.isEmpty) return const Center(child: Text("No records here yet."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        final bool isOwner = trade.lenderId == currentUserId;

        return GestureDetector(
          // Allow Owner (Lender) to reject PENDING trades via long press
          onLongPress: (isOwner && trade.status == TradeStatus.PENDING)
              ? () => _handleRejectTrade(trade.tradeId!)
              : null,
          child: _buildTradeHistoryCard(trade, isLending),
        );
      },
    );
  }

  void _handleRejectTrade(String tradeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Proposal?"),
        content: const Text("This will decline the trade contract and remove it from active status."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.client.from('trades').update({'status': 'REJECTED'}).eq('trade_id', tradeId);
              setState(() {}); // Crucial for refreshing the view
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistoryCard(Trade trade, bool isLending) {
    final String itemTitle = trade.offerDetails?.stuff?.title ?? "Unknown Item";
    final double totalPrice = (trade.finalizedPrice ?? 0) + (trade.finalizedDeposit ?? 0);
    final Color statusColor = _getStatusColor(trade.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(trade.status), color: _getStatusColor(trade.status), size: 20),
        ),
        title: Text(itemTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Date: ${DateFormat('dd MMM yyyy').format(trade.createdAt ?? DateTime.now())}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          "₹${trade.finalizedPrice}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Transaction Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                _buildPriceRow("Finalized Price", "₹${trade.finalizedPrice}"),
                if (trade.finalizedDeposit != null && trade.finalizedDeposit! > 0)
                  _buildPriceRow("Security Deposit (Refundable)", "₹${trade.finalizedDeposit}"),
                const Divider(),
                _buildPriceRow("Total Paid to Owner", "₹$totalPrice", isBold: true),

                if (isLending && trade.platformFee != null && trade.platformFee! > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                    child: _buildPriceRow(
                        "Platform Fee (10% Dues)",
                        "- ₹${trade.platformFee?.toStringAsFixed(2)}",
                        color: Colors.orange.shade900
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoBadge("Type: ${trade.offerType?.name}"),
                    _buildInfoBadge("Status: ${trade.status.name}"),
                  ],
                ),
                if (trade.ownerPaymentDetails != null) ...[
                  const SizedBox(height: 12),
                  Text("Payment sent to: ${trade.ownerPaymentDetails}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey.shade700)),
          Text(value, style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? Colors.black : Colors.black87)
          )),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.ACCEPTED: return Colors.green;
      case TradeStatus.CANCELLED:
      case TradeStatus.REJECTED: return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(TradeStatus status) {
    switch (status) {
      case TradeStatus.ACCEPTED: return Icons.check_circle;
      case TradeStatus.COMPLETED: return Icons.assignment_turned_in;
      default: return Icons.pending;
    }
  }
}

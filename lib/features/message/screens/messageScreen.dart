import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/features/requests/screens/requests_message_section.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';

class Messagescreen extends StatefulWidget {
  final VoidCallback onLogout;
  const Messagescreen({super.key, required this.onLogout});

  @override
  State<Messagescreen> createState() => _MessagescreenState();
}

class _MessagescreenState extends State<Messagescreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  Future<int> _getUnreadCount(String otherId, String? offerId) async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('messages')
          .select('message_id')
          .eq('receiver_id', currentUserId)
          .eq('sender_id', otherId)
          .eq('offer_id', offerId ?? '')
          .eq('is_read', false);
      return (res as List).length;
    } catch (e) {
      debugPrint("DEBUG ERROR: _getUnreadCount failed: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Business Center",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: "Inquiries"),
            Tab(text: "Requests",),
            Tab(text: "Ongoing"),
            Tab(text: "Completed"),
            Tab(text: "History & Fees"),
          ],
        ),
      ),
      body: TabBarView(
          controller: _tabController,
          children: [
            _buildInquiriesTab(currentUserId),
            RequestsMessageSection(currentUserId: currentUserId),
            _buildTradesByStatus(currentUserId, [TradeStatus.ACCEPTED]),
            _buildTradesByStatus(currentUserId, [TradeStatus.COMPLETED]),
            _buildHistoryAndFeesTab(currentUserId),
          ]
      ),
    );
  }

  Widget _buildInquiriesTab(String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('messages').stream(primaryKey: ['message_id']),
      builder: (context, snapshot) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase.from('chat_inbox_view').select(),
          builder: (context, viewSnapShot) {
            if (viewSnapShot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!viewSnapShot.hasData || viewSnapShot.data!.isEmpty) {
              debugPrint("DEBUG ERROR: Inquiries Tab fetch failed: ${viewSnapShot.error}");
              return _buildEmptyState(Icons.error_outline, "Error loading inquiries");
            }

            final chats = viewSnapShot.data!.where((m) =>
                      m['sender_id'] == currentUserId ||
                      m['receiver_id'] == currentUserId,
                ).toList();

            if (chats.isEmpty) return _buildEmptyState(Icons.message_outlined, "No inquiries yet");

            debugPrint("DEBUG: Loaded ${chats.length} inquiries");

            chats.sort((a, b) {
              final dateA = DateTime.parse(
                a['sent_at'] ?? DateTime.now().toIso8601String(),
              );
              final dateB = DateTime.parse(
                b['sent_at'] ?? DateTime.now().toIso8601String(),
              );
              return dateB.compareTo(dateA);
            });

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherId = (chat['sender_id'] == currentUserId)
                    ? chat['receiver_id']
                    : chat['sender_id'];

                // 3. Use FutureBuilder for individual unread counts
                return FutureBuilder<int>(
                  future: _getUnreadCount(otherId, chat['offer_id']),
                  builder: (context, unreadSnapshot) {
                    final unreadCount = unreadSnapshot.data ?? 0;
                    return _buildChatCard(chat, otherId, unreadCount);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatCard(
    Map<String, dynamic> chat,
    String otherId,
    int unreadCount,
  ) {
    final bool hasUnread = unreadCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            chat['offer_type'] == 'RENT'
                ? Icons.timer_outlined
                : Icons.inventory_2_outlined,
            color: AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          chat['stuff_title'] ?? "General Inquiry",
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            chat['last_message'] ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? Colors.black87 : Colors.grey[600],
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasUnread)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChatPage(
              receiverId: otherId,
              receiverName: chat['stuff_title'] ?? "Discussion",
              offerId: chat['offer_id'],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradesByStatus(String userId, List<TradeStatus> statuses) {
    return FutureBuilder<List<Trade>>(
        future: _supabase
            .from('trades')
            .select('*, offers(*, stuff(*, stuff_images(url)))')
            .or('borrower_id.eq.$userId, lender_id.eq.$userId')
            .then((data) => (data as List).map((m) => Trade.fromMap(m)).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (snapshot.hasError) {
            debugPrint("DEBUG ERROR: _buildTradesByStatus fetch failed: ${snapshot.error}");
            return _buildEmptyState(Icons.error_outline, "Could not load trades");
          }
          
          final filtered = snapshot.data?.where((t) =>
              statuses.contains(t.status) && (t.borrowerId == userId || t.lenderId == userId)
          ).toList() ?? [];

          if (filtered.isEmpty) {
            String msg = statuses.contains(TradeStatus.COMPLETED) ? "No completed trades" : "No ongoing trades";
            return _buildEmptyState(Icons.handshake_outlined, msg);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _buildOngoingTradeCard(filtered[i], userId),
          );
        }
    );
  }

  Widget _buildHistoryAndFeesTab(String userId) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFinancialSummary(), // Reusing logic from StudentHome
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text("Full Transaction History", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          FutureBuilder<List<Trade>>(
            future: _service.getFullTradeHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              if (snapshot.hasError) {
                debugPrint("DEBUG ERROR: History list fetch failed: ${snapshot.error}");
                return _buildEmptyState(Icons.error_outline, "Error loading history");
              }

              final history = snapshot.data?.where((t) =>
              (t.lenderId == userId || t.borrowerId == userId)
              ).toList() ?? [];

              if (history.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No history records."));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (ctx, i) {
                  final trade = history[i];
                  final bool isOwner = trade.lenderId == userId;

                  return GestureDetector(
                    // Long press to reject PENDING trades (Owner only)
                    onLongPress: (isOwner && trade.status == TradeStatus.PENDING)
                        ? () => _showRejectDialog(trade.tradeId!)
                        : null,
                    child: _buildTradeHistoryCard(trade, isOwner),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String tradeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Contract?"),
        content: const Text("Are you sure you want to reject this pending contract?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _supabase.from('trades').update({'status': 'REJECTED'}).eq('trade_id', tradeId);
              setState(() {});
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return FutureBuilder<double>(
      future: _service.getOutstandingPlatformFees(),
      builder: (context, snapshot) {
        final dues = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Platform Dues Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₹${dues.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18)),
                ],
              ),
              const Divider(),
              const Text("10% Fee on Sales/Rentals collected during renewal.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOngoingTradeCard(Trade trade, String userId) {
    final bool isLender = trade.lenderId == userId;
    final String itemTitle = trade.offerDetails?.stuff?.title ?? "Item";
    final bool isActive = trade.status == TradeStatus.ACCEPTED;

    // Calculate total for the breakdown
    final double totalPrice = (trade.finalizedPrice ?? 0) + (trade.finalizedDeposit ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        // The header of the card
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
          child: Icon(trade.offerType == OfferType.RENT ? Icons.timer : Icons.sync, color: Colors.blue),
        ),
        title: Text(itemTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          isLender ? "Status: Lending" : "Status: Borrowing",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PICKUP CODE", style: TextStyle(fontSize: 8, color: Colors.grey)),
            Text(trade.pickupCode ?? "----", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),

        // The Expanded Section (Trade Details)
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text("Contract Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildPriceRow("Price", "₹${trade.finalizedPrice}"),
                _buildPriceRow("Quantity", "${trade.finalizedQuantity} Unit(s)"),
                if (trade.finalizedDeposit != null && trade.finalizedDeposit! > 0)
                  _buildPriceRow("Security Deposit", "₹${trade.finalizedDeposit}"),
                const Divider(),
                _buildPriceRow("Total Value", "₹$totalPrice", isBold: true),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // NEW NAVIGATION BUTTON: Passes both Stuff and Offer
                    TextButton.icon(
                      onPressed: () async {
                        if (trade.offerId == null) return;

                        // 1. Show a loading indicator (matching ChatPage behavior)
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          // 2. Fetch the full Offer with nested stuff and images (just like ChatPage)
                          final Offer? fullOffer = await _service.getOfferById(trade.offerId!);

                          if (!mounted) return;
                          Navigator.pop(context); // Close loading dialog

                          // 3. Navigate only if data is valid
                          if (fullOffer != null && fullOffer.stuff != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailPage(item: fullOffer.stuff!),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Product details are no longer available")),
                            );
                          }
                        } catch (e) {
                          if (mounted) Navigator.pop(context);
                          debugPrint("Navigation Error in Business Center: $e");
                        }
                      },
                      icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      label: const Text("View Product"),
                    ),

                    if (isActive)
                      ElevatedButton.icon(
                        onPressed: () => _confirmCompleteTrade(trade.tradeId!, itemTitle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("COMPLETE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    else
                      Text(
                        "Completed on ${DateFormat('dd MMM').format(trade.endDate ?? DateTime.now())}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCompleteTrade(String tradeId, String title) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Finilize Trade?"),
            content: Text(
              "Are you sure you want to mark '$title' as completed? This will move it to your history.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _service.completeTrade(tradeId);
                    setState(() {}); // Refresh tabs
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Trade marked as Completed!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Yes, Complete"),
              ),
            ],
          ),
    );
  }

  Widget _buildTradeHistoryCard(Trade trade, bool isLending) {
    final String itemTitle = trade.offerDetails?.stuff?.title ?? "Unknown Item";
    final double totalPrice = (trade.finalizedPrice ?? 0) + (trade.finalizedDeposit ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(trade.status).withOpacity(0.1),
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

  Widget _buildEmptyState(IconData icon, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.message_outlined, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Relevant items and history will appear here.",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
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

  Widget _buildStatusChip(TradeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10),
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
      case TradeStatus.COMPLETED: return Colors.blue;
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

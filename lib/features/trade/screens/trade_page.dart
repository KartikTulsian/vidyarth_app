import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:vidyarth_app/core/constants/api_keys.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/profile/screens/subscription_page.dart';
import 'package:vidyarth_app/features/trade/widgets/add_item_sheet.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/features/trade/screens/trade_history_page.dart';
import 'package:vidyarth_app/main.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TradePage extends StatefulWidget {
  final VoidCallback onLogout;
  const TradePage({super.key, required this.onLogout});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentUserId = _supabaseService.client.auth.currentUser!.id;
  }

  void _openAddItemForm() async {
    showDialog(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final bool allowed = await _supabaseService.canUserAddItem();

    if (!mounted) return;
    Navigator.pop(context);

    if (allowed) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddItemSheet(onItemAdded: () => setState(() {})),
      );
    } else {
      // Show a professional "Upgrade" dialog
      _showUpgradeRequiredDialog();
    }
  }

  void _showUpgradeRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Limit Reached"),
        content: const Text(
          "You have reached the maximum items allowed on your current plan. Upgrade to list more!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscription();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("View Plans"),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscription() async {
    // Show a brief loading indicator while we get user details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final UserModel? userModel = await _supabaseService.getUnifiedProfile();

    if (!mounted) return;
    Navigator.pop(context); // Close the loader

    if (userModel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPage(
            role: userModel.role.name,
            currentTier: userModel.subTier.name,
          ),
        ),
      ).then((_) {
        // Refresh the page state when coming back from upgrade
        setState(() {});
      });
    }
  }

  void scheduleTradeReminder(Trade trade) async {
    if (trade.endDate == null) return;

    tz.initializeTimeZones();

    final reminderTime = tz.TZDateTime.from(
      trade.endDate!.subtract(const Duration(hours: 24)),
      tz.local,
    );

    if (reminderTime.isBefore(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          ApiKeys.tradeReminderChannelId,
          ApiKeys.tradeReminderChannelName,
          importance: Importance.max,
          priority: Priority.high,
        );

    // Use zonedSchedule instead of schedule
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: trade.tradeId.hashCode, // id
      title: 'Trade Due Tomorrow!', // title
      body:
          'Your trade for ${trade.offerDetails?.stuff?.title} is due in 24 hours.', // body
      scheduledDate: reminderTime, // scheduledDate
      notificationDetails: NotificationDetails(
        android: androidDetails,
      ), // notificationDetails
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Trade & Exchange",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: "My Listings"),
            Tab(text: "Ongoing Trades"),
            Tab(text: "Completed"),
            Tab(text: "Trade History"),
            Tab(text: "My Requests"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {}); // Triggers the FutureBuilder to re-run
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyListingsTab(),
          _buildActiveTradesTab([TradeStatus.ACCEPTED]),
          _buildActiveTradesTab([TradeStatus.COMPLETED]),
          const TradeHistoryPage(),
          _buildMyRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItemForm,
        heroTag: 'trade_fab',
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("List Item", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    return FutureBuilder<Map<String, int>>(
      future: _supabaseService.getUserListingStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final int count = snapshot.data!['count']!;
        final int limit = snapshot.data!['limit']!;
        final double progress = limit == 9999 ? 0.0 : count / limit;
        final bool isFull = limit != 9999 && count >= limit;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFull
                  ? [Colors.red[400]!, Colors.red[700]!]
                  : [Colors.black, Colors.grey[800]!],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    limit == 9999
                        ? "Unlimited Listings Active"
                        : "Listing Limit: $count / $limit Used",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (!isFull && limit != 9999)
                    GestureDetector(
                      onTap: _navigateToSubscription,
                      child: const Text(
                        "Upgrade ▶",
                        style: TextStyle(
                          color: Color(0xFF44FFD3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (limit != 9999) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: isFull
                        ? Colors.orangeAccent
                        : const Color(0xFF44FFD3),
                    minHeight: 8,
                  ),
                ),
              ],
              if (isFull)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Limit reached! Upgrade to Student Pro to list more.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Update the _buildMyListingsTab method
  Widget _buildMyListingsTab() {
    return Column(
      children: [
        _buildSubscriptionBanner(), // The new banner appears at the top
        Expanded(
          child: FutureBuilder<List<Stuff>>(
            future: _supabaseService.getUserItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  "No items listed yet.",
                  "Start contributing by clicking the button below.",
                );
              }

              final List<Stuff> items = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildEnhancedListCard(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTradesTab(List<TradeStatus> statuses) {
    return FutureBuilder<List<Trade>>(
      future: _supabaseService.getFullTradeHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trades = snapshot.data?.where((t) =>
        statuses.contains(t.status) && (t.borrowerId == _currentUserId || t.lenderId == _currentUserId)
        ).toList() ?? [];

        if (trades.isEmpty) return _buildEmptyState("No trades found", "Matches will appear here.");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trades.length,
          itemBuilder: (context, index) => _buildOngoingTradeCard(trades[index]),
        );
      },
    );
  }

  Widget _buildOngoingTradeCard(Trade trade) {
    final bool isLender = trade.lenderId == _currentUserId;
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
                          final Offer? fullOffer = await _supabaseService.getOfferById(trade.offerId!);

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
      builder: (ctx) => AlertDialog(
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
                await _supabaseService.completeTrade(tradeId);
                setState(() {}); // Refresh tabs
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trade marked as Completed!")),
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEnhancedListCard(Stuff item) {
    final String? imageUrl = item.imageUrls.firstOrNull;
    final Offer? offer = item.offers.firstOrNull;

    String offerTypeText = "No Offer";
    String priceDetail = "";
    Color offerColor = Colors.grey;

    if (offer != null) {
      offerTypeText = offer.offerType.name.toUpperCase();
      offerColor = Colors.green;

      switch (offer.offerType.name) {
        case 'SELL':
          priceDetail = "₹${offer.price ?? 0}";
          break;
        case 'RENT':
          String unit = offer.rentalUnit.name.toLowerCase();
          priceDetail = "₹${offer.rentalPrice ?? 0}/$unit";
          break;
        case 'EXCHANGE':
          priceDetail = "Value: ₹${offer.exchangeItemValue ?? 'N/A'}";
          offerColor = Colors.blue;
          break;
        default:
          priceDetail = "Negotiable";
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailPage(item: item)),
        ).then((_) => setState(() {})),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 85,
                        height: 85,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildStatusBadge(
                          item.isAvailable ? "Available" : "Traded",
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.type.name} • ${item.condition.name}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: offerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offerTypeText,
                            style: TextStyle(
                              color: offerColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          priceDetail,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isAvailable = status == "Available";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.orange,
          width: 0.5,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isAvailable ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return FutureBuilder<List<RequestModel>>(
      future: _supabaseService.getUserRequests(), // Create this in service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ADD EMPTY STATE LOGIC HERE:
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              "No Requests Found",
              "Post an urgent need from the Home screen to see it here."
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _buildRequestCard(requests[i]),
        );
      },
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

  Widget _buildRequestCard(RequestModel request) {
    final bool isOpen = request.status == RequestStatus.OPEN;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUrgencyBadge(request.urgencyLevel),
                _buildStatusBadge(request.status.name),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.stuffType.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              request.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Posted: ${DateFormat('dd MMM').format(request.createdAt ?? DateTime.now())}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isOpen)
                  TextButton.icon(
                    onPressed: () async {
                      // Logic to delete or close the request
                      await _supabaseService.client
                          .from('requests')
                          .update({'status': 'CLOSED'})
                          .eq('request_id', request.id);
                      setState(() {});
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.orange),
                    label: const Text("Mark Resolved", style: TextStyle(color: Colors.orange)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(UrgentLevel level) {
    Color color;
    switch (level) {
      case UrgentLevel.HIGH: color = Colors.red; break;
      case UrgentLevel.MEDIUM: color = Colors.orange; break;
      case UrgentLevel.LOW: color = Colors.blue; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "${level.name} URGENCY",
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

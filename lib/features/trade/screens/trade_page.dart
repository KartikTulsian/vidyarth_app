import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/profile/screens/subscription_page.dart';
import 'package:vidyarth_app/features/trade/screens/add_item_sheet.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class TradePage extends StatefulWidget {
  final VoidCallback onLogout;
  const TradePage({super.key, required this.onLogout});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          tabs: const [
            Tab(text: "My Listings"),
            Tab(text: "Ongoing Trades"),
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
        children: [_buildMyListingsTab(), _buildActiveTradesTab()],
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

  Widget _buildActiveTradesTab() {
    return _buildEmptyState(
      "No active trades yet.",
      "Start contributing by clicking the button below",
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
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
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
}

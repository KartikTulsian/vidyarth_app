import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/inventory/widgets/dealer_add_item_sheet.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/features/trade/screens/add_item_sheet.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';

class ItemDetailPage extends StatefulWidget {
  final Stuff item;
  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final _currentUser = Supabase.instance.client.auth.currentUser;
  final SupabaseService _supabaseService = SupabaseService();
  int _currentImageIndex = 0;

  void _deleteItem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text(
          "Are you sure you want to delete this listing? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteStuff(widget.item.id);
        if (context.mounted) {
          Navigator.pop(context); // Go back to list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item deleted successfully")),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _openFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
          body: PageView.builder(
            itemCount: widget.item.imageUrls.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) => InteractiveViewer( // Allows pinching
              child: Center(child: CachedNetworkImage(imageUrl: widget.item.imageUrls[index])),
            ),
          ),
        ),
      ),
    );
  }

  void _editItem(BuildContext context) async {

    final userModel = await _supabaseService.getUnifiedProfile();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (userModel?.role == UserRole.DEALER) {
          return DealerAddItemSheet(
            itemToEdit: widget.item,
            onItemAdded: () => Navigator.pop(context),
          );
        } else {
          return AddItemSheet(
            itemToEdit: widget.item,
            onItemAdded: () => Navigator.pop(context),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _currentUser?.id == widget.item.ownerId;
    final Offer? offer = widget.item.offers.firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: _buildAppBar(isOwner),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. Image Carousel Block
                _buildWhiteSection(_buildImageCarousel()),

                // 2. Main Details Block
                _buildWhiteSection(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntentBadge(offer?.offerType),
                    const SizedBox(height: 8),
                    _buildMainHeader(),
                    const SizedBox(height: 12),
                    if (offer != null) _buildSmartPriceSection(offer),
                  ],
                )),

                const SizedBox(height: 8),

                // 3. Product Highlights Block
                _buildWhiteSection(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Product Highlights"),
                    const SizedBox(height: 12),
                    _buildHighlightsGrid(),
                  ],
                )),

                const SizedBox(height: 8),

                // 4. Description Block
                _buildWhiteSection(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Description"),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description ?? "No description provided.",
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                  ],
                )),

                const SizedBox(height: 8),

                // 5. Pickup & Logistics Block
                if (offer != null) _buildWhiteSection(_buildLocationAndTerms(offer)),

                const SizedBox(height: 120), // Padding for sticky bottom
              ],
            ),
          ),
          if (!isOwner) _buildStickyBottom(context, offer),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isOwner) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: const BackButton(color: Colors.black87),
      title: const Text("Product Details", style: TextStyle(color: Colors.black87, fontSize: 16)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: Colors.black87)),
        if (isOwner) ...[
          IconButton(onPressed: () => _editItem(context), icon: const Icon(Icons.edit, color: Colors.blue)),
          IconButton(onPressed: () => _deleteItem(context), icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWhiteSection(Widget child) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildOfferTypeBadge(OfferType? type) {
    Color color = Colors.blue;
    String label = "LISTING";

    switch (type) {
      case OfferType.SELL: color = Colors.green; label = "FOR SALE"; break;
      case OfferType.RENT: color = Colors.orange; label = "FOR RENT"; break;
      case OfferType.EXCHANGE: color = Colors.purple; label = "EXCHANGE"; break;
      case OfferType.LEND: color = Colors.teal; label = "FREE LEND"; break;
      case OfferType.SHARE: color = Colors.indigo; label = "COMMUNITY SHARE"; break;
      default: break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildIntentBadge(OfferType? type) {
    Color color = Colors.blue;
    String text = "COMMUNITY ITEM";
    IconData icon = Icons.people_outline;

    switch (type) {
      case OfferType.SELL: color = Colors.green; text = "AVAILABLE TO BUY"; icon = Icons.shopping_bag_outlined; break;
      case OfferType.RENT: color = Colors.orange; text = "AVAILABLE FOR RENT"; icon = Icons.timer_outlined; break;
      case OfferType.EXCHANGE: color = Colors.purple; text = "EXCHANGE ONLY"; icon = Icons.swap_horiz; break;
      case OfferType.LEND: color = Colors.teal; text = "FREE TO LEND"; icon = Icons.handshake_outlined; break;
      case OfferType.SHARE: color = Colors.indigo; text = "COMMUNITY SHARE"; icon = Icons.groups_outlined; break;
      default: break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  // --- SMART PRICE (CLEARS LEND/SHARE CONFUSION) ---
  Widget _buildSmartPriceSection(Offer offer) {
    bool isFree = offer.offerType == OfferType.LEND || offer.offerType == OfferType.SHARE;
    double originalPrice = widget.item.originalPrice ?? 0;
    double currentPrice = offer.price ?? offer.rentalPrice ?? 0;

    if (isFree) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Text("₹0", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(width: 12),
            Text("FREE COMMUNITY LISTING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("₹${currentPrice.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
            if (originalPrice > currentPrice) ...[
              const SizedBox(width: 10),
              Text("₹${originalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 16, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 10),
              Text("${(((originalPrice - currentPrice) / originalPrice) * 100).round()}% off",
                  style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        if (offer.offerType == OfferType.RENT)
          Text("per ${offer.rentalUnit.name.toLowerCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildHighlightsGrid() {
    final specs = [
      {'label': 'Condition', 'value': widget.item.condition.name, 'icon': Icons.verified_outlined},
      if (widget.item.brand?.isNotEmpty == true) {'label': 'Brand', 'value': widget.item.brand!, 'icon': Icons.branding_watermark_outlined},
      if (widget.item.model?.isNotEmpty == true) {'label': 'Model', 'value': widget.item.model!, 'icon': Icons.settings_suggest_outlined},
      if (widget.item.language?.isNotEmpty == true) {'label': 'Language', 'value': widget.item.language!, 'icon': Icons.translate},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 50,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) => Row(
        children: [
          Icon(specs[index]['icon'] as IconData, size: 22, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(specs[index]['label'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(specs[index]['value'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottom(BuildContext context, Offer? offer) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, color: Colors.black87),
                        Text("QUESTIONS?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Material(
                  color: const Color(0xFFFFD814), // Flipkart Yellow
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(
                      receiverId: widget.item.ownerId,
                      receiverName: widget.item.title,
                      offerId: offer?.id,
                    ))),
                    child: Center(
                      child: Text(
                        offer?.offerType == OfferType.RENT ? "RENT NOW" : "CHAT TO BUY",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: widget.item.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openFullScreenImage(context, index),
              child: CachedNetworkImage(
                imageUrl: widget.item.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(color: Colors.grey[100]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.item.imageUrls.length,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index ? Colors.blue : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMainHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.brand ?? "Vidyarth",
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          widget.item.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
              child: const Row(
                children: [
                  Text("4.3 ", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.star, color: Colors.white, size: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text("5K+ ratings", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAndTerms(Offer offer) {
    final fullAddress = [
      offer.pickupAddress,
      offer.city,
      offer.state,
      offer.pincode
    ].where((part) => part != null && part.isNotEmpty).join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Pickup & Terms"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.1))
          ),
          child: Column(
            children: [
              _buildInfoRow(
                  Icons.location_on,
                  "Pickup Address",
                  fullAddress.isNotEmpty ? fullAddress : "Contact seller for location"
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.description_outlined, "Terms", offer.termsConditions ?? "Standard marketplace terms apply."),
              if (offer.specialInstructions?.isNotEmpty == true) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.info_outline, "Instructions", offer.specialInstructions!),
              ]
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ])),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';

class ShopPage extends StatefulWidget {
  final String dealerId;
  final String shopName;

  const ShopPage({super.key, required this.dealerId, required this.shopName});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _serchQuery = "";
  final _service = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search in this shop...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _serchQuery = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Stuff>>(
              future: _service.getShopItems(widget.dealerId, _serchQuery),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(child: Text("No items found in this shop."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final Stuff item = items[index];
                    final String? imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls[0] : null;
                    final Offer? offer = item.offers.isNotEmpty ? item.offers[0] : null;

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(item: item))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: imageUrl != null
                                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                                  : Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    offer != null ? "₹${offer.price ?? offer.rentalPrice ?? 0}" : "Price on Request",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    item.condition.name,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                );
              },
            )
          )
        ],
      ),
    );
  }
}

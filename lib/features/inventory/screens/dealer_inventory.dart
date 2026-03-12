import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/inventory/widgets/dealer_add_item_sheet.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';

class DealerInventory extends StatefulWidget {
  final VoidCallback onLogout;

  const DealerInventory({super.key, required this.onLogout});

  @override
  State<DealerInventory> createState() => _DealerInventoryState();
}

class _DealerInventoryState extends State<DealerInventory> {
  final _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  void _openAddStockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DealerAddItemSheet(onItemAdded: () => setState(() {})),
    );
  }

  void _openEditSheet(Stuff item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DealerAddItemSheet(
        itemToEdit: item, // FIX: Pass 'item' directly as a Stuff object
        onItemAdded: () => setState(() {}),
      ),
    );
  }

  void _showNotificationMenu(
    BuildContext context,
    List<Map<String, dynamic>> unreadMessages,
  ) {
    if (unreadMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No new notifications"))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Messages",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              itemCount: unreadMessages.length > 5 ? 5 : unreadMessages.length,
              itemBuilder: (context, index) {
                final msg = unreadMessages[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                  title: const Text("New message received"),
                  subtitle: Text(
                    msg['text'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx); // Close sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverId: msg['sender_id'],
                          receiverName:
                              "User", // You can fetch item title here if needed
                          offerId: msg['offer_id'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('messages')
          .stream(primaryKey: ['message_id'])
          .order('sent_at'),
      builder: (context, snapshot) {
        final unreadMessages =
            snapshot.data
                ?.where(
                  (m) =>
                      m['receiver_id'] == currentUserId &&
                      m['is_read'] == false,
                )
                .toList() ??
            [];

        int unreadCount = unreadMessages.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () => _showNotificationMenu(context, unreadMessages),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Stock Management",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          _buildNotificationButton(context, currentUserId),
        ],
      ),
      body: FutureBuilder<List<Stuff>>(
        future: _supabaseService.getDealerInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No stock listed."));
          }

          final inventory = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final Stuff item = inventory[index];
              final String imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls[0] : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                        ? Container(
                      width: 60, height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                        : Image.network(
                      imageUrl,
                      width: 60, height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60, height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Stock: ${item.stockQuantity} Units"),
                  trailing: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox( // Prevent text overflow
                          child: Text(
                            "Manage",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                        // const SizedBox(height: 4),
                        // GestureDetector(
                        //   onTap: () => _openEditSheet(item), // Logic for editing
                        //   child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        // ),
                      ],
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dealer_inventory_fab',
        onPressed: _openAddStockSheet,
        backgroundColor: Colors.black,
        label: const Text("Add Stock", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';

class Messagescreen extends StatefulWidget {
  final VoidCallback onLogout;
  const Messagescreen({super.key, required this.onLogout});

  @override
  State<Messagescreen> createState() => _MessagescreenState();
}

class _MessagescreenState extends State<Messagescreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Customer Inquiries",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('messages').stream(primaryKey: ['message_id']),
          builder: (context, snapshot) {
            return FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabase.from('chat_inbox_view').select(),
                builder: (context, viewSnapShot) {
                  if (viewSnapShot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!viewSnapShot.hasData || viewSnapShot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final chats = viewSnapShot.data!.where((m) =>
                      m['sender_id'] == currentUserId || m['receiver_id'] == currentUserId
                  ).toList();

                  if (chats.isEmpty) return _buildEmptyState();

                  return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemCount: chats.length,
                    itemBuilder: (context, index) {
                        final chat = chats[index];
                        final otherId = (chat['sender_id'] == currentUserId) ? chat['receiver_id'] : chat['sender_id'];

                        final bool isUnread = chat['is_read'] == false && chat['receiver_id'] == currentUserId;

                        return _buildChatCard(chat, otherId, isUnread);
                    }
                  );
                }
            );
          }
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, String otherId, bool isUnread) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBlue),
        ),
        title: Text(
          chat['stuff_title'] ?? "General Inquiry",
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
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
              color: isUnread ? Colors.black87 : Colors.grey[600],
              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isUnread)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No messages yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Customer inquiries for your items will appear here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

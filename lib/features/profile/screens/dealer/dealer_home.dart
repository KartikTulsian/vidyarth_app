import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/features/message/screens/messageScreen.dart';

class DealerHome extends StatelessWidget {
  final VoidCallback onLogout;
  final _supabase = Supabase.instance.client;

  DealerHome({super.key, required this.onLogout});

  void _showNotificationMenu(BuildContext context, List<Map<String, dynamic>> unreadMessages) {
    if (unreadMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No new notifications")),
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
            const Text("New Messages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              itemCount: unreadMessages.length > 5 ? 5 : unreadMessages.length,
              itemBuilder: (context, index) {
                final msg = unreadMessages[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                  title: const Text("New message received"),
                  subtitle: Text(msg['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx); // Close sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverId: msg['sender_id'],
                          receiverName: "User", // You can fetch item title here if needed
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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _supabase.auth.currentUser!.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello, Dealer! 👋",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        "Ready to share & earn?",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  // Notification portion
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('messages')
                        .stream(primaryKey: ['message_id'])
                        .order('sent_at'),
                    builder: (context, snapshot) {
                      final unreadMessages = snapshot.data?.where((m) =>
                      m['receiver_id'] == currentUserId && m['is_read'] == false
                      ).toList() ?? [];

                      int unreadCount = unreadMessages.length;

                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.black87),
                              onPressed: () => _showNotificationMenu(context, unreadMessages),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ]
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Upcoming Return", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("Physics H.C. Verma", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Due: Tomorrow, 5 PM", style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.white70, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("My Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard("Sold", "3", Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Lent", "12", Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Requests", "5", Colors.purple)),
              ],
            ),
          ]
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEnhancedChatList(String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('messages').stream(primaryKey: ['message_id']),
      builder: (context, snapshot) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase.from('chat_inbox_view').select(),
          builder: (context, viewSnapshot) {
            if (!viewSnapshot.hasData || viewSnapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No inquiries yet", style: TextStyle(color: Colors.grey),),
              );
            }

            final chats = viewSnapshot.data!.where((m) =>
                m['sender_id'] == currentUserId || m['receiver_id'] == currentUserId
            ).toList();

            return ListView.builder(
              shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final otherId = (chat['sender_id'] == currentUserId) ? chat['receiver_id'] : chat['sender_id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.orange),
                      ),
                      title: Text(
                          chat['stuff_title'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                      ),
                      subtitle: Text(
                        chat['last_message'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: chat['is_read'] == false && chat['receiver_id'] == currentUserId
                          ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))
                          : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => ChatPage(
                                receiverId: otherId,
                                receiverName: chat['stuff_title'],
                                offerId: chat['offer_id'],
                              )
                          )
                      ),
                    ),

                  );
                }
            );
          }
        );
      },
    );
  }
}

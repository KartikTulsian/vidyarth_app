import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class StudentHome extends StatelessWidget {
  final VoidCallback onLogout;
  final UserModel userData;
  final _supabase = Supabase.instance.client;

  StudentHome({super.key, required this.onLogout, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = userData.id;

    final String displayName = userData.profile?.displayName ??
        userData.profile?.fullName ??
        "Student";

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
                    title: Text(msg['stuff_title'] ?? "Message"),
                    subtitle: Text(msg['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx); // Close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverId: msg['sender_id'],
                            receiverName: msg['stuff_title'] ?? "Discussion",
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
                  Text(
                    "Hello, $displayName 👋",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    "Ready for some trades today?",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              StreamBuilder<List<Map<String, dynamic>>>(

                  stream: _supabase
                      .from('messages')
                      .stream(primaryKey: ['message_id'])
                      .order('sent_at'),
                  builder: (context, snapshot) {
                    // Filter locally for unread messages where current user is the receiver
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
                  }
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
              Expanded(child: _buildStatCard("Borrowed", "3", Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Lent", "12", Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Requests", "5", Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Recent Discussions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('messages').stream(primaryKey: ['message_id']),
            builder: (context, snapshot) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabase.from('chat_inbox_view').select(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // FILTER: Only show discussions where I am a participant
                  final myChats = snapshot.data!.where((chat) =>
                  chat['sender_id'] == currentUserId || chat['receiver_id'] == currentUserId
                  ).toList();

                  if (myChats.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myChats.length,
                    itemBuilder: (context, index) {
                      final chat = myChats[index];
                      final otherId = (chat['sender_id'] == currentUserId) ? chat['receiver_id'] : chat['sender_id'];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Text(chat['stuff_title']?[0] ?? "D",
                                style: const TextStyle(color: AppTheme.primaryBlue)),
                          ),
                          title: Text(
                            chat['stuff_title'] ?? "Discussion",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(chat['last_message'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ChatPage(
                                receiverId: otherId,
                                receiverName: chat['stuff_title'] ?? "Discussion",
                                offerId: chat['offer_id'], // CRITICAL: Item segregation
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
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

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text("No recent discussions", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

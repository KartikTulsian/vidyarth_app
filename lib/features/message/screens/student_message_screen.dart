import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/chat_page.dart';
import 'package:vidyarth_app/features/requests/screens/requests_message_section.dart';

class StudentMessageScreen extends StatefulWidget {
  const StudentMessageScreen({super.key});

  @override
  State<StudentMessageScreen> createState() => _StudentMessageScreenState();
}

class _StudentMessageScreenState extends State<StudentMessageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<int> _getUnreadCount(String otherId, String? offerId) async {
    final res = await _supabase.from('messages')
        .select('message_id')
        .eq('receiver_id', _currentUserId)
        .eq('sender_id', otherId)
        .eq('offer_id', offerId ?? '')
        .eq('is_read', false);
    return (res as List).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Inbox", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: "Trade Chats"),
            Tab(text: "Urgent Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNormalChats(),
          RequestsMessageSection(currentUserId: _currentUserId),
        ],
      ),
    );
  }

  Widget _buildNormalChats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('chat_inbox_view').stream(primaryKey: ['message_id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading chats"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No recent discussions"));

        final myChats = snapshot.data!.where((chat) {
          final List<dynamic> hiddenUsers = chat['hidden_from_users'] ?? [];
          return (chat['sender_id'] == _currentUserId || chat['receiver_id'] == _currentUserId)
              && !hiddenUsers.contains(_currentUserId);
        }).toList();

        myChats.sort((a, b) => DateTime.parse(b['sent_at'] ?? DateTime.now().toIso8601String())
            .compareTo(DateTime.parse(a['sent_at'] ?? DateTime.now().toIso8601String())));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myChats.length,
          itemBuilder: (context, index) {
            final chat = myChats[index];
            final String otherId = chat['sender_id'] == _currentUserId ? chat['receiver_id'] : chat['sender_id'];
            final String title = chat['stuff_title'] ?? "General Discussion";

            return FutureBuilder<int>(
              future: _getUnreadCount(otherId, chat['offer_id']),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(chat['last_message'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: unreadCount > 0
                        ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                        : const Icon(Icons.chevron_right, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ChatPage(receiverId: otherId, receiverName: title, offerId: chat['offer_id']),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
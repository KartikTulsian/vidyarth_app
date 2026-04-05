import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/features/requests/screens/request_chat_page.dart';

class RequestsMessageSection extends StatelessWidget {
  final String currentUserId;
  const RequestsMessageSection({super.key, required this.currentUserId});

  Future<int> _getUnreadCount(String otherId, String? requestId) async {
    try {
      final res = await Supabase.instance.client
          .from('request_messages')
          .select('message_id')
          .eq('receiver_id', currentUserId)
          .eq('sender_id', otherId)
          .eq('request_id', requestId ?? '')
          .eq('is_read', false);
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('request_chat_inbox_view').stream(primaryKey: ['message_id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading requests"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, size: 60, color: Colors.grey),
                SizedBox(height: 12),
                Text("No urgent request discussions", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final myChats = snapshot.data!.where((chat) =>
        chat['sender_id'] == currentUserId || chat['receiver_id'] == currentUserId
        ).toList();

        myChats.sort((a, b) => DateTime.parse(b['sent_at'] ?? DateTime.now().toIso8601String())
            .compareTo(DateTime.parse(a['sent_at'] ?? DateTime.now().toIso8601String())));

        if (myChats.isEmpty) return const Center(child: Text("No urgent request discussions"));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: myChats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final chat = myChats[index];
            final otherId = chat['sender_id'] == currentUserId ? chat['receiver_id'] : chat['sender_id'];
            final title = "Request: ${chat['stuff_title'] ?? 'Help'}";

            return FutureBuilder<int>(
              future: _getUnreadCount(otherId, chat['request_id']),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.bolt, color: Colors.white)),
                    title: Text(title, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600)),
                    subtitle: Text(chat['last_message'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: unreadCount > 0
                        ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                        : const Icon(Icons.chevron_right, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => RequestChatPage(
                            receiverId: otherId,
                            receiverName: title,
                            requestId: chat['request_id'],
                          ),
                        ),
                      );
                    },
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
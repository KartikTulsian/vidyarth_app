import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/message/screens/student_message_screen.dart';
import 'package:vidyarth_app/features/requests/screens/add_request_sheet.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class StudentHome extends StatefulWidget {
  final VoidCallback onLogout;
  final UserModel userData;

  const StudentHome({
    super.key,
    required this.onLogout,
    required this.userData,
  });

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService();

  void _showNotificationMenu(
    BuildContext context,
    List<Map<String, dynamic>> unreadMessages,
  ) {
    if (unreadMessages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No new notifications")));
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
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: unreadMessages.length > 5
                    ? 5
                    : unreadMessages.length,
                itemBuilder: (context, index) {
                  final msg = unreadMessages[index];
                  final isRequest = msg['title_prefix'].toString().contains('Urgent');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRequest ? Colors.redAccent : Colors.blueGrey,
                      child: Icon(isRequest ? Icons.bolt : Icons.mail_outline, color: Colors.white),
                    ),
                    title: Text("${msg['title_prefix']}${msg['stuff_title'] ?? 'Message'}"),
                    subtitle: Text(
                      msg['text'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx); // Close sheet

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentMessageScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRequestSheet(
        onRequestAdded: () {
          setState(() {}); // Refresh home counts
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Urgent request posted successfully!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = widget.userData.id;
    final String displayName =
        widget.userData.profile?.displayName ??
        widget.userData.profile?.fullName ??
        "Student";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Force rebuild of FutureBuilders
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
                        .eq('receiver_id', currentUserId)
                        .order('sent_at'),
                    builder: (context, normalSnapshot) {
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabase
                            .from('request_messages')
                            .stream(primaryKey: ['message_id'])
                            .eq('receiver_id', currentUserId)
                            .order('sent_at'),
                        builder: (context, requestSnapshot) {

                          final normalMessages = normalSnapshot.data ?? [];
                          final requestMessages = requestSnapshot.data ?? [];

                          final unreadNormal = normalMessages.where((m) => m['is_read'] == false).toList();
                          final unreadRequests = requestMessages.where((m) => m['is_read'] == false).toList();

                          // Combine and tag them
                          final combinedUnread = [
                            ...unreadNormal.map((m) => {...m, 'title_prefix': 'Trade: '}),
                            ...unreadRequests.map((m) => {...m, 'title_prefix': 'Urgent Request: '})
                          ];

                          // Sort newest first
                          combinedUnread.sort((a, b) {
                            final dateA = DateTime.tryParse(a['sent_at'] ?? '') ?? DateTime.now();
                            final dateB = DateTime.tryParse(b['sent_at'] ?? '') ?? DateTime.now();
                            return dateB.compareTo(dateA);
                          });

                          int unreadCount = combinedUnread.length;

                          return Stack(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () => _showNotificationMenu(context, combinedUnread),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Text('$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 8),
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildActionHeader(),
              const SizedBox(height: 20),
              _buildActiveTradeCard(currentUserId),
              const SizedBox(height: 24),

              const Text(
                "My Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDynamicStats(currentUserId),
              const SizedBox(height: 24),

              _buildFinancialSummary(),
              const SizedBox(height: 24),

              // const Text(
              //   "Recent Discussions",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 12),
              // _buildRecentDiscussions(currentUserId),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRequestSheet(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.bolt, color: Colors.white),
        label: const Text("Urgent Need", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActiveTradeCard(String userId) {
    return FutureBuilder<List<dynamic>>(
      future: _supabase
          .from('trades')
          .select('*, offers(stuff(title))')
          .or('borrower_id.eq.$userId, lender_id.eq.$userId')
          .eq('status', 'ACCEPTED')
          .order('start_date', ascending: false)
          .limit(1),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStaticPromoCard();
        }
        final trade = snapshot.data![0];
        final title = trade['offers']['stuff']['title'] ?? "Active Trade";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, Colors.blue.shade300],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Active Trade",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pickup Code: ${trade['pickup_code']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.handshake_rounded,
                color: Colors.white70,
                size: 40,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicStats(String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchActivityCounts(userId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'borrowed': 0, 'lent': 0, 'requests': 0};
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Borrowed",
                "${stats['borrowed']}",
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard("Lent", "${stats['lent']}", Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Requests",
                "${stats['requests']}",
                Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinancialSummary() {
    return FutureBuilder<double>(
      future: _service.getOutstandingPlatformFees(),
      builder: (context, snapshot) {
        final dues = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Platform Dues Tracking",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "10% Fee on Sales/Rentals:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "₹${dues.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Collected during subscription renewal.",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildRecentDiscussions(String currentUserId) {
  //   return StreamBuilder<List<Map<String, dynamic>>>(
  //     // Stream from the view for efficiency and real titles
  //     stream: _supabase.from('chat_inbox_view').stream(primaryKey: ['message_id']),
  //     builder: (context, snapshot) {
  //       if (snapshot.hasError) return Text("Error loading chats");
  //       if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
  //
  //       // Filter to show only chats belonging to ME and NOT hidden
  //       final myChats = snapshot.data!.where((chat) {
  //         // Only show if I am part of the chat AND my ID is NOT in the hidden_from_users list
  //         final List<dynamic> hiddenUsers = chat['hidden_from_users'] ?? [];
  //         return (chat['sender_id'] == currentUserId || chat['receiver_id'] == currentUserId)
  //             && !hiddenUsers.contains(currentUserId);
  //       }).toList();
  //
  //       // Sort by the 'sent_at' timestamp from the view
  //       myChats.sort((a, b) => DateTime.parse(b['sent_at']).compareTo(DateTime.parse(a['sent_at'])));
  //
  //       return ListView.builder(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: myChats.length,
  //         itemBuilder: (context, index) {
  //           final chat = myChats[index];
  //           final String otherId = chat['sender_id'] == currentUserId ? chat['receiver_id'] : chat['sender_id'];
  //           final String title = chat['stuff_title'] ?? "General Discussion";
  //           final String lastMsg = chat['last_message'] ?? "";
  //
  //           // Re-calculate unread count locally for this specific conversation
  //           return FutureBuilder<int>(
  //             future: _getUnreadCount(otherId, chat['offer_id']),
  //             builder: (context, unreadSnapshot) {
  //               final unreadCount = unreadSnapshot.data ?? 0;
  //
  //               return Card(
  //                 elevation: 0,
  //                 margin: const EdgeInsets.only(bottom: 8),
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
  //                 child: ListTile(
  //                   leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
  //                   title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                   subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
  //                   trailing: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       if (unreadCount > 0)
  //                         Container(
  //                           padding: const EdgeInsets.all(6),
  //                           decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
  //                           child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  //                         ),
  //                       const SizedBox(width: 8),
  //                       const Icon(Icons.chevron_right, size: 16),
  //                     ],
  //                   ),
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (ctx) => ChatPage(
  //                           receiverId: otherId,
  //                           receiverName: title,
  //                           offerId: chat['offer_id'],
  //                         ),
  //                       ),
  //                     ).then((_) => setState(() {})); // This clears the notification when you come back!
  //                   },
  //
  //                   onLongPress: () {
  //                     showDialog(
  //                       context: context,
  //                       builder: (ctx) => AlertDialog(
  //                         title: const Text("Hide Discussion?"),
  //                         content: const Text("This will hide the chat from your list. It will reappear if you get a new message."),
  //                         actions: [
  //                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
  //                           TextButton(
  //                               onPressed: () async {
  //                                 Navigator.pop(ctx);
  //                                 // Update the message in DB to include current user in 'hidden_from_users'
  //                                 await _supabase.rpc('hide_message_for_user', params: {
  //                                   'msg_id': chat['message_id'],
  //                                   'u_id': currentUserId
  //                                 });
  //                                 setState(() {}); // Refresh UI
  //                               },
  //                               child: const Text("Hide", style: TextStyle(color: Colors.red))
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               );
  //             },
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

// // Helper to get unread count per conversation
//   Future<int> _getUnreadCount(String senderId, String? offerId) async {
//     final res = await _supabase.from('messages')
//         .select('message_id')
//         .eq('receiver_id', _supabase.auth.currentUser!.id)
//         .eq('sender_id', senderId)
//         .eq('offer_id', offerId ?? '')
//         .eq('is_read', false);
//     return (res as List).length;
//   }

  Future<Map<String, int>> _fetchActivityCounts(String userId) async {
    try {
      // 1. Fetch raw data from Supabase
      final bData = await _supabase
          .from('trades')
          .select('*')
          .eq('borrower_id', userId)
          .or('status.eq.ACCEPTED,status.eq.COMPLETED');
      final lData = await _supabase
          .from('trades')
          .select('*')
          .eq('lender_id', userId)
          .or('status.eq.ACCEPTED,status.eq.COMPLETED');

      print("DEBUG: Borrowed count: ${(bData as List).length}, Lent count: ${(lData as List).length}");
      final rData = await _supabase
          .from('requests')
          .select('request_id')
          .eq('user_id', userId)
          .or('status.eq.OPEN,status.eq.CLOSED');

      // 2. Map the data to Trade model lists
      final List<Trade> borrowedItems = (bData as List)
          .map((m) => Trade.fromMap(m))
          .toList();
      final List<Trade> lentItems = (lData as List)
          .map((m) => Trade.fromMap(m))
          .toList();
      final List<Trade> requests = (rData as List)
          .map((m) => Trade.fromMap(m))
          .toList();

      // 3. Return counts (and you can now access trade details like borrowedItems[0].platformFee)
      return {
        'borrowed': borrowedItems.length,
        'lent': lentItems.length,
        'requests': requests.length,
      };
    } catch (e) {
      debugPrint("DEBUG ERROR in _fetchActivityCounts: $e");
      return {'borrowed': 0, 'lent': 0, 'requests': 0};
    }
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStaticPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No Active Trades",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Explore items nearby to start trading!",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.search, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildActionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Can't find an item?", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Post an urgent request to the community.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => AddRequestSheet(onRequestAdded: () => setState(() {})),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Post Urgent", style: TextStyle(fontSize: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

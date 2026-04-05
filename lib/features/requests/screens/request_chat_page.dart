import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/requests/screens/request_contract_review_card.dart';
import 'package:vidyarth_app/features/requests/screens/request_contract_sheet.dart';
import 'package:vidyarth_app/shared/models/request_message_model.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';
import 'package:vidyarth_app/shared/models/request_trade_model.dart';

class RequestChatPage extends StatefulWidget {
  final String requestId;
  final String receiverId;
  final String receiverName;

  const RequestChatPage({
    super.key,
    required this.requestId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<RequestChatPage> createState() => _RequestChatPageState();
}

class _RequestChatPageState extends State<RequestChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  final Map<String, RequestTrade> _tradeCache = {};

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() async {
    await _service.markRequestMessagesAsRead(widget.receiverId, widget.requestId);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();

    final message = RequestMessage(
      senderId: _currentUserId,
      receiverId: widget.receiverId,
      requestId: widget.requestId,
      text: text,
    );
    await _supabase.from('request_messages').insert(message.toMap());
  }

  void _onContractSent(RequestTrade trade) async {
    try {
      final response = await _supabase.from('request_trades').insert(trade.toMap()).select().single();
      final newTrade = RequestTrade.fromMap(response);

      setState(() {
        _messageController.text = "REQ_TRADE_ID:${newTrade.tradeId}";
      });
      _sendMessage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _openRequestContractWorkflow() async {
    final reqData = await _supabase.from('requests').select().eq('request_id', widget.requestId).single();
    final request = RequestModel.fromMap(reqData);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestContractSheet(
        request: request,
        helperId: _currentUserId, // I am the one offering help
        onContractSent: (trade) => _onContractSent(trade),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Only show the Handshake button if I am NOT the person who made the request
          if (widget.receiverId != _currentUserId)
            IconButton(
              onPressed: _openRequestContractWorkflow,
              icon: const Icon(Icons.handshake_outlined, color: Colors.redAccent),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('request_messages').stream(primaryKey: ['message_id']).eq('request_id', widget.requestId).order('sent_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Offer your help..."));

        final messages = snapshot.data!.map((m) => RequestMessage.fromMap(m)).where((m) {
          return (m.senderId == _currentUserId && m.receiverId == widget.receiverId) ||
              (m.senderId == widget.receiverId && m.receiverId == _currentUserId);
        }).toList();

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final bool isMe = msg.senderId == _currentUserId;

            if (msg.text.contains("REQ_TRADE_ID:")) {
              return _fetchAndBuildContractCard(msg.text, isMe);
            }
            return _buildMessageBubble(msg.text, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none)),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.redAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
      ),
    );
  }

  Widget _fetchAndBuildContractCard(String messageText, bool isMe) {
    final tradeId = messageText.split(':').last.trim();

    if (_tradeCache.containsKey(tradeId)) return RequestContractReviewCard(trade: _tradeCache[tradeId]!, isMe: isMe, onAccept: () => _finalizeTrade(_tradeCache[tradeId]!), onReject: () => _updateTradeStatus(tradeId, 'REJECTED'));

    return FutureBuilder<RequestTrade?>(
      future: _service.getRequestTradeById(tradeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData) return const Text("Contract unavailable");

        final trade = snapshot.data!;
        _tradeCache[tradeId] = trade; // Cache it
        return RequestContractReviewCard(
          trade: trade,
          isMe: isMe,
          onAccept: () => _finalizeTrade(trade),
          onReject: () => _updateTradeStatus(tradeId, 'REJECTED'),
        );
      },
    );
  }

  Future<void> _finalizeTrade(RequestTrade trade) async {
    try {
      final String code = (100000 + (DateTime.now().millisecond * 899)).toString().substring(0, 6);
      await _supabase.from('request_trades').update({'status': 'ACCEPTED', 'pickup_code': code}).eq('trade_id', trade.tradeId!);

      // Also mark the original request as closed
      await _supabase.from('requests').update({'status': 'CLOSED'}).eq('request_id', trade.requestId);

      _messageController.text = "✅ I've accepted your help! Pickup code is: $code";
      _sendMessage();
      setState(() {});
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> _updateTradeStatus(String tradeId, String newStatus) async {
    try {
      await _supabase.from('request_trades').update({'status': newStatus}).eq('trade_id', tradeId);
      _messageController.text = "❌ I have declined the proposal.";
      _sendMessage();
      setState(() {});
    } catch (e) {
      print("ERROR: $e");
    }
  }
}

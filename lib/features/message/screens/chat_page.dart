import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/message/widgets/contract_review_card.dart';
import 'package:vidyarth_app/features/message/widgets/trade_contract_sheet.dart';
import 'package:vidyarth_app/features/trade/screens/add_item_sheet.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/message_model.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? offerId;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.offerId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  Offer? _offerDetails;
  bool _isOwner = false;

  late Stream<List<Map<String, dynamic>>> _messageStream;
  final Map<String, Trade> _tradeCache = {};

  @override
  void initState() {
    super.initState();
    _messageStream = _supabase
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .eq('offer_id', widget.offerId ?? '')
        .order('sent_at', ascending: false);
    _markRead();
    _loadOfferAndCheckOwnership();
  }

  Future<void> _loadOfferAndCheckOwnership() async {
    if (widget.offerId == null) return;
    final offer = await _service.getOfferById(widget.offerId!);
    if (offer != null && mounted) {
      setState(() {
        _offerDetails = offer;
        // Only the person who created the offer (userId) is the owner
        _isOwner = offer.userId == _currentUserId;
      });
    }
  }

  void _viewItemDetails() async {
    if (widget.offerId == null) return;

    // Show a loading indicator
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    try {
      final Offer? fullOffer = await _service.getOfferById(widget.offerId!);
      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (fullOffer != null && fullOffer.stuff != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: fullOffer.stuff!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item or Offer details are no longer available")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Navigation Error: $e");
    }
  }

  void _markRead() async {
    await _service.markMessagesAsRead(widget.receiverId, widget.offerId);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final message = Message(
      senderId: _currentUserId,
      receiverId: widget.receiverId,
      offerId: widget.offerId,
      text: text,
    );

    await _supabase.from('messages').insert(message.toMap());
  }

  void _openTradeContractWorkflow() async {

    // STEP 1: Let the owner update the item details (Negotiation phase)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        itemToEdit: _offerDetails!.stuff, // Pass the associated stuff
        onItemAdded: () => Navigator.pop(context),
      ),
    );
    // // 1. Fetch the offer details for this chat
    // if (widget.offerId == null) return;
    //
    // final offer = await _service.getOfferById(widget.offerId!);

    // STEP 2: Refresh offer details after potential database update
    await _loadOfferAndCheckOwnership();

    if (mounted && _offerDetails != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TradeContractSheet(
          offer: _offerDetails!,
          borrowerId: widget.receiverId,
          onContractSent: (trade) async {
            // Save Trade to DB
            final response = await _supabase.from('trades').insert(trade.toMap()).select().single();
            final tradeId = response['trade_id'];

            // Send the hidden trigger message to show the ContractReviewCard
            _messageController.text = "TRADE_CONTRACT_ID:$tradeId";
            _sendMessage();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            // const Text("Online", style: TextStyle(color: Colors.green, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _viewItemDetails,
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            tooltip: "View Item Details",
          ),
          if (_isOwner && _offerDetails != null) // Only shown to Owner
            IconButton(
                onPressed: _openTradeContractWorkflow,
                icon: const Icon(Icons.handshake_outlined, color: Colors.blueAccent)
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildEnhancedMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('messages')
          .stream(primaryKey: ['message_id'])
          .eq('offer_id', widget.offerId ?? '') // Only get messages for this item
          .order('sent_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading messages"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!
            .map((m) => Message.fromMap(m))
            .where((m) {
          // Secondary security check: Ensure the message involves the current user
          return (m.senderId == _currentUserId && m.receiverId == widget.receiverId) ||
              (m.senderId == widget.receiverId && m.receiverId == _currentUserId);
        }).toList();

        if (messages.isEmpty) return const Center(child: Text("No messages yet."));

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final Message msg = messages[index];
            final bool isMe = msg.senderId == _currentUserId;

            // Check if this message is a hidden trigger for a contract
            if (msg.text.contains("TRADE_CONTRACT_ID:")) {
              return _fetchAndBuildContractCard(msg.text, isMe);
            }

            return _buildMessageBubble(msg.text, isMe);
          },
        );
      },
    );
  }

  Widget _buildEnhancedMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Colors.grey)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _fetchAndBuildContractCard(String messageText, bool isMe) {
    final tradeId = messageText.split(':').last;

    if (_tradeCache.containsKey(tradeId)) {
      return ContractReviewCard(
        trade: _tradeCache[tradeId]!,
        isMe: isMe,
        onAccept: () => _finalizeTrade(_tradeCache[tradeId]!),
        onReject: () => _updateTradeStatus(tradeId, 'REJECTED'),
      );
    }

    return FutureBuilder<Trade?>(
      future: _service.getTradeById(tradeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data == null) return const Text("Contract Expired");

        final Trade trade = snapshot.data!;
        return ContractReviewCard(
          trade: trade,
          isMe: isMe,
          onAccept: () => _finalizeTrade(trade),
          onReject: () => _updateTradeStatus(trade.tradeId!, 'REJECTED'),
        );
      },
    );
  }

  Future<void> _finalizeTrade(Trade trade) async {
    // Generate a 6-digit random pickup code
    final String code = (100000 + (DateTime.now().millisecond * 899)).toString().substring(0, 6);

    await _supabase.from('trades').update({
      'status': 'ACCEPTED',
      'pickup_code': code,
      'start_date': DateTime.now().toIso8601String(),
    }).eq('trade_id', trade.tradeId!);

    if (_tradeCache.containsKey(trade.tradeId)) {
      final updatedTrade = Trade.fromMap({
        ...trade.toMap(), // Existing data
        'trade_id': trade.tradeId,
        'status': 'ACCEPTED',
        'pickup_code': code,
      });
      setState(() {
        _tradeCache[trade.tradeId!] = updatedTrade;
      });
    }

    _messageController.text = "✅ I've accepted the contract! Our pickup code is: $code";
    _sendMessage();
    setState(() {});
  }

  Future<void> _updateTradeStatus(String tradeId, String newStatus) async {
    try {
      await _supabase
          .from('trades')
          .update({'status': newStatus})
          .eq('trade_id', tradeId);

      if (newStatus == 'REJECTED') {
        _messageController.text = "❌ I have declined the trade terms.";
        _sendMessage();
      }
      setState(() {}); // Refresh UI to update the card state
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }
}

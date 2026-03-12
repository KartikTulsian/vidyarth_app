class Message {
  final String? messageId;
  final String? senderId;
  final String? receiverId;
  final String? offerId;
  final String text;
  final bool isRead;
  final DateTime? sentAt;

  Message({
    this.messageId,
    this.senderId,
    this.receiverId,
    this.offerId,
    required this.text,
    this.isRead = false,
    this.sentAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    messageId: map['message_id'],
    senderId: map['sender_id'],
    receiverId: map['receiver_id'],
    offerId: map['offer_id'],
    text: map['text'] ?? '',
    isRead: map['is_read'] ?? false,
    sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
  );

  Map<String, dynamic> toMap() => {
    'sender_id': senderId,
    'receiver_id': receiverId,
    'offer_id': offerId,
    'text': text,
    'is_read': isRead,
  };
}
class RequestMessage {
  final String? messageId;
  final String? senderId;
  final String? receiverId;
  final String? requestId;
  final String text;
  final bool isRead;
  final DateTime? sentAt;

  RequestMessage({
    this.messageId,
    this.senderId,
    this.receiverId,
    this.requestId,
    required this.text,
    this.isRead = false,
    this.sentAt,
  });

  factory RequestMessage.fromMap(Map<String, dynamic> map) => RequestMessage(
    messageId: map['message_id'],
    senderId: map['sender_id'],
    receiverId: map['receiver_id'],
    requestId: map['request_id'],
    text: map['text'] ?? '',
    isRead: map['is_read'] ?? false,
    sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
  );

  Map<String, dynamic> toMap() => {
    'sender_id': senderId,
    'receiver_id': receiverId,
    'request_id': requestId,
    'text': text,
    'is_read': isRead,
  };
}
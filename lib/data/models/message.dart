enum MessageType { text, image, location, offer, contact, ewallet, system }
enum ChatType { order, direct }

class Chat {
  final String id;
  final ChatType type;
  final String? requestId;
  final String? orderId;
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.type,
    this.requestId,
    this.orderId,
    required this.title,
    required this.participantIds,
    required this.createdAt,
  });
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String body;
  final DateTime createdAt;
  final int? offerAmount;
  final String? offerStatus;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.type = MessageType.text,
    required this.body,
    required this.createdAt,
    this.offerAmount,
    this.offerStatus,
  });

  ChatMessage copyWith({String? offerStatus}) => ChatMessage(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        type: type,
        body: body,
        createdAt: createdAt,
        offerAmount: offerAmount,
        offerStatus: offerStatus ?? this.offerStatus,
      );
}
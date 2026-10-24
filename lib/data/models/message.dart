enum MessageType { text, image, location, offer, contact, ewallet, system, requestCard }
enum ChatType { order, direct }
enum CardStatus { pending, approved, paid, completed, cancelled }

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
  final Map<String, dynamic>? requestData; // Untuk menyimpan data booking (title, price, time, status)

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
    this.requestData,
  });

  ChatMessage copyWith({String? offerStatus, Map<String, dynamic>? requestData}) => ChatMessage(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        type: type,
        body: body,
        createdAt: createdAt,
        offerAmount: offerAmount,
        offerStatus: offerStatus ?? this.offerStatus,
        requestData: requestData ?? this.requestData,
      );
}
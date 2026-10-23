import '../models/message.dart';

abstract class ChatRepository {
  Stream<List<Chat>> watchChats(String userId);
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Future<Chat> getOrCreateOrderChat({
    required String chatId,
    required String requestId,
    required String title,
    required List<String> participants,
  });
  Future<void> sendMessage(ChatMessage msg);
  Chat? getChat(String chatId);
}
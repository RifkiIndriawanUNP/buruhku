import 'dart:async';
import '../../models/message.dart';
import '../chat_repository.dart';
import 'reactive.dart';

class MemoryChatRepo implements ChatRepository {
  final Map<String, Chat> _chats = {};
  final Map<String, Reactive<List<ChatMessage>>> _messages = {};
  final Map<String, Reactive<List<Chat>>> _chatsByUser = {};

  @override
  Stream<List<Chat>> watchChats(String userId) => _bucket(userId).stream;

  Reactive<List<Chat>> _bucket(String userId) =>
      _chatsByUser.putIfAbsent(userId, () => Reactive(<Chat>[]));

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => _msgsBucket(chatId).stream;

  Reactive<List<ChatMessage>> _msgsBucket(String chatId) =>
      _messages.putIfAbsent(chatId, () => Reactive(<ChatMessage>[]));

  @override
  Future<Chat> getOrCreateOrderChat({
    required String chatId,
    required String requestId,
    required String title,
    required List<String> participants,
  }) async {
    final existing = _chats[chatId];
    if (existing != null) return existing;

    final chat = Chat(
      id: chatId,
      type: ChatType.order,
      requestId: requestId,
      title: title,
      participantIds: participants,
      createdAt: DateTime.now(),
    );
    addChatToParticipants(chat);
    return chat;
  }

  void addChatToParticipants(Chat chat) {
    _chats[chat.id] = chat;
    for (final p in chat.participantIds) {
      final b = _bucket(p);
      b.set([chat, ...b.value.where((c) => c.id != chat.id)]);
    }
  }

  @override
  Future<void> sendMessage(ChatMessage msg) async {
    final list = _msgsBucket(msg.chatId).value;
    _msgsBucket(msg.chatId).set([...list, msg]);
    
    final chat = _chats[msg.chatId];
    if (chat != null) {
      for (final p in chat.participantIds) {
        final b = _bucket(p);
        b.set(b.value.map((c) => c.id == chat.id ? chat : c).toList());
      }
    }
  }

  // --- FUNGSI BARU UNTUK UPDATE STATUS CARD ---
  void updateRequestCardStatus(String messageId, String newStatus) {
    for (var chatId in _messages.keys) {
      final msgs = _messages[chatId]!.value;
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final m = msgs[idx];
        final newData = Map<String, dynamic>.from(m.requestData ?? {});
        newData['status'] = newStatus;
        msgs[idx] = m.copyWith(requestData: newData);
        _messages[chatId]!.set([...msgs]);
        break;
      }
    }
  }

  @override
  Chat? getChat(String chatId) => _chats[chatId];

  List<ChatMessage> getMessages(String chatId) => _msgsBucket(chatId).value;
}
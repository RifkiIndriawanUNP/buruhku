import 'dart:async';

import '../../models/message.dart';
import '../chat_repository.dart';
import 'reactive.dart';

class MemoryChatRepo implements ChatRepository {
  final Map<String, Chat> _chats = {};
  final Map<String, Reactive<List<ChatMessage>>> _messages = {};
  final Map<String, Reactive<List<Chat>>> _chatsByUser = {};

  @override
  Stream<List<Chat>> watchChats(String userId) {
    return _bucket(userId).stream;
  }

  Reactive<List<Chat>> _bucket(String userId) =>
      _chatsByUser.putIfAbsent(userId, () => Reactive(<Chat>[]));

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _msgsBucket(chatId).stream;
  }

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
    _chats[chatId] = chat;
    for (final p in participants) {
      final b = _bucket(p);
      b.set([chat, ...b.value.where((c) => c.id != chatId)]);
    }
    return chat;
  }

  @override
  Future<void> sendMessage(ChatMessage msg) async {
    final list = _msgsBucket(msg.chatId).value;
    final updated = [...list, msg];
    _msgsBucket(msg.chatId).set(updated);
    // Update last message preview on chat list
    final chat = _chats[msg.chatId];
    if (chat != null) {
      for (final p in chat.participantIds) {
        final b = _bucket(p);
        final newList = b.value
            .map((c) => c.id == chat.id ? chat : c)
            .toList();
        b.set(newList);
      }
    }
  }

  @override
  Chat? getChat(String chatId) => _chats[chatId];

  List<ChatMessage> getMessages(String chatId) =>
      _msgsBucket(chatId).value;

  void addChatToParticipants(Chat chat) {
    _chats[chat.id] = chat;
    for (final p in chat.participantIds) {
      final b = _bucket(p);
      b.set([chat, ...b.value.where((c) => c.id != chat.id)]);
    }
  }
}
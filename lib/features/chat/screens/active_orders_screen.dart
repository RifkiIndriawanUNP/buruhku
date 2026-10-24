import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/message.dart';
import 'chat_screen.dart';

class ActiveOrdersScreen extends StatelessWidget {
  const ActiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Aktif')),
      body: StreamBuilder<List<Chat>>(
        stream: Services.chats.watchChats(user.id),
        builder: (context, snap) {
          final chats = snap.data ?? const <Chat>[];
          if (chats.isEmpty) {
            return const Center(child: Text('Belum ada order aktif.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final c = chats[i];
              return InkWell(
                onTap: () {
                  final other = c.participantIds.firstWhere((p) => p != user.id, orElse: () => 'agent');
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: c.id, title: c.title, agentId: other, agentName: c.title, requestId: c.requestId,
                    ),
                  ));
                },
                child: AppBox(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      InitialAvatar(name: c.title),
                      const SizedBox(width: 12),
                      Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
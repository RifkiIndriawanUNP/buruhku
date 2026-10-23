import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/message.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: StreamBuilder<List<Chat>>(
        stream: Services.chats.watchChats(user.id),
        builder: (context, snap) {
          final chats = snap.data ?? const <Chat>[];
          if (chats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada chat.\nChat akan muncul setelah Anda membuat request dan agen menyetujui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = chats[i];
              return InkWell(
                onTap: () {
                  final other = c.participantIds.firstWhere(
                    (p) => p != user.id,
                    orElse: () => 'agent',
                  );
                  final title = c.title.isNotEmpty ? c.title : 'Chat';
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'chatId': c.id,
                      'title': title,
                      'agentId': other,
                      'agentName': title,
                      'requestId': c.requestId,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: AppBox(
                  child: Row(
                    children: [
                      InitialAvatar(name: c.title, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.type == ChatType.order
                                        ? Colors.blue.withValues(alpha: .1)
                                        : Colors.grey.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.type == ChatType.order ? 'Order' : 'Langsung',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: c.type == ChatType.order
                                          ? Colors.blue
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.type == ChatType.order
                                  ? 'Negosiasi & koordinasi order'
                                  : 'Chat langsung',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
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
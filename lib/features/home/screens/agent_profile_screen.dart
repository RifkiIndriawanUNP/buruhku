import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../core/widgets/tombol.dart';
import '../../../data/models/agent.dart';
import '../../../data/models/message.dart'; 
import '../../chat/screens/chat_screen.dart';

class AgentProfileScreen extends StatelessWidget {
  final Agent agent;
  const AgentProfileScreen({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(agent.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: InitialAvatar(name: agent.displayName, size: 96)),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(agent.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                if (agent.verified)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified, color: Colors.blue, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '⭐ ${agent.ratingAvg.toStringAsFixed(1)} · ${agent.jobsCompleted} pekerjaan selesai',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          AppBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tentang', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(agent.bio.isEmpty ? 'Belum ada deskripsi.' : agent.bio),
                const SizedBox(height: 10),
                Text(
                  'Jarak dari lokasi Anda: ${agent.distanceFrom(Env.demoLat, Env.demoLng).toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  'Radius layanan: ${agent.serviceRadiusKm.toStringAsFixed(0)} km',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final chatId = 'chat_direct_${agent.id}';
              final user = Services.auth.currentUser!;
              final chat = Services.chats.getChat(chatId);
              if (chat == null) {
                Services.chats.addChatToParticipants(
                  Chat(
                    id: chatId,
                    type: ChatType.direct,
                    title: 'Chat dengan ${agent.displayName}',
                    participantIds: [user.id, agent.id],
                    createdAt: DateTime.now(),
                  ),
                );
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chatId,
                    title: agent.displayName,
                    agentId: agent.id,
                    agentName: agent.displayName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat Langsung'),
          ),
          const SizedBox(height: 8),
          WireButton(
            label: 'Simpan sebagai Favorit',
            icon: Icons.favorite_border,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disimpan ke favorit (demo)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
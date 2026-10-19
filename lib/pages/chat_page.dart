import 'package:flutter/material.dart';
import '../widgets/colorful_card.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
      children: const [
        ColorfulCard(
          color: Color(0xFF2EC4B6),
          title: 'Chat Card 1',
          subtitle: 'Conversation placeholder',
        ),
        ColorfulCard(
          color: Color(0xFFFFBF69),
          title: 'Chat Card 2',
          subtitle: 'Liquid glass chat UI',
        ),
        ColorfulCard(
          color: Color(0xFFB8F2E6),
          title: 'Chat Card 3',
          subtitle: 'Scrollable content',
        ),
        ColorfulCard(
          color: Color(0xFFE71D36),
          title: 'Chat Card 4',
          subtitle: 'Glass morphism demo',
        ),
        ColorfulCard(
          color: Color(0xFF011627),
          title: 'Chat Card 5',
          subtitle: 'Interactive navigation',
        ),
      ],
    );
  }
}
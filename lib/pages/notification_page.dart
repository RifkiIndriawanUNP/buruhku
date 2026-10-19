import 'package:flutter/material.dart';
import '../widgets/colorful_card.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
      children: const [
        ColorfulCard(
          color: Color(0xFFFF4D6D),
          title: 'Notification 1',
          subtitle: 'New message from...',
        ),
        ColorfulCard(
          color: Color(0xFFFFB703),
          title: 'Notification 2',
          subtitle: 'Update available',
        ),
        ColorfulCard(
          color: Color(0xFF8AC926),
          title: 'Notification 3',
          subtitle: 'Liquid glass UI',
        ),
        ColorfulCard(
          color: Color(0xFF1982C4),
          title: 'Notification 4',
          subtitle: 'Drag indicator demo',
        ),
        ColorfulCard(
          color: Color(0xFF6A4C93),
          title: 'Notification 5',
          subtitle: 'Smooth animations',
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../widgets/colorful_card.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
      children: const [
        ColorfulCard(
          color: Color(0xFFFF9F1C),
          title: 'Explore Card 1',
          subtitle: 'Discover new liquid effects',
        ),
        ColorfulCard(
          color: Color(0xFF00B4D8),
          title: 'Explore Card 2',
          subtitle: 'Scroll through glass cards',
        ),
        ColorfulCard(
          color: Color(0xFF7209B7),
          title: 'Explore Card 3',
          subtitle: 'Interactive navigation',
        ),
        ColorfulCard(
          color: Color(0xFFF72585),
          title: 'Explore Card 4',
          subtitle: 'Try dragging the indicator',
        ),
        ColorfulCard(
          color: Color(0xFF4361EE),
          title: 'Explore Card 5',
          subtitle: 'Placeholder content',
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../widgets/colorful_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
      children: const [
        ColorfulCard(
          color: Color(0xFFFF6B6B),
          title: 'Home Card 1',
          subtitle: 'Placeholder scrollable content',
        ),
        ColorfulCard(
          color: Color(0xFFFFD93D),
          title: 'Home Card 2',
          subtitle: 'Liquid glass navigation demo',
        ),
        ColorfulCard(
          color: Color(0xFF6BCB77),
          title: 'Home Card 3',
          subtitle: 'Drag the pill indicator',
        ),
        ColorfulCard(
          color: Color(0xFF4D96FF),
          title: 'Home Card 4',
          subtitle: 'Smooth snapping animation',
        ),
        ColorfulCard(
          color: Color(0xFF9B5DE5),
          title: 'Home Card 5',
          subtitle: 'SDF refraction & dispersion',
        ),
      ],
    );
  }
}
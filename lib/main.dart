import 'package:flutter/material.dart';
import 'navigation/liquid_glass_nav_bar.dart';
import 'pages/home_page.dart';
import 'pages/explore_page.dart';
import 'pages/chat_page.dart';
import 'pages/notification_page.dart';

void main() {
  runApp(const LiquidGlassApp());
}

class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        //textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _pages = const [
    HomePage(),
    ExplorePage(),
    ChatPage(),
    NotificationPage(),
  ];

  void _onNavItemSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Konten halaman (background)
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Navigasi Liquid Glass di atas konten
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: LiquidGlassNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/agent_mode/screens/agent_dashboard_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/order/screens/order_detail_screen.dart';
import '../features/request/screens/create_request_screen.dart';
import '../features/request/screens/acceptors_screen.dart';
import '../features/request/screens/my_requests_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/safety/screens/sos_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/':
        return MaterialPageRoute(builder: (_) => const MainShell());
      case '/agent_mode':
        return MaterialPageRoute(builder: (_) => const AgentDashboardScreen());
      case '/create_request':
        return MaterialPageRoute(builder: (_) => const CreateRequestScreen());
      case '/my_requests':
        return MaterialPageRoute(builder: (_) => const MyRequestsScreen());
      case '/sos':
        return MaterialPageRoute(builder: (_) => const SosScreen());
      default:
        // Dynamic routes with arguments
        if (settings.name == '/chat' && settings.arguments is Map) {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: args['chatId'] as String,
              title: args['title'] as String,
              agentId: args['agentId'] as String,
              agentName: args['agentName'] as String,
              requestId: args['requestId'] as String?,
            ),
          );
        }
        if (settings.name == '/acceptors' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) =>
                AcceptorsScreen(requestId: settings.arguments as String),
          );
        }
        if (settings.name == '/order' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) =>
                OrderDetailScreen(orderId: settings.arguments as String),
          );
        }
        if (settings.name == '/account') {
          return MaterialPageRoute(builder: (_) => const AccountScreen());
        }
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
            body: Center(child: Text('Route: ${settings.name}')),
          ),
        );
    }
  }
}
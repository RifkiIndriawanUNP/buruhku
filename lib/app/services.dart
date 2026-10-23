import '../data/repositories/memory/agent_simulator.dart';
import '../data/repositories/memory/memory_auth_repo.dart';
import '../data/repositories/memory/memory_chat_repo.dart';
import '../data/repositories/memory/memory_order_repo.dart';
import '../data/repositories/memory/memory_request_repo.dart';

class Services {
  static final auth = MemoryAuthRepo();
  static final requests = MemoryRequestRepo();
  static final chats = MemoryChatRepo();
  static final orders = MemoryOrderRepo();
  static late final AgentSimulator simulator;

  static bool _inited = false;

  static void init() {
    if (_inited) return;
    _inited = true;
    simulator = AgentSimulator(
      auth: auth,
      requests: requests,
      chats: chats,
    );
    simulator.start();
  }
}
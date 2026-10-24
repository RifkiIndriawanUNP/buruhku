import 'dart:async';
import 'dart:math';
import '../../models/acceptance.dart';
import '../../models/job_request.dart';
import '../../models/message.dart';
import 'memory_auth_repo.dart';
import 'memory_chat_repo.dart';
import 'memory_request_repo.dart';

class AgentSimulator {
  final MemoryAuthRepo auth;
  final MemoryRequestRepo requests;
  final MemoryChatRepo chats;

  Timer? _ticker;
  final Random _rand = Random();
  final Set<String> _greetedChats = {};

  AgentSimulator({required this.auth, required this.requests, required this.chats});

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  void stop() => _ticker?.cancel();

  void _tick() {
    final user = auth.currentUser;
    if (user == null) return;

    for (final req in requests.publicRequestsSnapshot.where((r) => r.clientId == user.id)) {
      if (req.status != RequestStatus.open && req.status != RequestStatus.hasAcceptors) continue;
      final current = requests.getAcceptances(req.id);
      if (current.length >= req.acceptQuota) continue;
      if (_rand.nextDouble() > 0.5) continue;

      final candidates = requests.allAgents
          .where((a) => a.categoryIds.contains(req.categoryId) && !current.any((c) => c.agentId == a.id))
          .toList();
      if (candidates.isEmpty) continue;

      final agent = candidates[_rand.nextInt(candidates.length)];
      requests.internalAddAcceptance(Acceptance(
        id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
        requestId: req.id, agentId: agent.id, agentName: agent.displayName,
        agentRating: agent.ratingAvg, agentJobsCompleted: agent.jobsCompleted,
        agentDistanceKm: agent.distanceFrom(req.lat, req.lng),
        proposedPrice: req.offeredPrice, acceptedAt: DateTime.now(),
      ));
    }
  }

  Future<void> greetIfNeeded({required String chatId, required String requestId, required Acceptance acceptance, required String clientId}) async {
    if (_greetedChats.contains(chatId)) return;
    _greetedChats.add(chatId);
    await Future.delayed(const Duration(milliseconds: 800));
    await chats.sendMessage(ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_g',
      chatId: chatId, senderId: acceptance.agentId, senderName: acceptance.agentName,
      type: MessageType.text, body: 'Halo, saya ${acceptance.agentName}. Saya tertarik dengan pekerjaan ini. Bisa diskusikan detailnya?',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> replyTo({required String chatId, required String agentId, required String agentName, required String clientMessage}) async {
    final lc = clientMessage.toLowerCase();
    String reply = lc.contains('harga') || lc.contains('nego') 
        ? 'Harga bisa kita diskusikan. Berapa penawaran terbaik Anda?' 
        : 'Baik, saya catat. Ada detail lain yang perlu saya ketahui?';
        
    await Future.delayed(Duration(milliseconds: 900 + _rand.nextInt(800)));
    await chats.sendMessage(ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId, senderId: agentId, senderName: agentName,
      type: MessageType.text, body: reply, createdAt: DateTime.now(),
    ));
  }

  // --- FUNGSI BARU UNTUK AUTO-APPROVE BOOKING CARD ---
  Future<void> simulateBookingResponse(String chatId, String messageId, String agentId, String agentName) async {
    await Future.delayed(const Duration(seconds: 2));
    // Agen membalas chat
    await chats.sendMessage(ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId, senderId: agentId, senderName: agentName,
      type: MessageType.text, body: 'Halo, saya setuju dengan detail pekerjaannya. Silakan lanjutkan ke pembayaran.',
      createdAt: DateTime.now(),
    ));
    // Agen klik Setujui di Card
    chats.updateRequestCardStatus(messageId, 'approved');
  }
}
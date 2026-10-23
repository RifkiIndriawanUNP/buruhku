import 'dart:async';
import 'dart:math';

import '../../models/acceptance.dart';
import '../../models/job_request.dart';
import '../../models/message.dart';
import 'memory_auth_repo.dart';
import 'memory_chat_repo.dart';
import 'memory_request_repo.dart';

/// Simulasi perilaku agen:
/// 1) Menekan ACC pada request yang masih OPEN (setelah delay beberapa detik).
/// 2) Mengirim pesan pembuka pada chat order.
/// 3) Membalas pesan klien dengan balasan template.
class AgentSimulator {
  final MemoryAuthRepo auth;
  final MemoryRequestRepo requests;
  final MemoryChatRepo chats;

  Timer? _ticker;
  final Random _rand = Random();
  final Set<String> _greetedChats = {};
  final Set<String> _processedRequests = {};

  AgentSimulator({
    required this.auth,
    required this.requests,
    required this.chats,
  });

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  void stop() {
    _ticker?.cancel();
  }

  void _tick() {
    final user = auth.currentUser;
    if (user == null) return;

    // For each open request from this user, maybe an agent ACC
    for (final req in _requestsForCurrentUser(user.id)) {
      if (req.status != RequestStatus.open &&
          req.status != RequestStatus.hasAcceptors &&
          req.status != RequestStatus.negotiating) {
        continue;
      }
      final current = requests.getAcceptances(req.id);
      if (current.length >= req.acceptQuota) continue;

      // Add a random agent every ~2 ticks
      if (_rand.nextDouble() > 0.5) continue;

      final candidates = requests.allAgents
          .where((a) =>
              a.categoryIds.contains(req.categoryId) &&
              !current.any((c) => c.agentId == a.id))
          .toList();
      if (candidates.isEmpty) continue;

      final agent = candidates[_rand.nextInt(candidates.length)];
      final acc = Acceptance(
        id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
        requestId: req.id,
        agentId: agent.id,
        agentName: agent.displayName,
        agentRating: agent.ratingAvg,
        agentJobsCompleted: agent.jobsCompleted,
        agentDistanceKm: agent.distanceFrom(req.lat, req.lng),
        proposedPrice: req.offeredPrice,
        acceptedAt: DateTime.now(),
      );
      requests.internalAddAcceptance(acc);
    }
  }

  List<JobRequest> _requestsForCurrentUser(String userId) {
    // Access private bucket indirectly via watchers
    // Simplicity: keep single snapshot
    //final list = <JobRequest>[];
    // We don't expose bucket; instead we piggyback on known requests via user.
    // Use a simple global map — but instead we rely on repo's public list.
    // To avoid exposing internals, we simply iterate what we can via a small trick:
    // (Not ideal but works for MVP.)
    // Note: MemoryRequestRepo keeps _requests private. We'll rely on a public method.
    return requests.publicRequestsSnapshot.where((r) => r.clientId == userId).toList();
  }

  /// Dipanggil client saat membuka chat: agen kirim sapaan + tawaran.
  Future<void> greetIfNeeded({
    required String chatId,
    required String requestId,
    required Acceptance acceptance,
    required String clientId,
  }) async {
    if (_greetedChats.contains(chatId)) return;
    _greetedChats.add(chatId);

    await Future.delayed(const Duration(milliseconds: 800));

    final greet = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_g',
      chatId: chatId,
      senderId: acceptance.agentId,
      senderName: acceptance.agentName,
      type: MessageType.text,
      body:
          'Halo, saya ${acceptance.agentName}. Saya tertarik dengan pekerjaan ini. '
          'Bisa mulai sesuai jadwal. Apakah harga penawaran bisa dinegosiasikan?',
      createdAt: DateTime.now(),
    );
    await chats.sendMessage(greet);

    // Offer message
    final offer = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_o',
      chatId: chatId,
      senderId: acceptance.agentId,
      senderName: acceptance.agentName,
      type: MessageType.offer,
      body: 'Penawaran saya',
      offerAmount: (acceptance.proposedPrice * 1.05).round(),
      offerStatus: 'pending',
      createdAt: DateTime.now(),
    );
    await chats.sendMessage(offer);
  }

  /// Dipanggil client saat kirim pesan agar agen merespons.
  Future<void> replyTo({
    required String chatId,
    required String agentId,
    required String agentName,
    required String clientMessage,
  }) async {
    final lc = clientMessage.toLowerCase();
    String reply;
    if (lc.contains('halo') || lc.contains('hai')) {
      reply = 'Halo juga! Saya siap mengerjakan. Kapan mau mulai?';
    } else if (lc.contains('harga') || lc.contains('nego') || lc.contains('turun')) {
      reply = 'Harga bisa kita diskusikan. Berapa penawaran terbaik Anda?';
    } else if (lc.contains('kapan') || lc.contains('jam') || lc.contains('besok')) {
      reply = 'Saya fleksibel. Silakan tentukan waktu, saya usahakan datang tepat waktu.';
    } else if (lc.contains('terima') || lc.contains('setuju') || lc.contains('ok')) {
      reply = 'Baik, saya setuju. Silakan pilih saya sebagai agen dan lanjutkan pembayaran.';
    } else {
      reply = 'Baik, saya catat. Ada detail lain yang perlu saya ketahui?';
    }
    
    await Future.delayed(Duration(milliseconds: 900 + _rand.nextInt(800)));
    await chats.sendMessage(
      ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        chatId: chatId,
        senderId: agentId,
        senderName: agentName,
        type: MessageType.text,
        body: reply,
        createdAt: DateTime.now(),
      ),
    );
  }
  
  /// Dipanggil saat klien menerima penawaran offer.
  Future<void> respondToAcceptedOffer({
    required String chatId,
    required String agentId,
    required String agentName,
    required int finalPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await chats.sendMessage(
      ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        chatId: chatId,
        senderId: agentId,
        senderName: agentName,
        type: MessageType.text,
        body:
            'Terima kasih! Harga final Rp $finalPrice. Saya akan bekerja maksimal. Silakan pilih saya untuk melanjutkan ke pembayaran.',
        createdAt: DateTime.now(),
      ),
    );
  }
}
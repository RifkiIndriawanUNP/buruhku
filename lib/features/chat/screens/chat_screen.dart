 import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../data/models/message.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String agentId;
  final String agentName;
  final String? requestId;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.agentId,
    required this.agentName,
    this.requestId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _input.text.trim();
    if (txt.isEmpty || _sending) return;
    final user = Services.auth.currentUser!;
    setState(() => _sending = true);
    try {
      await Services.chats.sendMessage(
        ChatMessage(
          id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
          chatId: widget.chatId,
          senderId: user.id,
          senderName: user.fullName,
          type: MessageType.text,
          body: txt,
          createdAt: DateTime.now(),
        ),
      );
      _input.clear();
      // trigger agent reply
      Services.simulator.replyTo(
        chatId: widget.chatId,
        agentId: widget.agentId,
        agentName: widget.agentName,
        clientMessage: txt,
      );
      _jumpToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _acceptOffer(ChatMessage msg) async {
    final user = Services.auth.currentUser!;
    await Services.chats.sendMessage(
      ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}_a',
        chatId: widget.chatId,
        senderId: user.id,
        senderName: user.fullName,
        type: MessageType.system,
        body: 'Anda menyetujui penawaran ${rupiah(msg.offerAmount ?? 0)}',
        createdAt: DateTime.now(),
      ),
    );
    if (msg.offerAmount != null) {
      Services.simulator.respondToAcceptedOffer(
        chatId: widget.chatId,
        agentId: widget.agentId,
        agentName: widget.agentName,
        finalPrice: msg.offerAmount!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (widget.requestId != null)
              const Text('Chat Order',
                  style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: Services.chats.watchMessages(widget.chatId),
              builder: (context, snap) {
                final list = snap.data ?? const <ChatMessage>[];
                _jumpToEnd();
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pesan',
                        style: TextStyle(color: Colors.black54)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final mine = m.senderId == user.id;
                    if (m.type == MessageType.system) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(m.body,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54)),
                          ),
                        ),
                      );
                    }
                    if (m.type == MessageType.offer) {
                      return _OfferBubble(
                        msg: m,
                        mine: mine,
                        onAccept: () => _acceptOffer(m),
                      );
                    }
                    return _Bubble(mine: mine, child: Text(m.body));
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool mine;
  final Widget child;
  const _Bubble({required this.mine, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: mine ? Colors.white : Colors.black87),
          child: child,
        ),
      ),
    );
  }
}

class _OfferBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool mine;
  final VoidCallback onAccept;
  const _OfferBubble({
    required this.msg,
    required this.mine,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text('Penawaran Harga',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 6),
            Text(rupiah(msg.offerAmount ?? 0),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            if (!mine)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: msg.offerStatus == 'accepted' ? null : onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: Text(msg.offerStatus == 'accepted'
                      ? 'Sudah disetujui'
                      : 'Setuju'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
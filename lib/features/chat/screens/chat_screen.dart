import 'package:flutter/material.dart';
import '../../../app/services.dart';
//import '../../../core/utils/rupiah.dart';
import '../../../data/models/message.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String agentId;
  final String agentName;
  final String? requestId;
  const ChatScreen({
    super.key, required this.chatId, required this.title,
    required this.agentId, required this.agentName, this.requestId,
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
      await Services.chats.sendMessage(ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        chatId: widget.chatId, senderId: user.id, senderName: user.fullName,
        type: MessageType.text, body: txt, createdAt: DateTime.now(),
      ));
      _input.clear();
      Services.simulator.replyTo(
        chatId: widget.chatId, agentId: widget.agentId, agentName: widget.agentName, clientMessage: txt,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showBookingDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Pekerjaan')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Harga (Rp)'), keyboardType: TextInputType.number),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Waktu (Cth: Besok Pagi)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = Services.auth.currentUser!;
              final msgId = 'card_${DateTime.now().microsecondsSinceEpoch}';
              
              await Services.chats.sendMessage(ChatMessage(
                id: msgId, chatId: widget.chatId, senderId: user.id, senderName: user.fullName,
                type: MessageType.requestCard, body: 'Pengajuan Booking',
                createdAt: DateTime.now(),
                requestData: {
                  'title': titleCtrl.text,
                  'price': priceCtrl.text,
                  'time': timeCtrl.text,
                  'status': 'pending',
                }
              ));
              
              // Simulasi agen merespon
              Services.simulator.simulateBookingResponse(widget.chatId, msgId, widget.agentId, widget.agentName);
            },
            child: const Text('Kirim'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text('Chat Order', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        actions: [
          // Tombol buat Request Card
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showBookingDialog,
            tooltip: 'Ajukan Booking',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: Services.chats.watchMessages(widget.chatId),
              builder: (context, snap) {
                final list = snap.data ?? const <ChatMessage>[];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
                });
                
                if (list.isEmpty) return const Center(child: Text('Belum ada pesan'));

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final mine = m.senderId == user.id;
                    
                    if (m.type == MessageType.system) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: Text(m.body, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ),
                      );
                    }

                    if (m.type == MessageType.requestCard) {
                      return _RequestCardWidget(
                        msg: m,
                        isClient: mine,
                        onAction: (newStatus) async {
                          Services.chats.updateRequestCardStatus(m.id, newStatus);
                          
                          // Jika di-approve agen, kirim pesan sistem
                          if (newStatus == 'approved') {
                            Services.chats.sendMessage(ChatMessage(
                              id: 'sys_${DateTime.now().microsecondsSinceEpoch}',
                              chatId: widget.chatId, senderId: 'system', senderName: 'Sistem',
                              type: MessageType.system, body: 'Agen menyetujui request Anda. Silakan bayar.',
                              createdAt: DateTime.now(),
                            ));
                          }
                          
                          // Jika dibatalkan agen
                          if (newStatus == 'cancelled') {
                             Services.chats.sendMessage(ChatMessage(
                              id: 'sys_${DateTime.now().microsecondsSinceEpoch}',
                              chatId: widget.chatId, senderId: 'system', senderName: 'Sistem',
                              type: MessageType.system, body: 'Agen membatalkan request.',
                              createdAt: DateTime.now(),
                            ));
                          }
                        },
                      );
                    }

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(m.body, style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                      ),
                    );
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
                  Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: 'Tulis pesan…'))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET CARD REQUEST ---
class _RequestCardWidget extends StatelessWidget {
  final ChatMessage msg;
  final bool isClient;
  final Function(String) onAction;
  
  const _RequestCardWidget({required this.msg, required this.isClient, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final data = msg.requestData ?? {};
    final status = data['status'] ?? 'pending'; 
    
    Color statusColor = status == 'pending' ? Colors.orange 
        : status == 'approved' ? Colors.blue 
        : status == 'paid' ? Colors.purple
        : status == 'completed' ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: statusColor),
              const SizedBox(width: 8),
              const Text('Detail Booking', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12)),
            ],
          ),
          const Divider(),
          Text('Jasa: ${data['title']}'),
          Text('Harga: Rp ${data['price']}'),
          Text('Waktu: ${data['time']}'),
          const SizedBox(height: 12),
          
          if (isClient) ...[
            if (status == 'pending')
              const Text('Menunggu persetujuan agen...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            if (status == 'approved')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onAction('paid'),
                  child: const Text('Bayar Sekarang (Mock)'),
                ),
              ),
            if (status == 'paid')
              const Text('Menunggu agen menyelesaikan pekerjaan...', style: TextStyle(color: Colors.orange, fontSize: 12)),
            if (status == 'completed')
               const Text('Pekerjaan Selesai.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ] else ...[
            if (status == 'pending')
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => onAction('cancelled'), child: const Text('Batalkan'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () => onAction('approved'), child: const Text('Setujui'))),
                ],
              ),
            if (status == 'paid')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => onAction('completed'),
                  child: const Text('Selesaikan Pekerjaan'),
                ),
              ),
          ]
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/acceptance.dart';
import '../../../data/models/job_request.dart';
import '../../../data/models/order.dart';
import '../../order/screens/order_detail_screen.dart';

class PaymentScreen extends StatefulWidget {
  final JobRequest request;
  final Acceptance acceptance;
  const PaymentScreen({
    super.key,
    required this.request,
    required this.acceptance,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'QRIS';
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final user = Services.auth.currentUser!;
      final platformFee =
          (widget.acceptance.proposedPrice * Env.platformFeePct).round();
      final order = Order(
        id: 'ord_${DateTime.now().microsecondsSinceEpoch}',
        requestId: widget.request.id,
        clientId: user.id,
        agentId: widget.acceptance.agentId,
        agentName: widget.acceptance.agentName,
        title: widget.request.title,
        agreedPrice: widget.acceptance.proposedPrice,
        platformFee: platformFee,
        jobPin: (1000 + DateTime.now().microsecond % 9000).toString(),
        createdAt: DateTime.now(),
      );
      await Services.orders.create(order);
      await Services.orders.payEscrow(order.id);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.acceptance.proposedPrice;
    final fee = (price * Env.platformFeePct).round();
    final total = price + fee;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _kv('Agen', widget.acceptance.agentName),
                _kv('Pekerjaan', widget.request.title),
                const Divider(height: 20),
                _kv('Harga kesepakatan', rupiah(price)),
                _kv('Biaya layanan (10%)', rupiah(fee)),
                const Divider(height: 20),
                _kv('Total bayar', rupiah(total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...['QRIS', 'Virtual Account', 'E-Wallet'].map(
            (m) => RadioListTile<String>(
              value: m,
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              title: Text(m),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          AppBox(
            color: const Color(0xFFEAF5EA),
            border: Border.all(color: const Color(0xFFBFE3BF)),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dana Anda ditahan oleh sistem (escrow). Baru dilepas ke agen setelah Anda konfirmasi pekerjaan selesai.',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _pay,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Bayar ${rupiah(total)}'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                    color: Colors.black87)),
          ),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
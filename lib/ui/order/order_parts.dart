import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/ui.dart';

/// Bagian-bagian halaman detail order (tahapan, baris info, riwayat).

/// Tahapan order: garis hijau yang mengisi sampai tahap sekarang.
class OrderStepper extends StatelessWidget {
  final int step;
  final List<String> names;
  const OrderStepper({required this.step, required this.names, super.key});

  Widget _seg(bool visible, bool on) => Container(height: 3, color: !visible ? Colors.transparent : (on ? kGreen : kLine));

  Widget _dot(int i) {
    if (i < step) {
      return Container(width: 20, height: 20, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle), child: const Icon(Icons.check, size: 14, color: Colors.white));
    }
    if (i == step) {
      return Container(width: 22, height: 22, decoration: BoxDecoration(color: cW, shape: BoxShape.circle, border: Border.all(color: kGreen, width: 3.5)));
    }
    return Container(width: 14, height: 14, decoration: const BoxDecoration(color: kLine, shape: BoxShape.circle));
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < names.length; i++)
          Expanded(
            child: Column(children: [
              SizedBox(
                height: 22,
                child: Row(children: [
                  Expanded(child: _seg(i > 0, i <= step)),
                  _dot(i),
                  Expanded(child: _seg(i < names.length - 1, i < step)),
                ]),
              ),
              const SizedBox(height: 4),
              Text(names[i], maxLines: 1, style: TextStyle(fontSize: 11, fontWeight: i == step ? FontWeight.w800 : FontWeight.w500, color: i <= step ? g900 : g500)),
            ]),
          ),
      ]);
}

/// Baris info dengan ikon: label kecil di atas, nilai di bawah.
class OrderLine extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const OrderLine(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: g700)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: g500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, color: g900)),
          ]),
        ),
      ]);
}

/// Satu baris rincian harga.
class PayRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const PayRow(this.label, this.value, {this.bold = false, super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: bold ? 15 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? g900 : g700))),
          Text(value, style: TextStyle(fontSize: bold ? 19 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: g900)),
        ]),
      );
}

/// Riwayat kejadian berbentuk garis waktu. [log] berisi "waktu-iso|teks", terbaru di atas.
class OrderTimeline extends StatelessWidget {
  final List<String> log;
  const OrderTimeline(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = log.reversed.toList();
    return Column(children: [
      for (var i = 0; i < l.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 18,
              child: Column(children: [
                Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: i == 0 ? kGreen : g400, shape: BoxShape.circle)),
                if (i < l.length - 1) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: kLine)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: i < l.length - 1 ? 12 : 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l[i].split('|').sublist(1).join('|'), style: const TextStyle(fontSize: 13, height: 1.3, color: g900)),
                  const SizedBox(height: 2),
                  Text(ftime(DateTime.parse(l[i].split('|').first)), style: const TextStyle(fontSize: 12, color: g500)),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

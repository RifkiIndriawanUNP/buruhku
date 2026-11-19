import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/utils/geo.dart';

/// Kartu-kartu pesan di chat. Rata dan ringkas: ikon, angka utama, status berupa pil kecil.
/// Hanya UI. Aksi (setuju, tawar, dst.) diberikan dari luar lewat [actions].

const _w = 250.0;

class MsgCard extends StatelessWidget {
  final double width;
  final EdgeInsetsGeometry padding;
  final Widget child;
  const MsgCard({required this.child, this.width = _w, this.padding = const EdgeInsets.all(12), super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(22)),
        child: child,
      );
}

/// Lingkaran ikon berwarna di kiri kartu.
class _IconDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconDot(this.icon, this.color, {this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .32)),
        child: Icon(icon, size: size * .55, color: Colors.white),
      );
}

/// Status penawaran: menunggu, disepakati, ditolak, ditawar balik.
class OfferStatusPill extends StatelessWidget {
  final String status;
  const OfferStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'accepted' => ('Disepakati', kOkBg, kOkFg),
      'rejected' => ('Ditolak', kBadBg, kBadFg),
      'countered' => ('Ditawar balik', kInfoBg, kInfoFg),
      _ => ('Menunggu', kWaitBg, kWaitFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.1, color: fg)),
    );
  }
}

Widget _price(int price, String ptype, {double size = 24}) {
  final unit = unitOf(ptype);
  return Text.rich(TextSpan(
    text: rp(price),
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1.15, color: g900),
    children: [if (unit.isNotEmpty) TextSpan(text: unit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: g500))],
  ));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: g500),
        const SizedBox(width: 8),
        Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.3, color: g700))),
      ]);
}

/// Penawaran harga (tawar-menawar di chat order).
class PriceOfferCard extends StatelessWidget {
  final int price;
  final String ptype;
  final String status;
  final Widget? actions;
  const PriceOfferCard({required this.price, required this.ptype, required this.status, this.actions, super.key});

  @override
  Widget build(BuildContext context) => MsgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const _IconDot(Icons.sell_outlined, kGreen, size: 34),
            const SizedBox(width: 8),
            Expanded(child: Text(ptypes[ptype] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: g500))),
            OfferStatusPill(status),
          ]),
          const SizedBox(height: 12),
          _price(price, ptype, size: 26),
          if (actions != null) ...[const SizedBox(height: 12), actions!],
        ]),
      );
}

/// Penawaran order lengkap: pekerjaan, waktu, lokasi, harga.
class OrderOfferCard extends StatelessWidget {
  final Map<String, dynamic> d;
  final String status;
  final Widget? actions;
  const OrderOfferCard({required this.d, required this.status, this.actions, super.key});

  @override
  Widget build(BuildContext context) {
    final catId = d['cat'] as String?;
    final when = (d['when'] ?? '').toString();
    final addr = (d['address'] ?? '').toString();
    return MsgCard(
      width: 270,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          catId != null ? CatIcon(catOf(catId), size: 42) : const _IconDot(Icons.assignment_outlined, kGreen, size: 42),
          const SizedBox(width: 8),
          Expanded(child: Text((d['title'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
          const SizedBox(width: 8),
          OfferStatusPill(status),
        ]),
        if (when.isNotEmpty || addr.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (when.isNotEmpty) _InfoRow(Icons.schedule, when),
          if (when.isNotEmpty && addr.isNotEmpty) const SizedBox(height: 6),
          if (addr.isNotEmpty) _InfoRow(Icons.place_outlined, addr),
        ],
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 1, color: kLine)),
        _price(d['price'] as int, d['ptype'] as String, size: 22),
        if (actions != null) ...[const SizedBox(height: 12), actions!],
      ]),
    );
  }
}

/// Kontak WhatsApp yang dibagikan.
class ContactMsgCard extends StatelessWidget {
  final String number;
  final VoidCallback? onOpen;
  const ContactMsgCard({required this.number, this.onOpen, super.key});

  @override
  Widget build(BuildContext context) => MsgCard(
        width: 230,
        child: Row(children: [
          const _IconDot(Icons.phone, Color(0xFF25D366)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WhatsApp', style: TextStyle(fontSize: 12, color: g500)),
              Text(number, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: g900)),
            ]),
          ),
          if (onOpen != null) IconButton(onPressed: onOpen, visualDensity: VisualDensity.compact, icon: const Icon(Icons.open_in_new, size: 20, color: kGreen)),
        ]),
      );
}

/// E-wallet yang dibagikan. Nomor disamarkan untuk penerima sampai ikon mata diketuk.
class WalletMsgCard extends StatelessWidget {
  final String name, number, purpose;
  final bool mine, revealed;
  final VoidCallback onToggle;
  const WalletMsgCard({required this.name, required this.number, required this.purpose, required this.mine, required this.revealed, required this.onToggle, super.key});

  @override
  Widget build(BuildContext context) {
    final masked = number.length > 4 ? '${'\u2022' * (number.length - 4)}${number.substring(number.length - 4)}' : number;
    return MsgCard(
      width: 240,
      child: Row(children: [
        const _IconDot(Icons.account_balance_wallet_outlined, Color(0xFF4C6EF5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: g900)),
            const SizedBox(height: 2),
            Text(mine || revealed ? number : masked, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: .5, color: g700)),
            if (purpose.isNotEmpty) ...[const SizedBox(height: 6), Tag(purpose)],
          ]),
        ),
        if (!mine) IconButton(onPressed: onToggle, visualDensity: VisualDensity.compact, icon: Icon(revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: g500)),
      ]),
    );
  }
}

/// Foto yang dikirim. Ketuk untuk memperbesar.
class ImageMsgCard extends StatelessWidget {
  final String? path;
  const ImageMsgCard({required this.path, super.key});

  @override
  Widget build(BuildContext context) {
    final p = path;
    return GestureDetector(
      onTap: (p == null || p.isEmpty) ? null : () => showPhotoViewer(context, [p]),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: TempPhoto(path: p, w: 220, h: 165)),
    );
  }
}

/// Lokasi yang dibagikan: peta kecil dan alamat. Ketuk untuk membuka peta penuh.
class LocationMsgCard extends StatelessWidget {
  final String address;
  const LocationMsgCard({required this.address, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapFullPage(pin: kMapCenter, title: address))),
        child: MsgCard(
          width: 240,
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppMap(height: 118, pin: kMapCenter, zoom: 15, interactive: false, framed: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                const Icon(Icons.place, size: 18, color: kGreen),
                const SizedBox(width: 6),
                Expanded(child: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.3, color: g900))),
                Icon(Icons.chevron_right, size: 20, color: g500),
              ]),
            ),
          ]),
        ),
      );
}

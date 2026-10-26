import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';

IconData placeIcon(String label) {
  final t = label.toLowerCase();
  if (t.contains('rumah')) return Icons.home_outlined;
  if (t.contains('kantor') || t.contains('kerja')) return Icons.business_outlined;
  return Icons.place_outlined;
}

const _maxPlaces = 10;

/// Pemilih lokasi: chip lokasi tersimpan, titik di peta, atau ketik alamat manual.
/// Dipakai di form request dan form order langsung.
class LocationField extends StatefulWidget {
  final TextEditingController addr;
  final Offset pin;
  final ValueChanged<Offset> onPin;
  final double mapH;
  const LocationField({required this.addr, required this.pin, required this.onPin, this.mapH = 150, super.key});
  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  String? sel;

  @override
  void initState() {
    super.initState();
    final t = widget.addr.text.trim();
    if (t.isNotEmpty) {
      for (final p in context.r.places) {
        if (p.address == t) sel = p.id;
      }
    }
  }

  Future<void> _save(AppStore s) async {
    final addr = widget.addr.text.trim();
    if (addr.isEmpty) {
      toast(context, 'Isi alamat dulu sebelum menyimpan.');
      return;
    }
    if (s.places.length >= _maxPlaces) {
      toast(context, 'Maksimal $_maxPlaces lokasi tersimpan.');
      return;
    }
    final label = await askText(context, 'Nama lokasi', hint: 'mis. Rumah, Kantor, Rumah Ibu');
    if (label == null || label.isEmpty || !mounted) return;
    s.addPlace(label, addr, widget.pin);
    setState(() => sel = s.places.last.id);
    toast(context, 'Lokasi "$label" disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lokasi pekerjaan', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (s.places.isEmpty)
        const Text('Belum ada lokasi tersimpan. Simpan lokasi di bawah atau lewat Akun > Profil dan alamat.', style: TextStyle(fontSize: 12.5, color: g500))
      else
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final p in s.places)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(placeIcon(p.label), size: 16),
                  label: Text(p.label),
                  selected: sel == p.id,
                  onSelected: (_) {
                    setState(() => sel = p.id);
                    widget.addr.text = p.address;
                    widget.onPin(Offset(p.lat, p.lng));
                  },
                ),
              ),
          ]),
        ),
      const SizedBox(height: 10),
      FakeMap(
        h: widget.mapH,
        pin: widget.pin,
        onTap: (o) {
          setState(() => sel = null);
          widget.onPin(o);
        },
      ),
      const SizedBox(height: 8),
      TF('Alamat lengkap (ketik manual atau pilih titik peta)', widget.addr, lines: 2,
          validator: (v) => (v ?? '').trim().isEmpty ? 'Alamat wajib diisi' : null,
          onChanged: (_) {
            if (sel != null) setState(() => sel = null);
          },
          suffix: IconButton(
            tooltip: 'Lokasi saya',
            icon: const Icon(Icons.my_location),
            onPressed: () {
              widget.addr.text = s.address.isEmpty ? 'Jl. Melati No. 5, Palabuhanratu' : s.address;
              widget.onPin(const Offset(.5, .5));
              setState(() => sel = null);
            },
          )),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: () => _save(s), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('Simpan lokasi ini')),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- lokasi tersimpan (bagian dari detail profil)
class SavedPlacesSection extends StatelessWidget {
  const SavedPlacesSection({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Section('Lokasi tersimpan', action: 'Tambah', onAction: () {
        if (s.places.length >= _maxPlaces) {
          toast(context, 'Maksimal $_maxPlaces lokasi tersimpan.');
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceEditPage()));
      }),
      if (s.places.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Belum ada lokasi tersimpan. Simpan rumah, kantor, atau tempat lain agar cepat dipilih saat membuat request atau order.', style: TextStyle(color: g500, fontSize: 12.5)),
        ),
      for (final p in s.places)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Box(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(placeIcon(p.label), size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 6),
                    if (s.address == p.address) const Tag('Utama'),
                  ]),
                  const SizedBox(height: 2),
                  Text(p.address, style: const TextStyle(color: g700, fontSize: 12.5)),
                ]),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceEditPage(place: p)));
                  } else if (v == 'main') {
                    s.address = p.address;
                    s.notifyListeners();
                    toast(context, '"${p.label}" jadi alamat utama.');
                  } else if (v == 'del') {
                    if (await confirm(context, 'Hapus lokasi?', '"${p.label}" akan dihapus dari daftar lokasi tersimpan.', ok: 'Hapus')) s.deletePlace(p);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'main', child: Text('Jadikan alamat utama')),
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(value: 'del', child: Text('Hapus')),
                ],
              ),
            ]),
          ),
        ),
    ]);
  }
}

class PlaceEditPage extends StatefulWidget {
  final SavedLoc? place;
  const PlaceEditPage({this.place, super.key});
  @override
  State<PlaceEditPage> createState() => _PlaceEditPageState();
}

class _PlaceEditPageState extends State<PlaceEditPage> {
  late final label = TextEditingController(text: widget.place?.label ?? '');
  late final addr = TextEditingController(text: widget.place?.address ?? '');
  late Offset pin = widget.place == null ? const Offset(.5, .5) : Offset(widget.place!.lat, widget.place!.lng);
  final key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.place == null ? 'Tambah lokasi' : 'Ubah lokasi')),
        body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TF('Nama lokasi', label, maxLen: 30, validator: (v) => (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null),
            Wrap(spacing: 8, children: [
              for (final l in ['Rumah', 'Kantor', 'Rumah keluarga'])
                ActionChip(avatar: Icon(placeIcon(l), size: 16), label: Text(l), onPressed: () => setState(() => label.text = l)),
            ]),
            const SizedBox(height: 14),
            const Text('Titik di peta', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            FakeMap(h: 170, pin: pin, onTap: (o) => setState(() => pin = o)),
            const SizedBox(height: 12),
            TF('Alamat lengkap', addr, lines: 2, validator: (v) => (v ?? '').trim().isEmpty ? 'Alamat wajib diisi' : null,
                suffix: IconButton(icon: const Icon(Icons.my_location), onPressed: () => setState(() => addr.text = context.r.address.isEmpty ? 'Jl. Melati No. 5, Palabuhanratu' : context.r.address))),
            const SizedBox(height: 8),
            full(pbtn('Simpan', () {
              if (!key.currentState!.validate()) return;
              final s = context.r;
              if (widget.place == null) {
                s.addPlace(label.text.trim(), addr.text.trim(), pin);
              } else {
                s.updatePlace(widget.place!, label.text.trim(), addr.text.trim(), pin);
              }
              Navigator.pop(context);
              toast(context, 'Lokasi disimpan.');
            })),
          ]),
        ),
      );
}

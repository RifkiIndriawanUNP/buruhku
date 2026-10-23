import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/job_request.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController(text: 'Jl. Demo No. 1, Jakarta');
  final _price = TextEditingController(text: '150000');
  final _workers = TextEditingController(text: '1');
  String _category = 'cleaning';
  PriceType _priceType = PriceType.lumpSum;
  bool _loading = false;

  static const _cats = {
    'cleaning': 'Bersih-bersih',
    'repair': 'Perbaikan Ringan',
    'moving': 'Angkat & Pindah',
    'garden': 'Taman & Halaman',
    'laundry': 'Setrika / Laundry',
    'pickup': 'Antar-Jemput',
    'other': 'Lain-lain',
  };

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = Services.auth.currentUser!;
      final req = JobRequest(
        id: 'req_${DateTime.now().microsecondsSinceEpoch}',
        clientId: user.id,
        categoryId: _category,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        address: _address.text.trim(),
        lat: Env.demoLat,
        lng: Env.demoLng,
        workersNeeded: int.parse(_workers.text.trim()),
        priceType: _priceType,
        offeredPrice: int.parse(_price.text.replaceAll('.', '')),
        acceptQuota: Env.acceptQuota,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      await Services.requests.create(req);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request dibuat. Agen akan segera menyetujui.'),
          backgroundColor: Colors.green,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Request')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Judul Jasa',
                hintText: 'Contoh: Bersihkan halaman belakang',
              ),
              validator: (v) => requiredValidator(v, 'Judul wajib diisi'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: _cats.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Detail pekerjaan, alat yang perlu dibawa, dll.',
              ),
              validator: (v) => minLenValidator(v, 20, 'Deskripsi terlalu pendek'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => requiredValidator(v, 'Alamat wajib diisi'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _workers,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah buruh',
                    ),
                    validator: (v) => positiveIntValidator(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<PriceType>(
                    initialValue: _priceType,
                    decoration: const InputDecoration(labelText: 'Tipe harga'),
                    items: PriceType.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.label),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _priceType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga penawaran (Rp)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) => positiveIntValidator(v, 'Harga wajib > 0'),
            ),
            const SizedBox(height: 6),
            Text(
              'Rekomendasi harga wajar: ${rupiah(150000)} – ${rupiah(300000)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kirim Request'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
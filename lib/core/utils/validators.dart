String? requiredValidator(String? v, [String label = 'Wajib diisi']) {
  if (v == null || v.trim().isEmpty) return label;
  return null;
}

String? minLenValidator(String? v, int min, [String label = 'Terlalu pendek']) {
  if (v == null || v.trim().length < min) return '$label (min. $min karakter)';
  return null;
}

String? phoneValidator(String? v) {
  if (v == null) return 'Wajib diisi';
  final t = v.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  if (!RegExp(r'^(\+62|62|0)8\d{7,13}$').hasMatch(t)) {
    return 'Format nomor HP tidak valid';
  }
  return null;
}

String? positiveIntValidator(String? v, [String label = 'Harus angka > 0']) {
  final n = int.tryParse((v ?? '').replaceAll('.', ''));
  if (n == null || n <= 0) return label;
  return null;
}
import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/input_formatters.dart';

// ---------- dialog & toast ----------
void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

Future<bool> confirm(BuildContext c, String title, String msg, {String ok = 'Ya', String cancel = 'Batal'}) async {
  final r = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(title: Text(title), content: Text(msg), actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(cancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(ok)),
          ]));
  return r == true;
}

Future<void> info(BuildContext c, String title, String msg) => showDialog<void>(
    context: c,
    builder: (d) => AlertDialog(title: Text(title), content: Text(msg), actions: [
          FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Mengerti')),
        ]));

Future<String?> askText(BuildContext c, String title, {String hint = '', bool number = false, bool obscure = false, int lines = 1, bool money = false}) {
  final ctl = TextEditingController();
  return showDialog<String>(
      context: c,
      builder: (d) => AlertDialog(
              title: Text(title),
              content: TextField(
                  controller: ctl, autofocus: true, obscureText: obscure, maxLines: obscure ? 1 : lines,
                  keyboardType: (number || money) ? TextInputType.number : TextInputType.text,
                  inputFormatters: money ? [MoneyFormatter()] : null, decoration: InputDecoration(hintText: hint)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
                FilledButton(onPressed: () => Navigator.pop(d, ctl.text.trim()), child: const Text('OK')),
              ]));
}

Future<T?> sheet<T>(BuildContext c, Widget Function(BuildContext) b) => showModalBottomSheet<T>(
    context: c, isScrollControlled: true, showDragHandle: true,
    builder: (x) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(x).viewInsets.bottom), child: b(x)));

/// Memilih tanggal lalu jam. Mengembalikan null jika dibatalkan.
Future<DateTime?> pickDateTime(BuildContext c, {DateTime? initial}) async {
  final now = DateTime.now();
  final start = (initial != null && initial.isAfter(now)) ? initial : now;
  final d = await showDatePicker(context: c, initialDate: start, firstDate: now, lastDate: now.add(const Duration(days: 60)));
  if (d == null || !c.mounted) return null;
  final t = await showTimePicker(context: c, initialTime: TimeOfDay.fromDateTime(initial != null && initial.isAfter(now) ? initial : now.add(const Duration(hours: 2))));
  if (t == null) return null;
  return DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

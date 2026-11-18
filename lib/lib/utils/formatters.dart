// Format angka, uang, tanggal, dan waktu. Dart murni (tanpa Flutter),
// jadi boleh dipakai oleh lapisan data maupun UI.
String rp(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp$b';
}

String fmtNum(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$b';
}

int money(String s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0;


String two(int n) => n.toString().padLeft(2, '0');
const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fdate(DateTime d) => '${d.day} ${_bln[d.month - 1]} ${d.year}';
String ftime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String fdt(DateTime d) => '${fdate(d)}, ${ftime(d)}';
String ago(DateTime d) {
  final s = DateTime.now().difference(d);
  if (s.inSeconds < 60) return 'baru saja';
  if (s.inMinutes < 60) return '${s.inMinutes} mnt lalu';
  if (s.inHours < 24) return '${s.inHours} jam lalu';
  return '${s.inDays} hari lalu';
}

String clock(Duration d) {
  if (d.isNegative) d = Duration.zero;
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

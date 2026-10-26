import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------- palet grayscale ----------
const cW = Colors.white;
const g50 = Color(0xFFF7F7F7);
const g100 = Color(0xFFEFEFEF);
const g200 = Color(0xFFDDDDDD);
const g300 = Color(0xFFC2C2C2);
const g400 = Color(0xFFA3A3A3);
const g500 = Color(0xFF808080);
const g700 = Color(0xFF4A4A4A);
const g900 = Color(0xFF1C1C1C);

ThemeData buildTheme() {
  final b = OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: g300));
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
        primary: g900, onPrimary: cW, secondary: g700, onSecondary: cW, surface: cW, onSurface: g900,
        error: g900, onError: cW, outline: g300, outlineVariant: g200,
        primaryContainer: g200, onPrimaryContainer: g900, secondaryContainer: g200, onSecondaryContainer: g900),
    scaffoldBackgroundColor: cW,
    appBarTheme: const AppBarTheme(
        backgroundColor: cW, foregroundColor: g900, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        surfaceTintColor: Colors.transparent, shape: Border(bottom: BorderSide(color: g200)),
        titleTextStyle: TextStyle(color: g900, fontSize: 18, fontWeight: FontWeight.w600)),
    inputDecorationTheme: InputDecorationTheme(
        border: b, enabledBorder: b, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        focusedBorder: b.copyWith(borderSide: const BorderSide(color: g900, width: 1.5)),
        errorBorder: b.copyWith(borderSide: const BorderSide(color: g700)),
        focusedErrorBorder: b.copyWith(borderSide: const BorderSide(color: g900, width: 1.5)),
        labelStyle: const TextStyle(color: g500), errorStyle: const TextStyle(color: g700)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: g900, foregroundColor: cW, minimumSize: const Size(64, 46), shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: g900, side: const BorderSide(color: g900), minimumSize: const Size(64, 46), shape: shape)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: g900)),
    dividerTheme: const DividerThemeData(color: g200, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: cW, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(backgroundColor: g900, contentTextStyle: TextStyle(color: cW), behavior: SnackBarBehavior.floating),
  );
}

// ---------- format ----------
String rp(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp$b';
}

/// Angka dengan pemisah titik ribuan, tanpa 'Rp' (mis. 1.000.000).
String fmtNum(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$b';
}

/// Mengubah teks input uang ("1.000.000") menjadi angka.
int money(String s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0;

/// Memformat input angka otomatis dengan titik ribuan saat mengetik.
class MoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return const TextEditingValue(text: '');
    if (d.length > 12) d = d.substring(0, 12);
    final t = fmtNum(int.parse(d));
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

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

// ---------- widget dasar ----------
class Box extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color, border;
  final double radius;
  const Box({required this.child, this.onTap, this.padding = const EdgeInsets.all(12), this.color, this.border, this.radius = 8});
  @override
  Widget build(BuildContext context) => Material(
      color: color ?? cW,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: border ?? g300)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)));
}

class _Cross extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = g300..strokeWidth = 1;
    c.drawLine(Offset.zero, Offset(s.width, s.height), p);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class Ph extends StatelessWidget {
  final double? w, h;
  final IconData icon;
  final double radius;
  const Ph({this.w, this.h, this.icon = Icons.image_outlined, this.radius = 6});
  @override
  Widget build(BuildContext context) => Container(
      width: w, height: h, clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: g100, border: Border.all(color: g300), borderRadius: BorderRadius.circular(radius)),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: CustomPaint(painter: _Cross())),
        Container(color: g100, padding: const EdgeInsets.all(2), child: Icon(icon, color: g500)),
      ]));
}

class Avatar extends StatelessWidget {
  final double size;
  final IconData icon;
  const Avatar({this.size = 44, this.icon = Icons.person_outline});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: g200, border: Border.all(color: g400)),
      child: Icon(icon, size: size * .55, color: g700));
}

class Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool filled;
  const Tag(this.text, {this.icon, this.filled = false});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: filled ? g900 : cW, border: Border.all(color: filled ? g900 : g400), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 3), child: Icon(icon, size: 12, color: filled ? cW : g700)),
        Text(text, style: TextStyle(fontSize: 11, color: filled ? cW : g700)),
      ]));
}

class Stars extends StatelessWidget {
  final double r;
  final double size;
  const Stars(this.r, {this.size = 14});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(r >= i - 0.25 ? Icons.star : (r >= i - 0.75 ? Icons.star_half : Icons.star_border), size: size, color: g700),
      ]);
}

class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarPicker(this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(iconSize: 36, onPressed: () => onChanged(i), icon: Icon(i <= value ? Icons.star : Icons.star_border, color: g900)),
      ]);
}

class Section extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const Section(this.title, {this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]));
}

class Kv extends StatelessWidget {
  final String k, v;
  final bool bold;
  const Kv(this.k, this.v, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 4, child: Text(k, style: const TextStyle(color: g500))),
        Expanded(flex: 6, child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
      ]));
}

class Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const Empty(this.icon, this.text, {this.action});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: g300),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: g500)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ])));
}

class Warn extends StatelessWidget {
  final String text;
  final IconData icon;
  const Warn(this.text, {this.icon = Icons.warning_amber_outlined});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: g100, border: Border.all(color: g400), borderRadius: BorderRadius.circular(6)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: g700),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: g700))),
      ]));
}

class TF extends StatelessWidget {
  final String label;
  final TextEditingController ctl;
  final int lines;
  final int? maxLen;
  final TextInputType? type;
  final String? hint, prefix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscure, enabled, money;
  final Widget? suffix;
  const TF(this.label, this.ctl, {this.lines = 1, this.maxLen, this.type, this.hint, this.prefix, this.validator,
      this.onChanged, this.obscure = false, this.enabled = true, this.suffix, this.money = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
          controller: ctl, maxLines: obscure ? 1 : lines, maxLength: maxLen, keyboardType: money ? TextInputType.number : type, validator: validator,
          inputFormatters: money ? [MoneyFormatter()] : null,
          onChanged: onChanged, obscureText: obscure, enabled: enabled,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixText: prefix, suffixIcon: suffix, counterText: '')));
}

Widget pbtn(String label, VoidCallback? f, {IconData? icon}) =>
    icon == null ? FilledButton(onPressed: f, child: Text(label)) : FilledButton.icon(onPressed: f, icon: Icon(icon, size: 18), label: Text(label));
Widget obtn(String label, VoidCallback? f, {IconData? icon}) =>
    icon == null ? OutlinedButton(onPressed: f, child: Text(label)) : OutlinedButton.icon(onPressed: f, icon: Icon(icon, size: 18), label: Text(label));
Widget full(Widget w) => SizedBox(width: double.infinity, child: w);

class Seg extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const Seg(this.options, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Row(children: [
        for (final e in options.entries)
          Expanded(
              child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                      alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 11),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: e.key == value ? g900 : cW, border: Border.all(color: e.key == value ? g900 : g300), borderRadius: BorderRadius.circular(6)),
                      child: Text(e.value, style: TextStyle(fontSize: 13, color: e.key == value ? cW : g900, fontWeight: FontWeight.w600))))),
      ]);
}

class Counter extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const Counter(this.value, this.min, this.max, this.onChanged);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton.outlined(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)),
        SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        IconButton.outlined(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add)),
      ]);
}

// ---------- peta & QR palsu (wireframe) ----------
class _Grid extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = g200..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 28) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (var y = 0.0; y < s.height; y += 28) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
    final r = Paint()..color = g300..strokeWidth = 5..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, s.height * .65), Offset(s.width, s.height * .35), r);
    c.drawLine(Offset(s.width * .3, 0), Offset(s.width * .55, s.height), r);
  }

  @override
  bool shouldRepaint(_) => false;
}

class FakeMap extends StatelessWidget {
  final double h;
  final Offset? pin;
  final ValueChanged<Offset>? onTap;
  final List<Offset> marks;
  const FakeMap({this.h = 170, this.pin, this.onTap, this.marks = const []});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final w = box.maxWidth;
        return GestureDetector(
            onTapDown: onTap == null ? null : (d) => onTap!(Offset((d.localPosition.dx / w).clamp(0.0, 1.0), (d.localPosition.dy / h).clamp(0.0, 1.0))),
            child: Container(
                height: h, clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: g100, border: Border.all(color: g300), borderRadius: BorderRadius.circular(8)),
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _Grid())),
                  for (final m in marks) Positioned(left: m.dx * w - 12, top: m.dy * h - 24, child: const Icon(Icons.directions_walk, size: 24, color: g700)),
                  if (pin != null) Positioned(left: pin!.dx * w - 14, top: pin!.dy * h - 28, child: const Icon(Icons.location_on, size: 28, color: g900)),
                  if (onTap != null) const Positioned(right: 8, bottom: 6, child: Text('Ketuk peta untuk pasang pin', style: TextStyle(fontSize: 10, color: g500))),
                ])));
      });
}

class _Qr extends CustomPainter {
  final int seed;
  _Qr(this.seed);
  @override
  void paint(Canvas c, Size s) {
    final r = Random(seed);
    const n = 25;
    final cell = s.width / n;
    final p = Paint()..color = g900;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final tl = i < 7 && j < 7, tr = i < 7 && j >= n - 7, bl = i >= n - 7 && j < 7;
        bool on;
        if (tl || tr || bl) {
          final a = i >= n - 7 ? i - (n - 7) : i, b = j >= n - 7 ? j - (n - 7) : j;
          on = a == 0 || a == 6 || b == 0 || b == 6 || (a >= 2 && a <= 4 && b >= 2 && b <= 4);
        } else {
          on = r.nextBool();
        }
        if (on) {
          c.drawRect(Rect.fromLTWH(i * cell, j * cell, cell, cell), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class FakeQr extends StatelessWidget {
  final int seed;
  const FakeQr(this.seed);
  @override
  Widget build(BuildContext context) => Container(
      width: 180, height: 180, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cW, border: Border.all(color: g900)),
      child: CustomPaint(painter: _Qr(seed)));
}

// ---------- bottom bar ----------
class BarItem {
  final IconData icon;
  final String label;
  final int badge;
  const BarItem(this.icon, this.label, [this.badge = 0]);
}

class BottomBar extends StatelessWidget {
  final int index;
  final List<BarItem> items;
  final int? center;
  final ValueChanged<int> onTap;
  const BottomBar({required this.index, required this.items, required this.onTap, this.center});
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(color: cW, border: Border(top: BorderSide(color: g300))),
      child: SafeArea(
          top: false,
          child: SizedBox(
              height: 62,
              child: Row(children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                      child: InkWell(
                          onTap: () => onTap(i),
                          child: i == center
                              ? Center(
                                  child: Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(color: g900, borderRadius: BorderRadius.circular(8), border: Border.all(color: g900, width: i == index ? 3 : 0)),
                                      child: Icon(items[i].icon, color: cW)))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Badge(
                                      isLabelVisible: items[i].badge > 0, label: Text('${items[i].badge}'), backgroundColor: g900,
                                      child: Icon(items[i].icon, color: i == index ? g900 : g400, size: 24)),
                                  const SizedBox(height: 3),
                                  Text(items[i].label, style: TextStyle(fontSize: 11, color: i == index ? g900 : g500, fontWeight: i == index ? FontWeight.w700 : FontWeight.w400)),
                                ]))),
              ]))));
}

/// Membangun ulang tiap detik (untuk countdown / timer).
class Live extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  const Live(this.builder, {super.key});
  @override
  State<Live> createState() => _LiveState();
}

class _LiveState extends State<Live> {
  late final Stream<int> _s = Stream.periodic(const Duration(seconds: 1), (i) => i);
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(stream: _s, builder: (c, _) => widget.builder(c));
}

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

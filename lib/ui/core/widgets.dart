import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/ui/core/input_formatters.dart';

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

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
  const Box({required this.child, this.onTap, this.padding = const EdgeInsets.all(14), this.color, this.border, this.radius = 20});
  @override
  Widget build(BuildContext context) {
    // Kotak abu-abu lama (g50/g100) diganti putih supaya terbaca di atas latar abu-abu halaman.
    final fill = (color == null || color == g100 || color == g50) ? cW : color!;
    return Material(
        color: fill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: border == null ? BorderSide.none : BorderSide(color: border!)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)));
  }
}

class Ph extends StatelessWidget {
  final double? w, h;
  final IconData icon;
  final double radius;
  final String? imageUrl;
  const Ph({this.w, this.h, this.icon = Icons.image_outlined, this.radius = 14, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(imageUrl!, width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
      width: w, height: h, alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFE4E5E9), borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: const Color(0xFFB4B6BE)));
}

class Avatar extends StatelessWidget {
  final double size;
  final IconData icon;
  final String? imageUrl;
  const Avatar({this.size = 44, this.icon = Icons.person, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
      width: size, height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDADADA)),
      child: Icon(icon, size: size * .55, color: const Color(0xFFAEB0B8)));
}

class Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool filled;
  const Tag(this.text, {this.icon, this.filled = false});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: filled ? kGreen : const Color(0xFFEDEEF2), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(icon, size: 13, color: filled ? cW : g700)),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: filled ? cW : g700))),
      ]));
}

class Stars extends StatelessWidget {
  final double r;
  final double size;
  const Stars(this.r, {this.size = 14});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(r >= i - 0.25 ? Icons.star : (r >= i - 0.75 ? Icons.star_half : Icons.star_border), size: size, color: const Color(0xFF1A2B5F)),
      ]);
}

class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarPicker(this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(iconSize: 36, onPressed: () => onChanged(i), icon: Icon(i <= value ? Icons.star : Icons.star_border, color: const Color(0xFF1A2B5F))),
      ]);
}

class Section extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const Section(this.title, {this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
        if (action != null) TextButton(onPressed: onAction, style: TextButton.styleFrom(foregroundColor: kGreen), child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700))),
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
            Container(width: 84, height: 84, decoration: const BoxDecoration(color: cW, shape: BoxShape.circle), child: Icon(icon, size: 40, color: g300)),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: g500, height: 1.4)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ])));
}

class Warn extends StatelessWidget {
  final String text;
  final IconData icon;
  const Warn(this.text, {this.icon = Icons.warning_amber_rounded});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF4E0), borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: const Color(0xFFF08A00)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.35, color: g700))),
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
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: e.key == value ? kGreen : cW, border: Border.all(color: e.key == value ? kGreen : kLine), borderRadius: BorderRadius.circular(24)),
                      child: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: e.key == value ? cW : g900, fontWeight: FontWeight.w700))))),
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

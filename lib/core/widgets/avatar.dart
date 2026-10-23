import 'package:flutter/material.dart';

class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const InitialAvatar({super.key, required this.name, this.size = 40, this.color});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary.withValues(alpha: .15);
    final fg = color != null
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.38),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class WireButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  const WireButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c.withValues(alpha: .4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AppBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final double radius;
  final Border? border;
  const AppBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.color,
    this.radius = 14,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
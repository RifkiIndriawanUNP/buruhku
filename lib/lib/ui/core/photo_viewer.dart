import 'dart:io';
import 'package:flutter/material.dart';

/// Overlay foto layar penuh (alamat http atau path file lokal): geser antar foto, cubit untuk zoom, ketuk latar atau tombol tutup untuk keluar.
Future<void> showPhotoViewer(BuildContext context, List<String> urls, {int initial = 0}) {
  final l = urls.where((u) => u.isNotEmpty).toList();
  if (l.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: const Color(0xE6000000),
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) => _PhotoViewer(urls: l, initial: initial.clamp(0, l.length - 1)),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _PhotoViewer({required this.urls, required this.initial});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _c = PageController(initialPage: widget.initial);
  late int _i = widget.initial;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final n = widget.urls.length;
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        PageView.builder(
          controller: _c,
          itemCount: n,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.maybePop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: widget.urls[i].startsWith('http')
                    ? Image.network(
                        widget.urls[i],
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56),
                      )
                    : Image.file(File(widget.urls[i]), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56)),
              ),
            ),
          ),
        ),
        Positioned(
          top: top + 10,
          right: 12,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        if (n > 1)
          Positioned(
            top: top + 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(14)),
                child: Text('${_i + 1} / $n', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

/// Renders a velvety, non-reflective matte paper/canvas diffusion finish
/// mimicking Samsung The Frame's anti-glare matte panel.
class CanvasTexturePainter extends CustomPainter {
  final double intensity;

  const CanvasTexturePainter({this.intensity = 0.35});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Soft matte paper diffusion film (eliminates digital LCD gloss)
    final mattePaint = Paint()
      ..color = const Color(0x06000000)
      ..blendMode = BlendMode.darken;
    canvas.drawRect(Offset.zero & size, mattePaint);

    // 2. Natural gallery light vignette (subtle falloff towards the edges)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: const [
          Colors.transparent,
          Color(0x08000000),
          Color(0x22000000),
        ],
        stops: const [0.70, 0.90, 1.0],
      ).createShader(Offset.zero & size)
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(Offset.zero & size, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CanvasTexturePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

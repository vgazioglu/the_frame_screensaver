import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders an ultra-realistic 2K physical oil painting surface:
/// 1. Fine Belgian linen weave (keten tuval dokuması - warp & weft micro-threads)
/// 2. Subtle organic craquelure/impasto grain
/// 3. Physical monitor bezel cast shadow (tricks the eye into seeing the canvas
///    recessed 5mm behind the MSI monitor's physical frame).
class CanvasTexturePainter extends CustomPainter {
  final double intensity;

  const CanvasTexturePainter({this.intensity = 0.35});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;

    // 1. Anti-glare matte diffusion coat (eliminates LCD backlight harshness)
    final mattePaint = Paint()
      ..color = const Color(0x07140E08)
      ..blendMode = BlendMode.darken;
    canvas.drawRect(rect, mattePaint);

    // 2. Fine 2K Linen Canvas Weave (Keten Tuval Gözenek Dokusu)
    // Drawn at 3px pitch for 2560x1440 resolution: top-lit thread highlight & shadow
    final double alphaScale = (intensity / 0.35).clamp(0.4, 2.0);
    final weftShadowPaint = Paint()
      ..color = Color.fromRGBO(12, 8, 4, (0.028 * alphaScale).clamp(0.0, 0.12))
      ..strokeWidth = 1.0;
    final weftHighlightPaint = Paint()
      ..color = Color.fromRGBO(255, 248, 232, (0.016 * alphaScale).clamp(0.0, 0.08))
      ..strokeWidth = 1.0;

    // Horizontal linen threads (atkı iplikleri - üstten vuran spot ışığını yakalar)
    const double step = 3.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weftShadowPaint);
      canvas.drawLine(
        Offset(0, y + 1.0),
        Offset(size.width, y + 1.0),
        weftHighlightPaint,
      );
    }

    // Vertical linen threads (çözgü iplikleri - daha ince dikey doku)
    final warpShadowPaint = Paint()
      ..color = Color.fromRGBO(12, 8, 4, (0.020 * alphaScale).clamp(0.0, 0.10))
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warpShadowPaint);
    }

    // 3. Subtle organic impasto / pigment micro-variation
    final rng = math.Random(42);
    final speckLight = Paint()
      ..color = Color.fromRGBO(255, 246, 225, (0.018 * alphaScale).clamp(0.0, 0.06))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final speckDark = Paint()
      ..color = Color.fromRGBO(15, 10, 5, (0.022 * alphaScale).clamp(0.0, 0.08))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const int grainCount = 2400;
    for (int i = 0; i < grainCount; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final len = 1.5 + rng.nextDouble() * 3.5;
      if (i.isEven) {
        canvas.drawLine(Offset(dx, dy), Offset(dx + len, dy), speckLight);
      } else {
        canvas.drawLine(Offset(dx, dy), Offset(dx, dy + len), speckDark);
      }
    }

    // 4. Physical Bezel Depth Shadow (Monitörün kendi fiziksel çerçevesinin tuvale düşürdüğü 3D gölge)
    // Üst kenardan aşağı düşen derin galeri gölgesi (18px)
    final topRecessShadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x66000000),
          Color(0x28000000),
          Color(0x08000000),
          Colors.transparent,
        ],
        stops: [0.0, 0.30, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 18.0));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 18.0), topRecessShadow);

    // Sol ve sağ kenar iç kasnak gölgesi (12px)
    final leftRecessShadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x45000000),
          Color(0x14000000),
          Colors.transparent,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, 12.0, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, 12.0, size.height), leftRecessShadow);

    final rightRecessShadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Color(0x45000000),
          Color(0x14000000),
          Colors.transparent,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(size.width - 12.0, 0, 12.0, size.height));
    canvas.drawRect(
      Rect.fromLTWH(size.width - 12.0, 0, 12.0, size.height),
      rightRecessShadow,
    );

    // Alt kenar ince temas gölgesi (8px)
    final bottomRecessShadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0x38000000),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height - 8.0, size.width, 8.0));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 8.0, size.width, 8.0),
      bottomRecessShadow,
    );
  }

  @override
  bool shouldRepaint(covariant CanvasTexturePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

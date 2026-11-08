import 'package:flutter/material.dart';
import '../../core/models/frame_settings.dart';
import '../../core/theme/art_theme.dart';

/// Renders the outer picture frame (wooden/metal bezel) with bevels and shadows.
class FramePainter extends CustomPainter {
  final FrameBezelStyle style;
  final double thickness;

  const FramePainter({
    required this.style,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (thickness <= 0) return;

    final colors = ArtTheme.getFrameColors(style);
    if (colors.isEmpty) return;
    final outerRect = Offset.zero & size;
    final innerRect = outerRect.deflate(thickness);

    // Frame Path
    final framePath = Path()
      ..addRect(outerRect)
      ..addRect(innerRect)
      ..fillType = PathFillType.evenOdd;

    // Base gradient for wood grain / metal body
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(outerRect);
    canvas.drawPath(framePath, framePaint);

    // Outer edge light highlight (top and left)
    final outerHighlight = Paint()
      ..color = const Color(0x35FFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(outerRect.topLeft, outerRect.topRight, outerHighlight);
    canvas.drawLine(outerRect.topLeft, outerRect.bottomLeft, outerHighlight);

    // Outer edge shadow (bottom and right)
    final outerShadow = Paint()
      ..color = const Color(0x40000000)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(outerRect.bottomLeft, outerRect.bottomRight, outerShadow);
    canvas.drawLine(outerRect.topRight, outerRect.bottomRight, outerShadow);

    // Inner lip drop shadow (shadow cast by frame onto the mat board)
    final innerShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x60000000),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        innerRect.width,
        8.0,
      ));
    canvas.drawRect(
      Rect.fromLTWH(innerRect.left, innerRect.top, innerRect.width, 8.0),
      innerShadowPaint,
    );

    final innerShadowLeft = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0x40000000),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        6.0,
        innerRect.height,
      ));
    canvas.drawRect(
      Rect.fromLTWH(innerRect.left, innerRect.top, 6.0, innerRect.height),
      innerShadowLeft,
    );
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.thickness != thickness;
}

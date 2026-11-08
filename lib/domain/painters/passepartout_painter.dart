import 'package:flutter/material.dart';
import '../../core/models/frame_settings.dart';
import '../../core/theme/art_theme.dart';

/// Renders the museum passe-partout (mat board) with 45-degree beveled cut
/// and multi-layered inner drop shadow cast onto the canvas.
class PassepartoutPainter extends CustomPainter {
  final PassepartoutStyle style;
  final Rect artRect;
  final double bevelWidth;

  const PassepartoutPainter({
    required this.style,
    required this.artRect,
    this.bevelWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (style == PassepartoutStyle.none) return;

    final outerRect = Offset.zero & size;
    final matColor = ArtTheme.getMatColor(style);
    final bevelColor = ArtTheme.getMatBevelColor(style);

    // 1. Draw Mat Board (area outside artRect)
    final matPath = Path()
      ..addRect(outerRect)
      ..addRect(artRect)
      ..fillType = PathFillType.evenOdd;

    final matPaint = Paint()..color = matColor;
    canvas.drawPath(matPath, matPaint);

    // 2. Beveled 45-degree inner core cut
    final innerBevelRect = artRect.inflate(bevelWidth);
    final bevelPath = Path()
      ..addRect(innerBevelRect)
      ..addRect(artRect)
      ..fillType = PathFillType.evenOdd;

    final bevelPaint = Paint()..color = bevelColor;
    canvas.drawPath(bevelPath, bevelPaint);

    // Highlight on top & left bevel (gallery overhead lighting)
    final topHighlightPaint = Paint()
      ..color = const Color(0x35FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(artRect.topLeft, artRect.topRight, topHighlightPaint);
    canvas.drawLine(artRect.topLeft, artRect.bottomLeft, topHighlightPaint);

    // Shadow on bottom & right bevel
    final bottomShadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(artRect.bottomLeft, artRect.bottomRight, bottomShadowPaint);
    canvas.drawLine(artRect.topRight, artRect.bottomRight, bottomShadowPaint);

    // 3. Multi-layer depth drop shadow cast from mat board onto the canvas
    // Top shadow (recessed depth)
    final topShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x55000000),
          Color(0x22000000),
          Color(0x05000000),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(
        artRect.left,
        artRect.top,
        artRect.width,
        18.0,
      ));
    canvas.drawRect(
      Rect.fromLTWH(artRect.left, artRect.top, artRect.width, 18.0),
      topShadowPaint,
    );

    // Left shadow
    final leftShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0x40000000),
          Color(0x15000000),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(
        artRect.left,
        artRect.top,
        14.0,
        artRect.height,
      ));
    canvas.drawRect(
      Rect.fromLTWH(artRect.left, artRect.top, 14.0, artRect.height),
      leftShadowPaint,
    );

    // Subtle right & bottom contact shadow
    final rightShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: const [
          Color(0x25000000),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        artRect.right - 8.0,
        artRect.top,
        8.0,
        artRect.height,
      ));
    canvas.drawRect(
      Rect.fromLTWH(artRect.right - 8.0, artRect.top, 8.0, artRect.height),
      rightShadowPaint,
    );

    final bottomShadowPaintInner = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0x25000000),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        artRect.left,
        artRect.bottom - 8.0,
        artRect.width,
        8.0,
      ));
    canvas.drawRect(
      Rect.fromLTWH(artRect.left, artRect.bottom - 8.0, artRect.width, 8.0),
      bottomShadowPaintInner,
    );
  }

  @override
  bool shouldRepaint(covariant PassepartoutPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.artRect != artRect ||
      oldDelegate.bevelWidth != bevelWidth;
}

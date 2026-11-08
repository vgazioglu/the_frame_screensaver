import 'package:flutter/material.dart';
import '../../core/models/artwork.dart';

class MuseumPlaque extends StatelessWidget {
  final Artwork artwork;
  final bool visible;

  const MuseumPlaque({
    super.key,
    required this.artwork,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.0),
          boxShadow: [
            // Plakanın duvara / paspartuya düşen gerçekçi fiziksel gölgesi
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.60),
              blurRadius: 16.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _AntiqueBrassPlaquePainter(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 12.0),
            constraints: const BoxConstraints(minWidth: 320.0, maxWidth: 520.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Eser Başlığı (Derin oyma metal efekti)
                Text(
                  artwork.title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF221607), // Eskimiş koyu bronz/patina oyma rengi
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    fontFamily: 'serif',
                    height: 1.25,
                    shadows: [
                      // Üst iç oyma gölgesi
                      Shadow(
                        color: Color(0xBB000000),
                        offset: Offset(0, -0.9),
                        blurRadius: 0.8,
                      ),
                      // Alt metal parlama vurgusu
                      Shadow(
                        color: Color(0x99FFF0BA),
                        offset: Offset(0, 1.0),
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Sanatçı ve Yıl
                Text(
                  '${artwork.artist}${artwork.year.isNotEmpty ? " • ${artwork.year}" : ""}',
                  style: const TextStyle(
                    color: Color(0xFF38260D),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.1,
                    fontFamily: 'serif',
                    shadows: [
                      Shadow(
                        color: Color(0x88000000),
                        offset: Offset(0, -0.6),
                        blurRadius: 0.6,
                      ),
                      Shadow(
                        color: Color(0x77FFF0BA),
                        offset: Offset(0, 0.8),
                        blurRadius: 0.4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                if (artwork.museum.isNotEmpty) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    artwork.museum.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF523B17),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      fontFamily: 'serif',
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          offset: Offset(0, -0.5),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: Color(0x66FFF0BA),
                          offset: Offset(0, 0.7),
                          blurRadius: 0.3,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Eskitilmiş, 4 köşesinde pirinç vidaları ve oyma kenarlığı olan antika pirinç plaka
class _AntiqueBrassPlaquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Eskitilmiş Fırçalanmış Pirinç / Antika Bronz Gövde
    final brassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF8A6C32), // Koyu patinalı köşe
        Color(0xFFD4B268), // Parlak pirinç yansıması
        Color(0xFFBE9A4E), // Orta ton pirinç
        Color(0xFFF3DCA0), // Tepe ışık çizgisi
        Color(0xFFA68237), // Eskimiş altın/bronz
        Color(0xFF6B4E1A), // Alt kenar koyuluğu
      ],
      stops: const [0.0, 0.22, 0.45, 0.65, 0.85, 1.0],
    );

    final bgPaint = Paint()..shader = brassGradient.createShader(rect);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));
    canvas.drawRRect(rrect, bgPaint);

    // 2. Dış Pahlı Kenar Işığı ve Gölgesi (Bevel)
    final highlightPaint = Paint()
      ..color = const Color(0xAAFFF3D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(rect.topLeft, rect.topRight, highlightPaint);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, highlightPaint);

    final darkEdgePaint = Paint()
      ..color = const Color(0xDD3A270B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, darkEdgePaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, darkEdgePaint);

    // 3. İç Oyma Sınır Çizgisi (Engraved Inset Border)
    final insetRect = rect.deflate(5.0);
    final innerRRect = RRect.fromRectAndRadius(insetRect, const Radius.circular(1.5));

    // Oyuğun koyu iç çizgisi
    final grooveDark = Paint()
      ..color = const Color(0xAA422E10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(innerRRect, grooveDark);

    // Oyuğun alt parlaması
    final grooveLight = Paint()
      ..color = const Color(0x66FFF5D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final grooveHighlightRect = Rect.fromLTWH(
      insetRect.left + 0.5,
      insetRect.top + 0.5,
      insetRect.width,
      insetRect.height,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(grooveHighlightRect, const Radius.circular(1.5)), grooveLight);

    // 4. Dört Köşedeki Antika Pirinç Vidalar / Perçinler (Screws)
    _drawScrew(canvas, Offset(rect.left + 7.5, rect.top + 7.5));
    _drawScrew(canvas, Offset(rect.right - 7.5, rect.top + 7.5));
    _drawScrew(canvas, Offset(rect.left + 7.5, rect.bottom - 7.5));
    _drawScrew(canvas, Offset(rect.right - 7.5, rect.bottom - 7.5));
  }

  void _drawScrew(Canvas canvas, Offset center) {
    const radius = 2.4;

    // Vida dış gölgesi
    canvas.drawCircle(
      center + const Offset(0.4, 0.4),
      radius,
      Paint()..color = const Color(0x66291C0A),
    );

    // Vida pirinç başı
    final screwPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [
          Color(0xFFFFF0BA),
          Color(0xFF9E7C35),
          Color(0xFF4A340F),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, screwPaint);

    // Vidanın tornavida yarığı (çapraz slot çizgisi)
    final slotPaint = Paint()
      ..color = const Color(0xFF2B1C07)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center - const Offset(1.3, 0.7),
      center + const Offset(1.3, 0.7),
      slotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

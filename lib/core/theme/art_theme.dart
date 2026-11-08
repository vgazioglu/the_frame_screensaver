import 'package:flutter/material.dart';
import '../models/frame_settings.dart';

abstract final class ArtTheme {
  // Wood & Frame Gradients
  static List<Color> getFrameColors(FrameBezelStyle style) => switch (style) {
        FrameBezelStyle.none => const [],
        FrameBezelStyle.walnut => const [
            Color(0xFF2E1A11),
            Color(0xFF4A2A1A),
            Color(0xFF381F13),
            Color(0xFF1E0E08),
          ],
        FrameBezelStyle.oak => const [
            Color(0xFF8A6235), // Doğal Meşe Dış Kenar
            Color(0xFFC49F6E), // Meşe Ahşap Gövdesi
            Color(0xFF9E7440), // Meşe Damar Tonu
            Color(0xFF6B4B23), // Meşe İç Gölgelik
          ],
        FrameBezelStyle.matteWhite => const [
            Color(0xFFF0F0F0),
            Color(0xFFFFFFFF),
            Color(0xFFE8E8E8),
            Color(0xFFDDDDDD),
          ],
        FrameBezelStyle.obsidianBlack => const [
            Color(0xFF151515),
            Color(0xFF262626),
            Color(0xFF1C1C1C),
            Color(0xFF101010),
          ],
      };

  // Mat Board (Passe-partout) Base Color
  static Color getMatColor(PassepartoutStyle style) => switch (style) {
        PassepartoutStyle.warmCream => const Color(0xFFF6F3EC),
        PassepartoutStyle.modernWhite => const Color(0xFFFCFCFC),
        PassepartoutStyle.antiqueGray => const Color(0xFFE8E6E0),
        PassepartoutStyle.none => Colors.transparent,
      };

  // Mat Board Bevel Cut Edge Highlight Color (45 degree core bevel)
  static Color getMatBevelColor(PassepartoutStyle style) => switch (style) {
        PassepartoutStyle.warmCream => const Color(0xFFDDD7C8),
        PassepartoutStyle.modernWhite => const Color(0xFFE2E2E2),
        PassepartoutStyle.antiqueGray => const Color(0xFFCCC8BD),
        PassepartoutStyle.none => Colors.transparent,
      };

  // Typography for Museum Brass / Paper Plaque
  static const TextStyle plaqueTitleStyle = TextStyle(
    color: Color(0xFFEAEAEA),
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    fontFamily: 'serif',
    height: 1.25,
  );

  static const TextStyle plaqueArtistStyle = TextStyle(
    color: Color(0xFFB8B8B8),
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    fontFamily: 'serif',
  );

  static const TextStyle plaqueMetaStyle = TextStyle(
    color: Color(0xFF888888),
    fontSize: 11.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.3,
  );
}

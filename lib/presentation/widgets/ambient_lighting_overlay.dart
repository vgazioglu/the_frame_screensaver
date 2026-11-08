import 'package:flutter/material.dart';

/// Simulates a realistic museum ceiling track-spotlight (3000K warm halogen cone)
/// and circadian time-of-day gallery atmosphere across the oil painting surface.
class AmbientLightingOverlay extends StatelessWidget {
  const AmbientLightingOverlay({super.key});

  bool get _isEveningOrNight {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 7;
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isEveningOrNight;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Overhead Museum Track Spotlight Cone (Tavan Spotu & Vernik Yansıması)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.48),
                radius: 1.15,
                focal: const Alignment(0.0, -0.65),
                focalRadius: 0.08,
                colors: [
                  // Spotun tuvalin üst-orta kısmındaki vernikte oluşturduğu sıcak 3000K aydınlanma
                  isNight
                      ? const Color(0x16FFE8C2)
                      : const Color(0x10FFF6E5),
                  const Color(0x05FFF2DC),
                  Colors.transparent,
                  // Alt köşelere doğru doğal galeri ışık düşüşü (inverse-square falloff)
                  isNight
                      ? const Color(0x38080604)
                      : const Color(0x22080604),
                ],
                stops: const [0.0, 0.32, 0.68, 1.0],
              ),
            ),
          ),

          // 2. Vertical Gallery Wall Wash (Yukarıdan aşağıya doğal ışık süzülmesi)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x08FFF4E0),
                  Colors.transparent,
                  isNight
                      ? const Color(0x24050403)
                      : const Color(0x14050403),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

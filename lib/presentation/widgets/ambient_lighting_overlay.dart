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

    // Impeller OpenGLES (OpenGLESSDF) çok duraklı (multi-stop) Linear/Radial
    // gradyanlarda keskin basamak/şerit (y=45px) oluşturduğu için,
    // galeri atmosferi homojen sıcak mat vernik katmanı olarak uygulanır.
    return IgnorePointer(
      child: ColoredBox(
        color: isNight
            ? const Color(0x14080604)
            : const Color(0x0A080604),
      ),
    );
  }
}

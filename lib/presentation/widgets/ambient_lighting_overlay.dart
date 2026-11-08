import 'package:flutter/material.dart';

/// Simulates directional museum spotlight / ambient gallery illumination
/// washing across the matte painting surface.
class AmbientLightingOverlay extends StatelessWidget {
  const AmbientLightingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1.0),
            end: Alignment(0.8, 1.0),
            colors: [
              Color(0x0CFFF6E5), // Soft warm highlight from top-left spot
              Colors.transparent,
              Color(0x10000000), // Very gentle natural falloff to bottom-right
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

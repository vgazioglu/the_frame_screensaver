import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/artwork.dart';
import '../../core/models/frame_settings.dart';
import '../../domain/painters/canvas_texture_painter.dart';
import '../../domain/painters/frame_painter.dart';
import 'ambient_lighting_overlay.dart';
import 'museum_plaque.dart';

class FrameCanvas extends StatefulWidget {
  final Artwork artwork;
  final FrameSettings settings;

  const FrameCanvas({
    super.key,
    required this.artwork,
    required this.settings,
  });

  @override
  State<FrameCanvas> createState() => _FrameCanvasState();
}

class _FrameCanvasState extends State<FrameCanvas> {
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;
  double _imageAspect = 1.77;

  ImageProvider _getImageProvider(Artwork art) {
    if (art.hasLocalFile && File(art.localFilePath!).existsSync()) {
      return FileImage(File(art.localFilePath!));
    }
    if (art.hasAsset) {
      return AssetImage(art.assetPath!);
    }
    return const AssetImage('assets/paintings/david_socrates.jpg');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(FrameCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artwork.id != oldWidget.artwork.id) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = _getImageProvider(widget.artwork);
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    _imageStream = provider.resolve(createLocalImageConfiguration(context));
    _streamListener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (h > 0 && mounted) {
          setState(() {
            _imageAspect = w / h;
          });
        }
      },
      onError: (exception, stackTrace) {
        // Hata durumunda sessizce güvenli oranda kalır
      },
    );
    _imageStream!.addListener(_streamListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    super.dispose();
  }

  Alignment _calculateFocalAlignment() {
    // 1. Eser bazlı özel odak noktası tanımlanmışsa (metadata focalY) onu kullanır
    if (widget.artwork.focalY != null) {
      return Alignment(0.0, widget.artwork.focalY!.clamp(-1.0, 1.0));
    }

    // 2. Varsayılan Akıllı Kompozisyon Odaklaması:
    // Aşırı uçlara (-0.95 gibi) gitmeden, insan gözünün ve altın oranın doğal odağını korur
    if (_imageAspect < 0.95) {
      // Dikey (portrait) eserler: Tavan ve baş payı güvenliği
      return const Alignment(0.0, -0.60);
    }
    if (_imageAspect < 1.45) {
      // 5:4 ve 4:3 klasik oranlar (Portreler ve figüratif tablolar için güvenli tavan payı)
      return const Alignment(0.0, -0.45);
    }
    // Geniş 16:9 / 16:10 panoramik manzara tabloları
    return const Alignment(0.0, -0.12);
  }

  static List<double> _calculateArtModeColorMatrix(double factor) {
    // Samsung The Frame "Art Mode" Optik Simülasyonu:
    // 1. Arka Işık Kısma: Monitörün sert LED ışığını (~%15) kısarak gerçek tuvalin ortam ışığını yansıtma hissini verir.
    // 2. Sıcak Tuval Spektrumu: Soğuk mavi dijital LED piklerini kırar (-%6 mavi), sıcak keten/yağlıboya tonu ekler (+%2 kırmızı).
    // 3. Pigment Derinliği: Dijital zifiri siyahı (#000000) fiziksel boya pigmenti gibi hafifçe yumuşatır (+3.0 ofset).
    final r = factor * 1.02;
    final g = factor * 1.00;
    final b = factor * 0.94;
    return [
      r, 0, 0, 0, 3.0,
      0, g, 0, 0, 3.0,
      0, 0, b, 0, 1.0,
      0, 0, 0, 1.0, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        // 1. SAMSUNG THE FRAME SAF MODU (Aspect Ratio Korunarak Tüm Ekrana Yayma):
        // Tıpkı Samsung The Frame TV uygulamasında olduğu gibi:
        // - En-boy oranı (aspect ratio) KESİNLİKLE bozulmaz (BoxFit.cover).
        // - Tablonun en can alıcı noktasına (altın oran / görsel odak) akıllı odaklanır.
        // - %4 TV overscan ile kenardaki tarama çizgileri/çerçeve kenarları elenir, sıfır boşluk kalır.
        // - errorBuilder sayesinde asla siyah ekran oluşmaz.
        if (widget.settings.fitMode.isSamsungMode) {
          final focalAlignment = _calculateFocalAlignment();
          // Oranı 16:9'dan dar olan tablolarda dikey overscan yapmayarak tavan payını azami koruyoruz
          final overscanScale = _imageAspect < 1.65 ? 1.0 : 1.02;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Tablonun Kendisi (Uçtan uca, en-boy oranı korunarak yayılan saf tablo)
              Transform.scale(
                scale: overscanScale,
                child: ColorFiltered(
                  colorFilter: widget.settings.enableAmbientDimming
                      ? ColorFilter.matrix(
                          _calculateArtModeColorMatrix(
                            widget.settings.matteDimmingFactor,
                          ),
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Image(
                    image: _getImageProvider(widget.artwork),
                    fit: BoxFit.cover, // Aspect ratio %100 korunur, asla basık/yayvan yapmaz!
                    width: double.infinity,
                    height: double.infinity,
                    alignment: focalAlignment,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/paintings/van_gogh_cypresses.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: const Alignment(0.0, -0.15),
                      );
                    },
                  ),
                ),
              ),

              // The Frame Mat Ekran / Yağlı boya tuval dokusu (Yansımasız gerçek tuval hissi)
              if (widget.settings.enableCanvasTexture)
                const Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: CanvasTexturePainter(intensity: 0.35),
                    ),
                  ),
                ),

              // Ortam Sensörü Işıklandırması
              if (widget.settings.enableAmbientDimming)
                const Positioned.fill(
                  child: AmbientLightingOverlay(),
                ),
            ],
          );
        }

        // 2. SMART MAT MODE (Klasik Müze Paspartusu):
        // Eser BoxFit.contain ile %100 tam gösterilir, paspartu ve çerçeve ile sunulur.
        final matColor = switch (widget.settings.matStyle) {
          PassepartoutStyle.warmCream => const Color(0xFFF1E9DA),
          PassepartoutStyle.modernWhite => const Color(0xFFFAF8F5),
          PassepartoutStyle.antiqueGray => const Color(0xFF2C2C2E),
          PassepartoutStyle.none => const Color(0xFF18181A),
        };

        return Container(
          width: totalWidth,
          height: totalHeight,
          color: matColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Mat Board Kağıt Dokusu
              Container(
                decoration: BoxDecoration(
                  color: matColor,
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2),
                    radius: 1.2,
                    colors: [
                      matColor,
                      Color.lerp(matColor, Colors.black, 0.15)!,
                    ],
                  ),
                ),
              ),

              // Eserin Kendisi (Hiçbir yer kesilmeden, ortalanmış ve gölgeli)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56.0,
                    vertical: 42.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        // 45 derece pahlı iç paspartu gölgesi (The Frame 3D Derinlik)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18.0,
                          spreadRadius: 2.0,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ColorFiltered(
                          colorFilter: widget.settings.enableAmbientDimming
                              ? ColorFilter.matrix(
                                  _calculateArtModeColorMatrix(
                                    widget.settings.matteDimmingFactor,
                                  ),
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: Image(
                            image: _getImageProvider(widget.artwork),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),

                        // Yağlı boya mat tuval dokusu
                        if (widget.settings.enableCanvasTexture)
                          const Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: CanvasTexturePainter(intensity: 0.35),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Galeri Işıklandırması
              if (widget.settings.enableAmbientDimming)
                const Positioned.fill(
                  child: AmbientLightingOverlay(),
                ),

              // Dış Ahşap/Siyah Çerçeve (varsa)
              if (widget.settings.bezelStyle != FrameBezelStyle.none)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: FramePainter(
                        style: widget.settings.bezelStyle,
                        thickness: 24.0,
                      ),
                    ),
                  ),
                ),

              // Bilgi Plakası
              if (widget.settings.showMuseumPlaque)
                Positioned(
                  bottom: 24.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MuseumPlaque(
                      artwork: widget.artwork,
                      visible: true,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

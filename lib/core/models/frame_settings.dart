enum FrameBezelStyle {
  none,
  walnut,
  oak,
  matteWhite,
  obsidianBlack;

  String get displayName => switch (this) {
        FrameBezelStyle.none => 'Çerçevesiz (Modern Kenar)',
        FrameBezelStyle.walnut => 'Ceviz Ağacı (Walnut)',
        FrameBezelStyle.oak => 'Doğal Meşe (Oak)',
        FrameBezelStyle.matteWhite => 'Galeri Beyazı (Matte White)',
        FrameBezelStyle.obsidianBlack => 'Obsidiyen Siyah (Matte Black)',
      };
}

enum PassepartoutStyle {
  warmCream,
  modernWhite,
  antiqueGray,
  none;

  String get displayName => switch (this) {
        PassepartoutStyle.warmCream => 'Sıcak Krem (Warm Cream)',
        PassepartoutStyle.modernWhite => 'Modern Beyaz (Modern White)',
        PassepartoutStyle.antiqueGray => 'Müze Grisi (Museum Gray)',
        PassepartoutStyle.none => 'Paspartusuz (No Mat)',
      };
}

enum ArtworkFitMode {
  samsungNoMat, // Samsung The Frame: Aspect ratio bozulmadan tüm ekranı doldurur (BoxFit.cover - Akıllı Odak), kenarlıksız
  smartMat; // Müze Paspartusu: BoxFit.contain ile orijinal boyut, paspartu ve ahşap çerçeve

  String get displayName => switch (this) {
        ArtworkFitMode.samsungNoMat => 'Samsung The Frame (Kenarsız - Akıllı Odak)',
        ArtworkFitMode.smartMat => 'Müze Paspartusu (Orijinal Boyut - Çerçeveli)',
      };

  bool get isSamsungMode => this == ArtworkFitMode.samsungNoMat;
}

class FrameSettings {
  final FrameBezelStyle bezelStyle;
  final PassepartoutStyle matStyle;
  final ArtworkFitMode fitMode;
  final double frameThickness;
  final double matWidth;
  final bool showMuseumPlaque;
  final bool enableCanvasTexture;
  final bool enableAmbientDimming;
  final int autoCycleSeconds;
  final double matteDimmingFactor; // 0.5 to 1.0

  const FrameSettings({
    this.bezelStyle = FrameBezelStyle.none,
    this.matStyle = PassepartoutStyle.none,
    this.fitMode = ArtworkFitMode.samsungNoMat,
    this.frameThickness = 0.0,
    this.matWidth = 0.0,
    this.showMuseumPlaque = false,
    this.enableCanvasTexture = true,
    this.enableAmbientDimming = true,
    this.autoCycleSeconds = 300, // 5 minutes default
    this.matteDimmingFactor = 0.85,
  });

  FrameSettings copyWith({
    FrameBezelStyle? bezelStyle,
    PassepartoutStyle? matStyle,
    ArtworkFitMode? fitMode,
    double? frameThickness,
    double? matWidth,
    bool? showMuseumPlaque,
    bool? enableCanvasTexture,
    bool? enableAmbientDimming,
    int? autoCycleSeconds,
    double? matteDimmingFactor,
  }) {
    return FrameSettings(
      bezelStyle: bezelStyle ?? this.bezelStyle,
      matStyle: matStyle ?? this.matStyle,
      fitMode: fitMode ?? this.fitMode,
      frameThickness: frameThickness ?? this.frameThickness,
      matWidth: matWidth ?? this.matWidth,
      showMuseumPlaque: showMuseumPlaque ?? this.showMuseumPlaque,
      enableCanvasTexture: enableCanvasTexture ?? this.enableCanvasTexture,
      enableAmbientDimming: enableAmbientDimming ?? this.enableAmbientDimming,
      autoCycleSeconds: autoCycleSeconds ?? this.autoCycleSeconds,
      matteDimmingFactor: matteDimmingFactor ?? this.matteDimmingFactor,
    );
  }

  Map<String, dynamic> toJson() => {
        'bezelStyle': bezelStyle.name,
        'matStyle': matStyle.name,
        'fitMode': fitMode.name,
        'frameThickness': frameThickness,
        'matWidth': matWidth,
        'showMuseumPlaque': showMuseumPlaque,
        'enableCanvasTexture': enableCanvasTexture,
        'enableAmbientDimming': enableAmbientDimming,
        'autoCycleSeconds': autoCycleSeconds,
        'matteDimmingFactor': matteDimmingFactor,
      };

  factory FrameSettings.fromJson(Map<String, dynamic> json) {
    return FrameSettings(
      bezelStyle: FrameBezelStyle.values.firstWhere(
        (e) => e.name == json['bezelStyle'],
        orElse: () => FrameBezelStyle.none,
      ),
      matStyle: PassepartoutStyle.values.firstWhere(
        (e) => e.name == json['matStyle'],
        orElse: () => PassepartoutStyle.none,
      ),
      fitMode: ArtworkFitMode.values.firstWhere(
        (e) => e.name == json['fitMode'],
        orElse: () => ArtworkFitMode.samsungNoMat,
      ),
      frameThickness: (json['frameThickness'] as num?)?.toDouble() ?? 0.0,
      matWidth: (json['matWidth'] as num?)?.toDouble() ?? 0.0,
      showMuseumPlaque: json['showMuseumPlaque'] as bool? ?? false,
      enableCanvasTexture: json['enableCanvasTexture'] as bool? ?? true,
      enableAmbientDimming: json['enableAmbientDimming'] as bool? ?? true,
      autoCycleSeconds: (json['autoCycleSeconds'] as num?)?.toInt() ?? 300,
      matteDimmingFactor:
          (json['matteDimmingFactor'] as num?)?.toDouble() ?? 0.85,
    );
  }
}

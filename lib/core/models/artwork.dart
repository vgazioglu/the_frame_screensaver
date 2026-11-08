class Artwork {
  final String id;
  final String title;
  final String artist;
  final String year;
  final String medium;
  final String museum;
  final String? assetPath;
  final String? localFilePath;
  final String? remoteImageUrl;
  final double? focalY; // -1.0 (en üst) ile +1.0 (en alt) arası özel odak noktası

  const Artwork({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.medium,
    required this.museum,
    this.assetPath,
    this.localFilePath,
    this.remoteImageUrl,
    this.focalY,
  });

  bool get hasLocalFile => localFilePath != null;
  bool get hasAsset => assetPath != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'year': year,
        'medium': medium,
        'museum': museum,
        if (assetPath != null) 'assetPath': assetPath,
        if (localFilePath != null) 'localFilePath': localFilePath,
        if (remoteImageUrl != null) 'remoteImageUrl': remoteImageUrl,
        if (focalY != null) 'focalY': focalY,
      };

  factory Artwork.fromJson(Map<String, dynamic> json) => Artwork(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        year: json['year'] as String? ?? '',
        medium: json['medium'] as String? ?? 'Oil on canvas',
        museum: json['museum'] as String? ?? '',
        assetPath: json['assetPath'] as String?,
        localFilePath: json['localFilePath'] as String?,
        remoteImageUrl: json['remoteImageUrl'] as String?,
        focalY: (json['focalY'] as num?)?.toDouble(),
      );
}

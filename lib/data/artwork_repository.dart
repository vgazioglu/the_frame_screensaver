import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../core/models/artwork.dart';
import '../core/models/frame_settings.dart';

class ArtworkRepository {
  static const String _catalogFileName = 'catalog.json';
  static const String _paintingsDirName = 'paintings';
  static const String _settingsFileName = 'settings.json';

  late Directory _cacheDir;
  late Directory _paintingsDir;
  late File _catalogFile;
  late Directory _configDir;
  late File _settingsFile;

  bool _initialized = false;

  // MSI 27" PRO MP275Q (2560x1440 WQHD 16:9 = 1.78) monitöre tam uyumlu
  // Geniş Ekran (Widescreen >= 1.45..2.10) Dahili Yağlıboya Şaheserler
  static const List<Artwork> bundledMasterpieces = [
    Artwork(
      id: 'met-436105',
      title: 'The Death of Socrates',
      artist: 'Jacques Louis David',
      year: '1787',
      medium: 'Oil on canvas',
      museum: 'The Metropolitan Museum of Art, New York',
      assetPath: 'assets/paintings/david_socrates.jpg',
    ),
    Artwork(
      id: 'met-437658',
      title: 'Study for "A Sunday on La Grande Jatte"',
      artist: 'Georges Seurat',
      year: '1884',
      medium: 'Oil on canvas',
      museum: 'The Metropolitan Museum of Art, New York',
      assetPath: 'assets/paintings/seurat_grande_jatte.jpg',
    ),
  ];

  // Curated Multi-Museum Masterpieces (MoMA, Uffizi, Rijksmuseum, Mauritshuis, National Gallery London, etc.)
  // Strictly Landscape (Ratio >= 1.25, 4K High Resolution via Wikimedia Commons Special:FilePath)
  static const List<Map<String, String>> curatedMuseumPool = [
    {
      'id': 'gap-starry-night',
      'title': 'The Starry Night',
      'artist': 'Vincent van Gogh',
      'year': '1889',
      'medium': 'Oil on canvas',
      'museum': 'Museum of Modern Art, New York',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Vincent_van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-venus',
      'title': 'The Birth of Venus',
      'artist': 'Sandro Botticelli',
      'year': 'c. 1484–1486',
      'medium': 'Tempera on canvas',
      'museum': 'Uffizi Gallery, Florence',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Sandro_Botticelli_-_La_nascita_di_Venere_-_Google_Art_Project_-_edited.jpg?width=3840',
    },
    {
      'id': 'gap-turner-temeraire',
      'title': 'The Fighting Temeraire',
      'artist': 'J. M. W. Turner',
      'year': '1839',
      'medium': 'Oil on canvas',
      'museum': 'The National Gallery, London',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/The_Fighting_Temeraire,_JMW_Turner,_National_Gallery.jpg?width=3840',
    },
    {
      'id': 'gap-haywain',
      'title': 'The Hay Wain',
      'artist': 'John Constable',
      'year': '1821',
      'medium': 'Oil on canvas',
      'museum': 'The National Gallery, London',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/John_Constable_-_The_Hay_Wain_(1821).jpg?width=3840',
    },
    {
      'id': 'gap-bierstadt-sierra',
      'title': 'Among the Sierra Nevada, California',
      'artist': 'Albert Bierstadt',
      'year': '1868',
      'medium': 'Oil on canvas',
      'museum': 'Smithsonian American Art Museum',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Albert_Bierstadt_-_Among_the_Sierra_Nevada,_California_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-bierstadt-rocky',
      'title': 'A Storm in the Rocky Mountains, Mt. Rosalie',
      'artist': 'Albert Bierstadt',
      'year': '1866',
      'medium': 'Oil on canvas',
      'museum': 'Brooklyn Museum, New York',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Albert_Bierstadt_-_A_Storm_in_the_Rocky_Mountains,_Mt._Rosalie_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-bruegel-hunters',
      'title': 'The Hunters in the Snow',
      'artist': 'Pieter Bruegel the Elder',
      'year': '1565',
      'medium': 'Oil on wood panel',
      'museum': 'Kunsthistorisches Museum, Vienna',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Pieter_Bruegel_the_Elder_-_Hunters_in_the_Snow_(Winter)_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-bruegel-babel',
      'title': 'The Tower of Babel',
      'artist': 'Pieter Bruegel the Elder',
      'year': '1563',
      'medium': 'Oil on wood panel',
      'museum': 'Kunsthistorisches Museum, Vienna',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Pieter_Bruegel_the_Elder_-_The_Tower_of_Babel_(Vienna)_-_Google_Art_Project_-_edited.jpg?width=3840',
    },
    {
      'id': 'gap-church-cotopaxi',
      'title': 'Cotopaxi',
      'artist': 'Frederic Edwin Church',
      'year': '1862',
      'medium': 'Oil on canvas',
      'museum': 'Detroit Institute of Arts',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Frederic_Edwin_Church_-_Cotopaxi_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-church-aurora',
      'title': 'Aurora Borealis',
      'artist': 'Frederic Edwin Church',
      'year': '1865',
      'medium': 'Oil on canvas',
      'museum': 'Smithsonian American Art Museum',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Frederic_Edwin_Church_-_Aurora_Borealis_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-hokusai-wave',
      'title': 'Under the Wave off Kanagawa (The Great Wave)',
      'artist': 'Katsushika Hokusai',
      'year': 'c. 1831',
      'medium': 'Woodblock print',
      'museum': 'Tokyo National Museum',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Great_Wave_off_Kanagawa2.jpg?width=3840',
    },
    {
      'id': 'gap-friedrich-tree',
      'title': 'The Lone Tree (Der einsame Baum)',
      'artist': 'Caspar David Friedrich',
      'year': '1822',
      'medium': 'Oil on canvas',
      'museum': 'Alte Nationalgalerie, Berlin',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Caspar_David_Friedrich_-_Der_einsame_Baum_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-monet-sunrise',
      'title': 'Impression, Sunrise',
      'artist': 'Claude Monet',
      'year': '1872',
      'medium': 'Oil on canvas',
      'museum': 'Musée Marmottan Monet, Paris',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Claude_Monet,_Impression,_soleil_levant.jpg?width=3840',
    },
    {
      'id': 'gap-caillebotte-rain',
      'title': 'Paris Street; Rainy Day',
      'artist': 'Gustave Caillebotte',
      'year': '1877',
      'medium': 'Oil on canvas',
      'museum': 'Art Institute of Chicago',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Gustave_Caillebotte_-_Paris_Street;_Rainy_Day_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-voogd-pines',
      'title': 'Italian Landscape with Umbrella Pines',
      'artist': 'Hendrik Voogd',
      'year': '1807',
      'medium': 'Oil on canvas',
      'museum': 'Rijksmuseum, Amsterdam',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Hendrik_Voogd_-_Italian_landscape_with_Umbrella_Pines.jpg?width=3840',
    },
    {
      'id': 'gap-avercamp-ice',
      'title': 'Winter Landscape with Ice Skaters',
      'artist': 'Hendrick Avercamp',
      'year': 'c. 1608',
      'medium': 'Oil on panel',
      'museum': 'Rijksmuseum, Amsterdam',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Hendrick_Avercamp_-_Winterlandschap_met_ijsvermaak.jpg?width=3840',
    },
    {
      'id': 'gap-canaletto-bucentaur',
      'title': 'Bucentaur\'s Return to the Pier by the Palazzo Ducale',
      'artist': 'Canaletto',
      'year': 'c. 1730',
      'medium': 'Oil on canvas',
      'museum': 'Pushkin State Museum of Fine Arts, Moscow',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Canaletto_-_Bucentaur%27s_return_to_the_pier_by_the_Palazzo_Ducale_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-rembrandt-tulp',
      'title': 'The Anatomy Lesson of Dr. Nicolaes Tulp',
      'artist': 'Rembrandt van Rijn',
      'year': '1632',
      'medium': 'Oil on canvas',
      'museum': 'Mauritshuis, The Hague',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Rembrandt_-_The_Anatomy_Lesson_of_Dr_Nicolaes_Tulp.jpg?width=3840',
    },
    {
      'id': 'gap-cole-oxbow',
      'title': 'The Oxbow (View from Mount Holyoke)',
      'artist': 'Thomas Cole',
      'year': '1836',
      'medium': 'Oil on canvas',
      'museum': 'The Metropolitan Museum of Art, New York',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Cole_Thomas_The_Oxbow_(The_Connecticut_River_near_Northampton_1836).jpg?width=3840',
    },
    {
      'id': 'gap-friedrich-monk',
      'title': 'The Monk by the Sea',
      'artist': 'Caspar David Friedrich',
      'year': '1808–1810',
      'medium': 'Oil on canvas',
      'museum': 'Alte Nationalgalerie, Berlin',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Caspar_David_Friedrich_-_Der_M%C3%B6nch_am_Meer_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-cezanne-mont',
      'title': 'Mont Sainte-Victoire and Château Noir',
      'artist': 'Paul Cézanne',
      'year': '1904–1906',
      'medium': 'Oil on canvas',
      'museum': 'Bridgestone Museum of Art, Tokyo',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Paul_Cezanne_-_Mont_Sainte-Victoire_and_Ch%C3%A2teau_Noir_-_Google_Art_Project.jpg?width=3840',
    },
    {
      'id': 'gap-pissarro-boulevard',
      'title': 'Boulevard Montmartre, Morning, Cloudy Weather',
      'artist': 'Camille Pissarro',
      'year': '1897',
      'medium': 'Oil on canvas',
      'museum': 'National Gallery of Victoria, Melbourne',
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/Camille_Pissarro_-_Boulevard_Montmartre%2C_morning%2C_cloudy_weather_-_Google_Art_Project.jpg?width=3840',
    },
  ];

  // Verified Met Museum IDs for additional landscape variety (Bundled IDs 436535, 436105, 436528, 437658 excluded to prevent duplication)
  static const List<int> curatedLandscapeMetIds = [
    437056, // Memling - Tommaso Portinari (1.53)
    437053, // Meléndez - The Afternoon Meal (1.45)
    435883, // Cézanne - Still Life with Apples and Pears (1.30)
    438815, // Turner - The Grand Canal, Venice (1.61)
    438821, // Turner - Venice from Madonna (1.50)
    437135, // Monet - The Parc Monceau (1.30)
    437372, // Pissarro - Boulevard Montmartre (1.28)
    437430, // Renoir - By the Seashore (1.30)
    437532, // Rousseau - The Repast of the Lion (1.33)
    437326, // Poussin - Blind Orion (1.44)
  ];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final home = Platform.environment['HOME'] ?? '';
    _cacheDir = Directory(p.join(home, '.cache', 'the_frame_screensaver'));
    _paintingsDir = Directory(p.join(_cacheDir.path, _paintingsDirName));
    _catalogFile = File(p.join(_cacheDir.path, _catalogFileName));

    _configDir = Directory(p.join(home, '.config', 'the_frame_screensaver'));
    _settingsFile = File(p.join(_configDir.path, _settingsFileName));

    if (!await _paintingsDir.exists()) {
      await _paintingsDir.create(recursive: true);
    }

    if (!await _configDir.exists()) {
      await _configDir.create(recursive: true);
    }
  }

  /// Loads saved frame settings from ~/.config/the_frame_screensaver/settings.json
  Future<FrameSettings> loadSettings() async {
    await init();
    if (await _settingsFile.exists()) {
      try {
        final content = await _settingsFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return FrameSettings.fromJson(map);
      } catch (_) {}
    }
    return const FrameSettings();
  }

  /// Persists frame settings to ~/.config/the_frame_screensaver/settings.json
  Future<void> saveSettings(FrameSettings settings) async {
    await init();
    try {
      if (!await _configDir.exists()) {
        await _configDir.create(recursive: true);
      }
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(settings.toJson());
      await _settingsFile.writeAsString(jsonStr);
    } catch (_) {}
  }

  static bool isLandscapeJpeg(File file) {
    try {
      if (!file.existsSync()) return true;
      final bytes = file.openSync().readSync(4096);
      for (int i = 0; i < bytes.length - 8; i++) {
        if (bytes[i] == 0xFF &&
            (bytes[i + 1] >= 0xC0 && bytes[i + 1] <= 0xC3) &&
            bytes[i + 1] != 0xC4) {
          final h = (bytes[i + 5] << 8) | bytes[i + 6];
          final w = (bytes[i + 7] << 8) | bytes[i + 8];
          if (h > 0) {
            final ratio = w / h;
            // MSI 27" PRO MP275Q (2560x1440 WQHD 16:9 = 1.78) için sıkı geniş ekran filtresi:
            // Yalnızca 1.45 (3:2) ile 2.10 arasındaki geniş yatay tablolar kabul edilir;
            // kareye yakın (4:3, 5:4) veya dikey tablolar zorlanmaz ve gösterilmez.
            return ratio >= 1.45 && ratio <= 2.10 && h >= 800;
          }
        }
      }
    } catch (_) {}
    return true;
  }

  /// Loads all artworks: strictly landscape (aspect ratio >= 1.15) with valid files (> 50KB)
  Future<List<Artwork>> loadAllArtworks() async {
    await init();

    final artworks = <Artwork>[...bundledMasterpieces];

    if (await _catalogFile.exists()) {
      try {
        final content = await _catalogFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        for (final item in list) {
          final art = Artwork.fromJson(item as Map<String, dynamic>);
          if (art.localFilePath != null) {
            final f = File(art.localFilePath!);
            if (await f.exists() &&
                await f.length() > 50000 &&
                isLandscapeJpeg(f) &&
                !artworks.any((a) => a.id == art.id)) {
              artworks.add(art);
            }
          }
        }
      } catch (_) {}
    }

    return artworks;
  }

  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Dynamically fetches a brand-new 4K Landscape Oil Painting online:
  /// Prioritizes the 860+ CC0 Oil Painting pool at The Cleveland Museum of Art CDN,
  /// plus any un-downloaded Curated World Museum masterpieces.
  Future<Artwork?> fetchRandomOnlineArtwork({List<String> excludeIds = const []}) async {
    await init();

    // 1. Önce 866+ eserlik yüksek hızlı Cleveland Museum 4K CC0 Yağlıboya havuzundan yeni eser ara
    Artwork? art = await _fetchFromClevelandMuseum(excludeIds);
    // 2. Yedek olarak küratörlü dünya müzeleri havuzunu dene
    art ??= await _fetchFromCuratedWorldMuseums(excludeIds);
    art ??= await _fetchFromMetMuseum(excludeIds);

    return art;
  }

  Future<Artwork?> _fetchFromCuratedWorldMuseums(List<String> excludeIds) async {
    final random = Random();
    final available = curatedMuseumPool.where((item) {
      final idStr = slugify('${item['artist']}_${item['title']}');
      final targetPath = p.join(_paintingsDir.path, '$idStr.jpg');
      final mediumLower = (item['medium'] ?? '').toLowerCase();
      return mediumLower.contains('oil') &&
          !excludeIds.contains(item['id']) &&
          !excludeIds.contains(idStr) &&
          !File(targetPath).existsSync();
    }).toList();
    if (available.isEmpty) return null;

    final selected = available[random.nextInt(available.length)];
    final title = selected['title']!;
    final artist = selected['artist']!;
    final idStr = slugify('${artist}_$title');
    final targetFilePath = p.join(_paintingsDir.path, '$idStr.jpg');

    try {
      final imgResponse = await http
          .get(
            Uri.parse(selected['url']!),
            headers: {
              'User-Agent':
                  'TheFrameScreensaver/1.0 (Linux; x86_64; contact: art-screensaver@local.org)',
              'Accept': 'image/jpeg,image/*,*/*',
            },
          )
          .timeout(const Duration(seconds: 25));

      if (imgResponse.statusCode == 200 && imgResponse.bodyBytes.length > 50000) {
        final file = File(targetFilePath);
        await file.writeAsBytes(imgResponse.bodyBytes);

        if (!isLandscapeJpeg(file)) {
          await file.delete();
          return null;
        }

        final newArt = Artwork(
          id: idStr,
          title: title,
          artist: artist,
          year: selected['year']!,
          medium: selected['medium']!,
          museum: selected['museum']!,
          localFilePath: targetFilePath,
          remoteImageUrl: selected['url'],
        );

        await _saveArtworkToCatalog(newArt);
        return newArt;
      }
    } catch (_) {}
    return null;
  }

  Future<Artwork?> _fetchFromClevelandMuseum(List<String> excludeIds) async {
    final random = Random();

    // 866 adet CC0 yağlıboya tablo havuzunda en fazla 6 farklı sayfa (35'erli) dene
    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        final skip = random.nextInt(800);
        final url = Uri.parse(
          'https://openaccess-api.clevelandart.org/api/artworks/?has_image=1&type=Painting&q=oil&cc0=1&skip=$skip&limit=35',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent':
                'TheFrameScreensaver/1.0 (Linux; x86_64; contact: art-screensaver@local.org)',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = List<dynamic>.from(data['data'] as List<dynamic>? ?? []);
        items.shuffle(random);

        for (final item in items) {
          final images = item['images'] as Map<String, dynamic>?;
          if (images == null) continue;

          final web = images['web'] as Map<String, dynamic>?;
          final printImg = images['print'] as Map<String, dynamic>?;
          final imgObj = printImg ?? web;
          if (imgObj == null) continue;

          final widthStr = imgObj['width']?.toString() ?? '0';
          final heightStr = imgObj['height']?.toString() ?? '0';
          final w = double.tryParse(widthStr) ?? 0;
          final h = double.tryParse(heightStr) ?? 0;
          if (h < 800) continue;
          final ratio = w / h;
          // İndirmeden önce MSI 27" PRO MP275Q (16:9 = 1.78) oranına uyum kontrolü:
          // Yalnızca 1.45 - 2.10 arasındaki geniş yatay (3:2, 16:10, 16:9) tablolar indirilir!
          if (ratio < 1.45 || ratio > 2.10) continue;

          final technique = item['technique']?.toString() ?? '';
          final techLower = technique.toLowerCase();
          // Yalnızca gerçek yağlıboya (oil on canvas / panel / fabric / wood) eserleri kabul et
          if (!techLower.contains('oil')) continue;
          if (techLower.contains('clamshell') ||
              techLower.contains('mural') ||
              techLower.contains('fresco') ||
              techLower.contains('silk') ||
              techLower.contains('triptych') ||
              techLower.contains('tabernacle')) {
            continue;
          }

          final title = item['title']?.toString() ?? 'Masterpiece';
          final titleLower = title.toLowerCase();
          final typeLower = (item['type']?.toString() ?? '').toLowerCase();
          if (titleLower.contains('scroll') ||
              titleLower.contains('emaki') ||
              titleLower.contains('fan') ||
              titleLower.contains('album') ||
              titleLower.contains('fragment') ||
              titleLower.contains('mural') ||
              titleLower.contains('cassone') ||
              titleLower.contains('icon') ||
              typeLower.contains('scroll')) {
            continue;
          }

          final imgUrl = imgObj['url']?.toString();
          if (imgUrl == null || imgUrl.isEmpty) continue;

          final creators = item['creators'] as List<dynamic>?;
          String artist = '';
          if (creators != null && creators.isNotEmpty) {
            final desc = creators[0]['description']?.toString() ?? '';
            final parenIdx = desc.indexOf('(');
            artist = (parenIdx > 0 ? desc.substring(0, parenIdx) : desc).trim();
          }
          // Anonim / bilinmeyen ("Master Artist" vb.) eserleri atla, gerçek ressamları tercih et
          if (artist.isEmpty ||
              artist.toLowerCase() == 'master artist' ||
              artist.toLowerCase().contains('unknown') ||
              artist.toLowerCase().contains('anonymous')) {
            continue;
          }

          final slugId = slugify('${artist}_$title');
          if (slugId.isEmpty || excludeIds.contains(slugId)) continue;

          final targetFilePath = p.join(_paintingsDir.path, '$slugId.jpg');
          // Zaten indirilmişse atla ve gerçekten YENİ bir eser bul
          if (await File(targetFilePath).exists()) {
            continue;
          }

          final imgResponse = await http.get(
            Uri.parse(imgUrl),
            headers: {
              'User-Agent':
                  'TheFrameScreensaver/1.0 (Linux; x86_64; contact: art-screensaver@local.org)',
            },
          ).timeout(const Duration(seconds: 25));

          if (imgResponse.statusCode == 200 &&
              imgResponse.bodyBytes.length > 50000) {
            final file = File(targetFilePath);
            await file.writeAsBytes(imgResponse.bodyBytes);

            if (!isLandscapeJpeg(file)) {
              await file.delete();
              continue;
            }

            // Portre / figüratif eser ise baş hizasını koruyacak focalY ata
            double? autoFocalY;
            if (titleLower.contains('portrait') ||
                titleLower.contains('madame') ||
                titleLower.contains('monsieur') ||
                titleLower.contains('lady') ||
                titleLower.contains('woman') ||
                titleLower.contains('family')) {
              autoFocalY = -0.60;
            }

            final newArt = Artwork(
              id: slugId,
              title: title,
              artist: artist,
              year: item['creation_date']?.toString() ?? '',
              medium: technique,
              museum: 'The Cleveland Museum of Art',
              localFilePath: targetFilePath,
              remoteImageUrl: imgUrl,
              focalY: autoFocalY,
            );

            await _saveArtworkToCatalog(newArt);
            return newArt;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<Artwork?> _fetchFromMetMuseum(List<String> excludeIds) async {
    try {
      final random = Random();
      final objectId =
          curatedLandscapeMetIds[random.nextInt(curatedLandscapeMetIds.length)];

      final url = Uri.parse(
          'https://collectionapi.metmuseum.org/public/collection/v1/objects/$objectId');
      final response = await http
          .get(url, headers: {'User-Agent': 'TheFrameScreensaver/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final primaryImage = data['primaryImage'] as String?;
        if (primaryImage != null && primaryImage.isNotEmpty) {
          final title = data['title'] as String? ?? 'Untitled';
          final artist = data['artistDisplayName'] as String? ?? 'Master Artist';
          final slugId = slugify('${artist}_$title');
          final idStr = slugId.isNotEmpty ? slugId : 'artwork_$objectId';
          if (excludeIds.contains(idStr)) return null;

          final targetFilePath = p.join(_paintingsDir.path, '$idStr.jpg');

          if (await File(targetFilePath).exists()) {
            final existingCatalog = await loadAllArtworks();
            final match = existingCatalog.where((a) => a.id == idStr).firstOrNull;
            if (match != null) return match;
          }

          final imgResponse = await http
              .get(Uri.parse(primaryImage))
              .timeout(const Duration(seconds: 25));

          if (imgResponse.statusCode == 200 && imgResponse.bodyBytes.length > 50000) {
            final file = File(targetFilePath);
            await file.writeAsBytes(imgResponse.bodyBytes);

            if (!isLandscapeJpeg(file)) {
              await file.delete();
              return null;
            }

            final newArt = Artwork(
              id: idStr,
              title: title,
              artist: artist,
              year: data['objectDate'] as String? ?? '',
              medium: data['medium'] as String? ?? 'Oil on canvas',
              museum: data['repository'] as String? ?? 'The Met, New York',
              localFilePath: targetFilePath,
              remoteImageUrl: primaryImage,
            );

            await _saveArtworkToCatalog(newArt);
            return newArt;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveArtworkToCatalog(Artwork art) async {
    final all = await loadAllArtworks();
    if (!all.any((a) => a.id == art.id)) {
      all.add(art);
      final catalogJson = jsonEncode(
        all.where((a) => a.localFilePath != null).map((a) => a.toJson()).toList(),
      );
      await _catalogFile.writeAsString(catalogJson);
    }
  }

  /// Background downloader for offline enrichment (Landscape Only)
  Future<void> syncCuratedMasterpieces() async {
    await init();
    final existingArtworks = await loadAllArtworks();
    final existingIds = existingArtworks.map((a) => a.id).toSet();

    for (final item in curatedMuseumPool.take(5)) {
      final id = item['id']!;
      if (!existingIds.contains(id)) {
        await fetchRandomOnlineArtwork(excludeIds: existingIds.toList());
        existingIds.add(id);
      }
    }
  }
}

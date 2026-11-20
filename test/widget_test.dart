import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_frame_screensaver/core/models/artwork.dart';
import 'package:the_frame_screensaver/core/models/frame_settings.dart';
import 'package:the_frame_screensaver/data/artwork_repository.dart';
import 'package:the_frame_screensaver/main.dart';
import 'package:the_frame_screensaver/presentation/controllers/screensaver_controller.dart';
import 'package:the_frame_screensaver/presentation/widgets/frame_canvas.dart';
import 'package:the_frame_screensaver/presentation/widgets/museum_plaque.dart';

void main() {
  testWidgets('TheFrameApp mounts cleanly', (WidgetTester tester) async {
    final controller = ScreensaverController();
    await tester.pumpWidget(TheFrameApp(
      controller: controller,
      isScreensaverMode: false,
    ));

    expect(find.byType(TheFrameApp), findsOneWidget);
  });

  test('ScreensaverController cycles through Samsung modes with toggleFitMode', () {
    final controller = ScreensaverController();
    expect(controller.settings.fitMode, ArtworkFitMode.samsungNoMat);

    controller.toggleFitMode();
    expect(controller.settings.fitMode, ArtworkFitMode.smartMat);

    controller.toggleFitMode();
    expect(controller.settings.fitMode, ArtworkFitMode.samsungNoMat);
  });

  testWidgets('FrameCanvas in Samsung mode displays edge-to-edge with BoxFit.cover and no plaque or bezel', (WidgetTester tester) async {
    const artwork = Artwork(
      id: 'test-art',
      title: 'Starry Night',
      artist: 'Van Gogh',
      year: '1889',
      medium: 'Oil on canvas',
      museum: 'MoMA',
      assetPath: 'assets/paintings/van_gogh_cypresses.jpg',
    );

    const settings = FrameSettings(
      fitMode: ArtworkFitMode.samsungNoMat,
      showMuseumPlaque: false,
      bezelStyle: FrameBezelStyle.none,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FrameCanvas(
            artwork: artwork,
            settings: settings,
          ),
        ),
      ),
    );

    // In Samsung mode:
    // 1. Plaque MUST NOT be rendered
    expect(find.byType(MuseumPlaque), findsNothing);

    // 2. Image widget has BoxFit.cover (Aspect ratio MUST be preserved, never fill!)
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.fit, BoxFit.cover);
  });

  test('ScreensaverController does not repeat artworks in the same session', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_session_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      final controller = ScreensaverController(repository: repo);
      await controller.initialize();

      final shownIds = <String>{};
      shownIds.add(controller.currentArtwork.id);

      final totalToAdvance = controller.artworks.length - 1;
      for (int i = 0; i < totalToAdvance; i++) {
        controller.nextArtwork();
        expect(shownIds.contains(controller.currentArtwork.id), isFalse);
        shownIds.add(controller.currentArtwork.id);
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ArtworkRepository.slugify generates clean human-readable filenames and transliterates diacritics', () {
    final slug1 = ArtworkRepository.slugify('Vincent van Gogh - Wheat Field');
    expect(slug1, 'vincent_van_gogh_wheat_field');
    expect(slug1.startsWith('met'), isFalse);

    final slug2 = ArtworkRepository.slugify('Claude Monet - Cliff Walk at Pourville');
    expect(slug2, 'claude_monet_cliff_walk_at_pourville');
    expect(slug2.startsWith('met'), isFalse);

    // Diakritik harf testi (harf düşmesi engellenmeli)
    final slug3 = ArtworkRepository.slugify('Édouard Vuillard - Café Wepler');
    expect(slug3, 'edouard_vuillard_cafe_wepler');

    final slug4 = ArtworkRepository.slugify('Georges Seurat - Study for "Bathers at Asnières"');
    expect(slug4, 'georges_seurat_study_for_bathers_at_asnieres');

    final slug5 = ArtworkRepository.slugify('Juan van der Hamen y Léon - Still Life with Sweets');
    expect(slug5, 'juan_van_der_hamen_y_leon_still_life_with_sweets');
  });

  test('ArtworkRepository.isViolentOrInappropriate filters gruesome and violent themes', () {
    expect(ArtworkRepository.isViolentOrInappropriate("Perseus's Last Duty"), isTrue);
    expect(ArtworkRepository.isViolentOrInappropriate("The Raft of the Medusa"), isTrue);
    expect(ArtworkRepository.isViolentOrInappropriate("The Christian Martyr's Last Prayer"), isTrue);
    expect(ArtworkRepository.isViolentOrInappropriate("The Starry Night"), isFalse);
    expect(ArtworkRepository.isViolentOrInappropriate("Among the Sierra Nevada, California"), isFalse);
  });

  test('FrameSettings serializes and deserializes backlight dimming and cycle minutes accurately', () {
    const original = FrameSettings(
      matteDimmingFactor: 0.72,
      enableAmbientDimming: true,
      autoCycleSeconds: 180,
      fitMode: ArtworkFitMode.samsungNoMat,
      enableCanvasTexture: true,
    );

    final json = original.toJson();
    expect(json['matteDimmingFactor'], 0.72);
    expect(json['autoCycleSeconds'], 180);
    expect(json['enableAmbientDimming'], true);

    final recovered = FrameSettings.fromJson(json);
    expect(recovered.matteDimmingFactor, 0.72);
    expect(recovered.autoCycleSeconds, 180);
    expect(recovered.enableAmbientDimming, true);
    expect(recovered.fitMode, ArtworkFitMode.samsungNoMat);
  });

  test('ArtworkRepository saves, loads, and clears shown history to disk', () async {
    final tempDir = Directory.systemTemp.createTempSync('repo_test_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      expect(await repo.loadShownHistory(), isEmpty);

      await repo.saveShownHistory(['art-1', 'art-2', 'art-3']);
      final loaded = await repo.loadShownHistory();
      expect(loaded, ['art-1', 'art-2', 'art-3']);

      await repo.clearShownHistory();
      expect(await repo.loadShownHistory(), isEmpty);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ScreensaverController remembers shown artworks across sessions via disk', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_history_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      final controller1 = ScreensaverController(repository: repo);
      await controller1.initialize();

      final firstShownId = controller1.currentArtwork.id;
      expect(controller1.shownArtworkIds.contains(firstShownId), isTrue);

      // Diskteki geçmişi doğrula
      final savedHistory = await repo.loadShownHistory();
      expect(savedHistory.contains(firstShownId), isTrue);

      // Yeni bir oturum başlatıldığında daha önce gösterilen eser tekrar ilk olarak seçilmemeli (alternatif varsa)
      final controller2 = ScreensaverController(repository: repo);
      await controller2.initialize();

      if (controller2.artworks.length > 1) {
        expect(controller2.currentArtwork.id, isNot(firstShownId));
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ScreensaverController resets history when maxHistoryCapacity is reached to prevent file bloat', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_cap_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      // Kapasiteyi küçük tutarak (ör. 3) sıfırlama mekanizmasını test et
      final controller = ScreensaverController(
        repository: repo,
        maxHistoryCapacity: 3,
      );
      await controller.initialize();

      // İlerleterek geçmişi doldur
      controller.nextArtwork();
      controller.nextArtwork();
      controller.nextArtwork();

      // maxHistoryCapacity aşıldığında dosya sonsuza kadar büyümemeli, sıfırlanmalı
      expect(controller.shownArtworkIds.length, lessThanOrEqualTo(3));
      final savedHistory = await repo.loadShownHistory();
      expect(savedHistory.length, lessThanOrEqualTo(3));
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ScreensaverController resets history when all artworks are shown without back-to-back repetition', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_cycle_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      final controller = ScreensaverController(repository: repo);
      await controller.initialize();

      final total = controller.artworks.length;
      final firstRoundIds = <String>{controller.currentArtwork.id};

      for (int i = 0; i < total - 1; i++) {
        controller.nextArtwork();
        firstRoundIds.add(controller.currentArtwork.id);
      }

      // Tüm eserler ilk turda gösterildi
      expect(firstRoundIds.length, total);

      final lastIdBeforeReset = controller.currentArtwork.id;
      // Bir sonraki geçiş döngüyü sıfırlayarak yeni bir eser seçmeli
      controller.nextArtwork();

      if (total > 1) {
        // Sıfırlama sonrasında hemen bir önceki eser peş peşe tekrarlanmamalı
        expect(controller.currentArtwork.id, isNot(lastIdBeforeReset));
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ArtworkRepository auto-registers uncataloged archive paintings into rotation', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_manual_');
    try {
      final paintingsDir = Directory('${tempDir.path}/paintings')..createSync(recursive: true);
      // 1600x900 PNG header (> 50KB padding)
      final manualFile = File('${paintingsDir.path}/manual_test_painting.png');
      final bytes = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, // IHDR length
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x06, 0x40, // width = 1600
        0x00, 0x00, 0x03, 0x84, // height = 900
        ...List.filled(55000, 0),
      ];
      manualFile.writeAsBytesSync(bytes);

      final repo = ArtworkRepository(cacheDir: tempDir);
      final controller = ScreensaverController(repository: repo);
      await controller.initialize();

      expect(
        controller.artworks.any((a) => a.id == 'local-manual_test_painting'),
        isTrue,
      );

      final visited = <String>{controller.currentArtwork.id};
      for (int i = 0; i < controller.artworks.length - 1; i++) {
        controller.nextArtwork();
        visited.add(controller.currentArtwork.id);
      }
      expect(visited.contains('local-manual_test_painting'), isTrue);
      expect(visited.length, controller.artworks.length);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ScreensaverController.initialize does not repeat the last shown artwork when starting a new cycle', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_wrap_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      final allIds = ArtworkRepository.bundledMasterpieces.map((a) => a.id).toList();
      expect(allIds.length, greaterThanOrEqualTo(2));

      // Tüm eserler daha önce gösterilmiş; en son gösterilen allIds.last
      await repo.saveShownHistory(allIds);

      for (int run = 0; run < 10; run++) {
        await repo.saveShownHistory(allIds);
        final controller = ScreensaverController(repository: repo);
        await controller.initialize();
        expect(controller.currentArtwork.id, isNot(allIds.last));
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ScreensaverController evicts oldest history via FIFO instead of wiping all history', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_fifo_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      await repo.saveShownHistory(['old-1', 'old-2', 'recent-3']);

      final controller = ScreensaverController(
        repository: repo,
        maxHistoryCapacity: 3,
      );
      await controller.initialize();

      // Kapasite 3: en eski 'old-1' çıkarılmalı, 'old-2', 'recent-3' ve yeni gösterilen kalmalı
      expect(controller.shownArtworkIds.length, 3);
      expect(controller.shownArtworkIds.contains('old-1'), isFalse);
      expect(controller.shownArtworkIds.contains('old-2'), isTrue);
      expect(controller.shownArtworkIds.contains('recent-3'), isTrue);
      expect(controller.shownArtworkIds.contains(controller.currentArtwork.id), isTrue);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  test('ArtworkRepository.saveShownHistory handles rapid concurrent writes without corruption', () async {
    final tempDir = Directory.systemTemp.createTempSync('screensaver_conc_');
    try {
      final repo = ArtworkRepository(cacheDir: tempDir);
      await Future.wait([
        repo.saveShownHistory(['a']),
        repo.saveShownHistory(['a', 'b']),
        repo.saveShownHistory(['a', 'b', 'c']),
        repo.saveShownHistory(['a', 'b', 'c', 'd']),
      ]);

      final loaded = await repo.loadShownHistory();
      expect(loaded, ['a', 'b', 'c', 'd']);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}

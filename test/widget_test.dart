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
      showMuseumPlaque: true,
      bezelStyle: FrameBezelStyle.oak,
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
    final controller = ScreensaverController();
    await controller.initialize();

    final shownIds = <String>{};
    shownIds.add(controller.currentArtwork.id);

    final totalToAdvance = controller.artworks.length - 1;
    for (int i = 0; i < totalToAdvance; i++) {
      controller.nextArtwork();
      expect(shownIds.contains(controller.currentArtwork.id), isFalse);
      shownIds.add(controller.currentArtwork.id);
    }
  });

  test('ArtworkRepository.slugify generates clean human-readable filenames without met prefix', () {
    final slug1 = ArtworkRepository.slugify('Vincent van Gogh - Wheat Field');
    expect(slug1, 'vincent_van_gogh_wheat_field');
    expect(slug1.startsWith('met'), isFalse);

    final slug2 = ArtworkRepository.slugify('Claude Monet - Cliff Walk at Pourville');
    expect(slug2, 'claude_monet_cliff_walk_at_pourville');
    expect(slug2.startsWith('met'), isFalse);
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
}

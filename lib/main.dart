import 'package:flutter/material.dart';
import 'presentation/controllers/screensaver_controller.dart';
import 'presentation/screens/screensaver_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final isPreview = args.contains('--preview') || args.contains('-p') || args.contains('--windowed');
  final isScreensaver = !isPreview;
  final shouldLockOnExit = args.contains('--lock-on-exit');

  final controller = ScreensaverController();
  await controller.initialize();

  runApp(TheFrameApp(
    controller: controller,
    isScreensaverMode: isScreensaver,
    shouldLockOnExit: shouldLockOnExit,
  ));
}

class TheFrameApp extends StatelessWidget {
  final ScreensaverController controller;
  final bool isScreensaverMode;
  final bool shouldLockOnExit;

  const TheFrameApp({
    super.key,
    required this.controller,
    required this.isScreensaverMode,
    this.shouldLockOnExit = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samsung The Frame Art Screensaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'serif',
      ),
      home: ScreensaverScreen(
        controller: controller,
        isScreensaverMode: isScreensaverMode,
        shouldLockOnExit: shouldLockOnExit,
      ),
    );
  }
}

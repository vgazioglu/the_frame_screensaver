import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/screensaver_controller.dart';
import '../widgets/frame_canvas.dart';
import '../widgets/settings_dialog.dart';

class ScreensaverScreen extends StatefulWidget {
  final ScreensaverController controller;
  final bool isScreensaverMode;
  final bool shouldLockOnExit;

  const ScreensaverScreen({
    super.key,
    required this.controller,
    this.isScreensaverMode = true,
    this.shouldLockOnExit = false,
  });

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  final FocusNode _focusNode = FocusNode();
  Offset? _initialPointerPos;
  bool _isExiting = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _requestExit() {
    if (_isExiting) return;
    _isExiting = true;

    // Eğer sistem ekran koruyucusu / kilit modundaysa çıkışta Cinnamon kilit ekranını tetikle:
    if (widget.shouldLockOnExit) {
      _triggerSystemLock();
    }
    exit(0);
  }

  void _triggerSystemLock() {
    try {
      if (File('/usr/bin/cinnamon-screensaver-command').existsSync()) {
        Process.runSync('cinnamon-screensaver-command', ['--lock']);
        return;
      }
      if (File('/usr/bin/loginctl').existsSync()) {
        Process.runSync('loginctl', ['lock-session']);
        return;
      }
      if (File('/usr/bin/xdg-screensaver').existsSync()) {
        Process.runSync('xdg-screensaver', ['lock']);
        return;
      }
    } catch (_) {}
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Esc: Menü açıksa menüyü kapat, kapalıysa ekran koruyucudan çık
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showSettings) {
        setState(() => _showSettings = false);
        return;
      }
      if (widget.isScreensaverMode) {
        _requestExit();
        return;
      }
    }

    // Enter ekran koruyucudan çıkış
    if (widget.isScreensaverMode && !_showSettings && event.logicalKey == LogicalKeyboardKey.enter) {
      _requestExit();
      return;
    }

    // 'S' tuşu: Ayarlar menüsünü aç / kapat
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      setState(() => _showSettings = !_showSettings);
      return;
    }

    // 'C' tuşu: Kafa kesilmeyen Müze Paspartusu / Tam Ekran geçişi
    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      widget.controller.toggleFitMode();
      return;
    }

    // 'N' tuşu: Yeni online 4K tablo indir
    if (event.logicalKey == LogicalKeyboardKey.keyN) {
      widget.controller.fetchNextOnlinePainting();
      return;
    }

    // Gezinme Tuşları: Sadece Sağ ve Sol Ok Tuşları
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        widget.controller.nextArtwork();
      case LogicalKeyboardKey.arrowLeft:
        widget.controller.previousArtwork();
      case LogicalKeyboardKey.keyF:
        widget.controller.cycleFrameStyle();
      case LogicalKeyboardKey.keyM:
        widget.controller.cycleMatStyle();
      case LogicalKeyboardKey.keyI:
        widget.controller.togglePlaque();
      case LogicalKeyboardKey.keyT:
        widget.controller.toggleCanvasTexture();
      case LogicalKeyboardKey.keyB:
        widget.controller.cycleBacklightBrightness();
      case LogicalKeyboardKey.keyQ:
        if (widget.isScreensaverMode) _requestExit();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // 🖱️ SAĞ TIK: Ayarlar Menüsünü Aç / Kapat
    if (event.buttons == kSecondaryMouseButton) {
      setState(() {
        _showSettings = !_showSettings;
      });
      return;
    }

    // Menü açıkken sol tık menü içi seçimler içindir, engelleme yapma
    if (_showSettings) {
      return;
    }

    // Sol tık ekran koruyucu modunda çıkış yapar
    if (widget.isScreensaverMode && event.buttons == kPrimaryMouseButton) {
      _requestExit();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.isScreensaverMode || _showSettings) return;

    if (_initialPointerPos == null) {
      _initialPointerPos = event.position;
      return;
    }

    final distance = (event.position - _initialPointerPos!).distance;
    // Masa titreşimlerini engellemek için belirgin fare hareketi aranır (> 45px)
    if (distance > 45.0) {
      _requestExit();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC49F6E),
          ),
        ),
      );
    }

    final artwork = widget.controller.currentArtwork;
    final settings = widget.controller.settings;
    final isOnlineLoading = widget.controller.isFetchingOnline;
    final statusMsg = widget.controller.statusMessage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        cursor: _showSettings ? SystemMouseCursors.basic : SystemMouseCursors.none,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ana Tablo (Yumuşak Fade Geçişi)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 1800),
                switchInCurve: Curves.easeInOutSine,
                switchOutCurve: Curves.easeInOutSine,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: FrameCanvas(
                  key: ValueKey('${artwork.id}_${settings.fitMode}_${settings.matStyle}_${settings.bezelStyle}'),
                  artwork: artwork,
                  settings: settings,
                ),
              ),

              // 2. Sağ Üst İndirme / Durum Rozeti
              if (isOnlineLoading || statusMsg != null)
                Positioned(
                  top: 24.0,
                  right: 28.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 9.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDD18181B),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: const Color(0x33C49F6E),
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 10.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOnlineLoading) ...[
                          const SizedBox(
                            width: 14.0,
                            height: 14.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Color(0xFFC49F6E),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                        ],
                        Text(
                          statusMsg ?? 'İndiriliyor...',
                          style: const TextStyle(
                            color: Color(0xFFE8E8E8),
                            fontSize: 12.5,
                            fontFamily: 'serif',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Sağ Tık Ayarlar Menüsü (Floating Settings Overlay)
              if (_showSettings)
                Positioned.fill(
                  child: Stack(
                    children: [
                      // Karartılmış Arka Plan (Dışına sol tıklandığında menüyü kapatır)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _showSettings = false),
                          child: Container(
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      // Menü Kutusu (Tıklamaları içeriğe aktarır)
                      Center(
                        child: SettingsOverlay(
                          controller: widget.controller,
                          onClose: () => setState(() => _showSettings = false),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

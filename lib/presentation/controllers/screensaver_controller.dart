import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/artwork.dart';
import '../../core/models/frame_settings.dart';
import '../../data/artwork_repository.dart';

class ScreensaverController extends ChangeNotifier {
  final ArtworkRepository _repository;

  List<Artwork> _artworks = [...ArtworkRepository.bundledMasterpieces];
  int _currentIndex = 0;
  final List<int> _history = [];
  final Set<String> _seenInSession = <String>{};
  FrameSettings _settings = const FrameSettings();
  bool _isLoading = true;
  bool _isFetchingOnline = false;
  String? _statusMessage;
  Timer? _cycleTimer;

  ScreensaverController({ArtworkRepository? repository})
      : _repository = repository ?? ArtworkRepository();

  List<Artwork> get artworks => _artworks;
  int get currentIndex => _currentIndex;
  Artwork get currentArtwork => _artworks.isNotEmpty
      ? _artworks[_currentIndex]
      : ArtworkRepository.bundledMasterpieces.first;
  FrameSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isFetchingOnline => _isFetchingOnline;
  String? get statusMessage => _statusMessage;
  int get unseenInSessionCount =>
      _artworks.where((a) => !_seenInSession.contains(a.id)).length;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _repository.loadSettings();
      final loaded = await _repository.loadAllArtworks();
      if (loaded.isNotEmpty) {
        _artworks = loaded;
      }
    } catch (_) {
      _artworks = [...ArtworkRepository.bundledMasterpieces];
    } finally {
      _isLoading = false;

      // 1. Birinci resmi İLK ANDAN İTİBAREN rastgele seç:
      if (_artworks.isNotEmpty) {
        _currentIndex = Random().nextInt(_artworks.length);
        _seenInSession.add(_artworks[_currentIndex].id);
      }

      notifyListeners();
      _startAutoCycleTimer();

      // Gösterimde kalan tablo havuzunu kontrol et, tükenmeden arka planda önceden indir:
      _checkAndPrefetchBuffer();
    }
  }

  void _startAutoCycleTimer() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(
      Duration(seconds: _settings.autoCycleSeconds),
      (_) => nextArtwork(),
    );
  }

  void updateSettings(FrameSettings newSettings) {
    final timerChanged = _settings.autoCycleSeconds != newSettings.autoCycleSeconds;
    _settings = newSettings;
    if (timerChanged) {
      _startAutoCycleTimer();
    }
    notifyListeners();
    _repository.saveSettings(_settings);
  }

  /// Her geçişte oturumda daha önce gösterilmemiş RASTGELE bir tablo seçer.
  /// Aynı oturumda bir gösterilen tablo bir daha gösterilmez!
  void nextArtwork({bool random = true}) {
    if (_artworks.isEmpty) return;

    _history.add(_currentIndex);
    if (_history.length > 50) _history.removeAt(0);

    // Oturumda henüz gösterilmemiş (unseen) tabloları filtrele:
    final unvisited = _artworks.where((a) => !_seenInSession.contains(a.id)).toList();

    if (unvisited.isNotEmpty) {
      final nextArt = random
          ? unvisited[Random().nextInt(unvisited.length)]
          : unvisited.first;
      _currentIndex = _artworks.indexOf(nextArt);
      _seenInSession.add(nextArt.id);
    } else {
      // Gösterimde kalan tablo kalmadıysa:
      // Hemen önceden indirme mekanizmasını zorla devreye sok
      _checkAndPrefetchBuffer(forceImmediate: true);

      // Tüm mevcut havuz tüketildiyse oturum hafızasını sıfırla ve mevcut tablodan farklı olanı seç
      _seenInSession.clear();
      final candidates = _artworks.where((a) => a.id != currentArtwork.id).toList();
      if (candidates.isNotEmpty) {
        final nextArt = candidates[Random().nextInt(candidates.length)];
        _currentIndex = _artworks.indexOf(nextArt);
        _seenInSession.add(nextArt.id);
      }
    }

    notifyListeners();

    // Gösterimde kalan tablo sayısı 3 veya daha azsa arka planda sessizce yeni şaheserler indir:
    _checkAndPrefetchBuffer();
  }

  /// Önceki tabloya (geçmişe) döner
  void previousArtwork() {
    if (_artworks.isEmpty) return;

    if (_history.isNotEmpty) {
      _currentIndex = _history.removeLast();
    } else {
      _currentIndex = (_currentIndex - 1 + _artworks.length) % _artworks.length;
    }

    notifyListeners();
  }

  /// Kalan tablo sayısı azaldığında (<= 3) veya tükendiğinde önceden arka planda yeni 4K tablolar indirir.
  Future<void> _checkAndPrefetchBuffer({bool forceImmediate = false}) async {
    if (_isFetchingOnline) return;

    final unvisitedCount = unseenInSessionCount;
    if (unvisitedCount > 3 && !forceImmediate) return;

    _isFetchingOnline = true;
    notifyListeners();

    try {
      final currentIds = _artworks.map((a) => a.id).toList();
      final newArt = await _repository.fetchRandomOnlineArtwork(excludeIds: currentIds);

      if (newArt != null && !_artworks.any((a) => a.id == newArt.id)) {
        _artworks.add(newArt);

        // Eğer hiç gösterilecek tablo kalmamışsa hemen bu yeni indirilen şahesere geç:
        if (unvisitedCount == 0 && forceImmediate) {
          _currentIndex = _artworks.length - 1;
          _seenInSession.add(newArt.id);
          _statusMessage = '🏛️ Yeni Şaheser: ${newArt.title}';
        }
      }
    } catch (_) {
    } finally {
      _isFetchingOnline = false;
      notifyListeners();

      if (_statusMessage != null) {
        Timer(const Duration(seconds: 4), () {
          _statusMessage = null;
          notifyListeners();
        });
      }
    }
  }

  /// Manuel olarak 'N' tuşu veya menü butonu ile yeni online 4K şaheser indirir
  Future<void> fetchNextOnlinePainting() async {
    if (_isFetchingOnline) return;

    _isFetchingOnline = true;
    _statusMessage = '🏛️ Yeni 4K şaheser indiriliyor...';
    notifyListeners();

    try {
      final currentIds = _artworks.map((a) => a.id).toList();
      final newArt = await _repository.fetchRandomOnlineArtwork(excludeIds: currentIds);

      if (newArt != null) {
        _history.add(_currentIndex);
        final idx = _artworks.indexWhere((a) => a.id == newArt.id);
        if (idx == -1) {
          _artworks.add(newArt);
          _currentIndex = _artworks.length - 1;
        } else {
          _currentIndex = idx;
        }
        _seenInSession.add(newArt.id);
        _statusMessage = '✅ ${newArt.title} yüklendi';
      } else {
        nextArtwork();
        _statusMessage = null;
      }
    } catch (_) {
      nextArtwork();
      _statusMessage = null;
    } finally {
      _isFetchingOnline = false;
      notifyListeners();

      Timer(const Duration(seconds: 4), () {
        _statusMessage = null;
        notifyListeners();
      });
    }
  }

  void toggleFitMode() {
    final next = _settings.fitMode == ArtworkFitMode.samsungNoMat
        ? ArtworkFitMode.smartMat
        : ArtworkFitMode.samsungNoMat;
    updateSettings(_settings.copyWith(fitMode: next));
    _statusMessage = '📺 ${next.displayName}';
    notifyListeners();
    Timer(const Duration(seconds: 3), () {
      if (_statusMessage?.startsWith('📺') ?? false) {
        _statusMessage = null;
        notifyListeners();
      }
    });
  }

  void cycleFrameStyle() {
    final values = FrameBezelStyle.values;
    final nextIndex = (_settings.bezelStyle.index + 1) % values.length;
    updateSettings(_settings.copyWith(bezelStyle: values[nextIndex]));
  }

  void cycleMatStyle() {
    final values = PassepartoutStyle.values;
    final nextIndex = (_settings.matStyle.index + 1) % values.length;
    updateSettings(_settings.copyWith(matStyle: values[nextIndex]));
  }

  void togglePlaque() {
    updateSettings(_settings.copyWith(
      showMuseumPlaque: !_settings.showMuseumPlaque,
    ));
  }

  void toggleCanvasTexture() {
    updateSettings(_settings.copyWith(
      enableCanvasTexture: !_settings.enableCanvasTexture,
    ));
  }

  void _showTransientStatus(String msg) {
    _statusMessage = msg;
    notifyListeners();
    Timer(const Duration(seconds: 3), () {
      if (_statusMessage == msg) {
        _statusMessage = null;
        notifyListeners();
      }
    });
  }

  void toggleAmbientDimming() {
    updateSettings(_settings.copyWith(
      enableAmbientDimming: !_settings.enableAmbientDimming,
    ));
    _showTransientStatus(
      _settings.enableAmbientDimming
          ? '🖼️ Samsung The Frame Arka Işık Kısma: Açık'
          : '☀️ Tam Dijital Monitör Parlaklığı: Açık',
    );
  }

  void cycleBacklightBrightness() {
    // 0.85 -> 0.72 -> 1.00 -> 0.85
    final current = _settings.matteDimmingFactor;
    final double next;
    final String label;
    if (current > 0.95) {
      next = 0.85;
      label = '🖼️ The Frame Mat Tuval Işığı (%85 - Doğal Galeri)';
    } else if (current > 0.78) {
      next = 0.72;
      label = '🌙 Loş Galeri Gece Işığı (%72)';
    } else {
      next = 1.00;
      label = '☀️ Tam Dijital Monitör Parlaklığı (%100)';
    }

    updateSettings(_settings.copyWith(
      matteDimmingFactor: next,
      enableAmbientDimming: next < 0.98,
    ));
    _showTransientStatus(label);
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    super.dispose();
  }
}

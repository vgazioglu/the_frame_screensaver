import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/artwork.dart';
import '../../core/models/frame_settings.dart';
import '../../data/artwork_repository.dart';

class ScreensaverController extends ChangeNotifier {
  final ArtworkRepository _repository;
  final int maxHistoryCapacity;

  List<Artwork> _artworks = [...ArtworkRepository.bundledMasterpieces];
  int _currentIndex = 0;
  final List<int> _history = [];
  final Set<String> _shownArtworkIds = <String>{};
  FrameSettings _settings = const FrameSettings();
  bool _isLoading = true;
  bool _isFetchingOnline = false;
  String? _statusMessage;
  Timer? _cycleTimer;

  ScreensaverController({
    ArtworkRepository? repository,
    this.maxHistoryCapacity = 100,
  }) : _repository = repository ?? ArtworkRepository();

  List<Artwork> get artworks => _artworks;
  int get currentIndex => _currentIndex;
  Artwork get currentArtwork => _artworks.isNotEmpty
      ? _artworks[_currentIndex]
      : ArtworkRepository.bundledMasterpieces.first;
  FrameSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isFetchingOnline => _isFetchingOnline;
  String? get statusMessage => _statusMessage;
  Set<String> get shownArtworkIds => Set.unmodifiable(_shownArtworkIds);
  int get unseenCount =>
      _artworks.where((a) => !_shownArtworkIds.contains(a.id)).length;
  int get unseenInSessionCount => unseenCount;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _repository.loadSettings();
      final loaded = await _repository.loadAllArtworks();
      if (loaded.isNotEmpty) {
        _artworks = loaded;
      }

      final savedHistory = await _repository.loadShownHistory();
      _shownArtworkIds.clear();
      _shownArtworkIds.addAll(savedHistory);

      // Kapasite sınırını aştıysa sıfırla
      if (_shownArtworkIds.length >= maxHistoryCapacity) {
        _shownArtworkIds.clear();
      }
    } catch (_) {
      _artworks = [...ArtworkRepository.bundledMasterpieces];
    } finally {
      _isLoading = false;

      // 1. Birinci resmi daha önce gösterilmemiş olanlar arasından rastgele seç:
      if (_artworks.isNotEmpty) {
        var unvisited =
            _artworks.where((a) => !_shownArtworkIds.contains(a.id)).toList();
        if (unvisited.isEmpty) {
          // Tüm eserler daha önce gösterilmiş, döngüyü sıfırla
          _shownArtworkIds.clear();
          unvisited = _artworks;
        }

        final initialArt = unvisited[Random().nextInt(unvisited.length)];
        _currentIndex = _artworks.indexOf(initialArt);
        await _recordArtworkShown(initialArt.id);
      }

      notifyListeners();
      _startAutoCycleTimer();

      // Gösterimde kalan tablo havuzunu kontrol et, tükenmeden arka planda önceden indir:
      _checkAndPrefetchBuffer();
    }
  }

  Future<void> _recordArtworkShown(String id) async {
    _shownArtworkIds.add(id);
    if (_shownArtworkIds.length >= maxHistoryCapacity) {
      _shownArtworkIds.clear();
      _shownArtworkIds.add(id);
    }
    await _repository.saveShownHistory(_shownArtworkIds.toList());
  }

  /// Gösterim geçmişini temizler ve diski sıfırlar
  Future<void> clearHistory() async {
    _shownArtworkIds.clear();
    await _repository.clearShownHistory();
    notifyListeners();
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

  /// Her geçişte daha önce gösterilmemiş RASTGELE bir tablo seçer.
  /// Gösterilen eser diske kaydedilir; tüm eserler bitene kadar tekrarlanmaz.
  void nextArtwork({bool random = true}) {
    if (_artworks.isEmpty) return;

    _history.add(_currentIndex);
    if (_history.length > 50) _history.removeAt(0);

    // Henüz gösterilmemiş (unvisited) tabloları filtrele:
    var unvisited =
        _artworks.where((a) => !_shownArtworkIds.contains(a.id)).toList();

    if (unvisited.isNotEmpty) {
      final nextArt = random
          ? unvisited[Random().nextInt(unvisited.length)]
          : unvisited.first;
      _currentIndex = _artworks.indexOf(nextArt);
    } else {
      // Gösterimde kalan tablo kalmadıysa:
      // Hemen önceden indirme mekanizmasını zorla devreye sok
      _checkAndPrefetchBuffer(forceImmediate: true);

      // Tüm mevcut havuz tüketildiyse hafızayı sıfırla ve mevcut tablodan farklı olanı seç
      _shownArtworkIds.clear();
      if (_artworks.length > 1) {
        _shownArtworkIds.add(currentArtwork.id);
      }
      unvisited =
          _artworks.where((a) => !_shownArtworkIds.contains(a.id)).toList();
      final nextArt = unvisited.isNotEmpty
          ? (random ? unvisited[Random().nextInt(unvisited.length)] : unvisited.first)
          : _artworks.first;
      _currentIndex = _artworks.indexOf(nextArt);
    }

    _recordArtworkShown(currentArtwork.id);
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
          _recordArtworkShown(newArt.id);
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
    _statusMessage = '🏛️ Yeni 4K yağlıboya şaheser indiriliyor...';
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
        _recordArtworkShown(newArt.id);
        _statusMessage = '✅ Yeni Eser İndirildi: ${newArt.title} (${newArt.artist})';
      } else {
        nextArtwork();
        _statusMessage = '⚠️ Sunucu yanıt vermedi, arşivden gösteriliyor';
      }
    } catch (_) {
      nextArtwork();
      _statusMessage = '⚠️ İndirme hatası, arşivden gösteriliyor';
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

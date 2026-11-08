import 'package:flutter/material.dart';
import '../../core/models/frame_settings.dart';
import '../controllers/screensaver_controller.dart';

class SettingsOverlay extends StatelessWidget {
  final ScreensaverController controller;
  final VoidCallback onClose;

  const SettingsOverlay({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final artwork = controller.currentArtwork;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 580.0,
            maxHeight: 740.0,
          ),
          margin: const EdgeInsets.all(24.0),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: const Color(0xF218181B), // 95% opacity deep museum charcoal
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: const Color(0x33C49F6E), // Muted gold/bronze border
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 32.0,
                spreadRadius: 4.0,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      color: Color(0xFFC49F6E),
                      size: 26.0,
                    ),
                    const SizedBox(width: 12.0),
                    const Expanded(
                      child: Text(
                        'THE FRAME — AYARLAR',
                        style: TextStyle(
                          color: Color(0xFFF3EFE6),
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
                      onPressed: onClose,
                      hoverColor: Colors.white10,
                      splashRadius: 20.0,
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Ayarları değiştirmek için tıklayın; menüyü kapatmak için sağ tıklayın veya Esc\'ye basın.',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12.0),
                ),
                const Divider(color: Color(0x22FFFFFF), height: 28.0),

                // 1. Eser Bilgisi Kartı
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0x26C49F6E),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0x33C49F6E),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFC49F6E),
                        size: 20.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artwork.title,
                              style: const TextStyle(
                                color: Color(0xFFFAF8F5),
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              '${artwork.artist}${artwork.year.isNotEmpty ? ' (${artwork.year})' : ''}',
                              style: const TextStyle(
                                color: Color(0xFFD1C7B7),
                                fontSize: 13.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              '🏛️ ${artwork.museum}',
                              style: const TextStyle(
                                color: Color(0xFFA19D95),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // 2. Görüntüleme Modu (Samsung The Frame vs Müze Paspartusu)
                const Text(
                  'GÖRÜNTÜLEME MODU',
                  style: TextStyle(
                    color: Color(0xFFC49F6E),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildSegmentedOption<ArtworkFitMode>(
                  options: [
                    (
                      ArtworkFitMode.samsungNoMat,
                      'Samsung The Frame',
                      'Orantıyı bozmadan tüm ekrana yayar'
                    ),
                    (
                      ArtworkFitMode.smartMat,
                      'Müze Paspartusu',
                      'Orijinal boyut, paspartu & çerçeve'
                    ),
                  ],
                  selected: settings.fitMode,
                  onSelect: (mode) {
                    controller.updateSettings(settings.copyWith(fitMode: mode));
                  },
                ),
                if (settings.fitMode.isSamsungMode) ...[
                  const SizedBox(height: 10.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0x1FC49F6E),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0x33C49F6E)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tv, color: Color(0xFFC49F6E), size: 16.0),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Samsung The Frame Modu: En-boy oranı (aspect ratio) kesinlikle bozulmaz; eser can alıcı noktasına odaklanarak tüm ekrana yayılır.',
                            style: TextStyle(color: Color(0xFFD1C7B7), fontSize: 11.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18.0),

                // 3. Otomatik Geçiş Süresi
                const Text(
                  'TABLO GEÇİŞ SÜRESİ',
                  style: TextStyle(
                    color: Color(0xFFC49F6E),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [60, 180, 300, 600, 900].map((sec) {
                    final isSelected = settings.autoCycleSeconds == sec;
                    final label = sec < 60
                        ? '$sec sn'
                        : '${sec ~/ 60} dakika';
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: const Color(0xFFC49F6E),
                      backgroundColor: const Color(0x332C2C2E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFFD1D1D6),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.0,
                      ),
                      onSelected: (val) {
                        if (val) {
                          controller.updateSettings(
                            settings.copyWith(autoCycleSeconds: sec),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18.0),

                // 4. Paspartu Stili (Smart Mat açıkken)
                if (settings.fitMode == ArtworkFitMode.smartMat) ...[
                  const Text(
                    'PASPARTU (MAT) RENGİ',
                    style: TextStyle(
                      color: Color(0xFFC49F6E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: PassepartoutStyle.values.map((style) {
                      final isSelected = settings.matStyle == style;
                      return ChoiceChip(
                        label: Text(style.displayName),
                        selected: isSelected,
                        selectedColor: const Color(0xFFC49F6E),
                        backgroundColor: const Color(0x332C2C2E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFFD1D1D6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.0,
                        ),
                        onSelected: (val) {
                          if (val) {
                            controller.updateSettings(
                              settings.copyWith(matStyle: style),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18.0),
                ],

                // 5. Çerçeve Stili (Müze Paspartusu açıkken)
                if (settings.fitMode == ArtworkFitMode.smartMat) ...[
                  const Text(
                    'ÇERÇEVE (BEZEL)',
                    style: TextStyle(
                      color: Color(0xFFC49F6E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: FrameBezelStyle.values.map((bezel) {
                      final isSelected = settings.bezelStyle == bezel;
                      return ChoiceChip(
                        label: Text(bezel.displayName),
                        selected: isSelected,
                        selectedColor: const Color(0xFFC49F6E),
                        backgroundColor: const Color(0x332C2C2E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFFD1D1D6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.0,
                        ),
                        onSelected: (val) {
                          if (val) {
                            controller.updateSettings(
                              settings.copyWith(bezelStyle: bezel),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18.0),
                ],

                // 6. Bilgi Plakası & Mat Doku Toggle'ları
                if (settings.fitMode == ArtworkFitMode.smartMat)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Müze Bilgi Plakası',
                      style: TextStyle(color: Color(0xFFE5E5EA), fontSize: 13.5),
                    ),
                    subtitle: const Text(
                      'Eserin adını ve müzesini alt kısımda gösterir',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                    ),
                    activeTrackColor: const Color(0xFFC49F6E),
                    value: settings.showMuseumPlaque,
                    onChanged: (val) {
                      controller.updateSettings(
                        settings.copyWith(showMuseumPlaque: val),
                      );
                    },
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tuval Dokusu (Canvas Texture)',
                    style: TextStyle(color: Color(0xFFE5E5EA), fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'Eserin üzerinde fiziksel yağlı boya mat dokusu oluşturur',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                  ),
                  activeTrackColor: const Color(0xFFC49F6E),
                  value: settings.enableCanvasTexture,
                  onChanged: (val) {
                    controller.updateSettings(
                      settings.copyWith(enableCanvasTexture: val),
                    );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'The Frame Arka Işık Kısma (Art Mode)',
                    style: TextStyle(color: Color(0xFFE5E5EA), fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'Monitörün sert LED parlamasını kısarak fiziksel tuval matlığı kazandırır',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                  ),
                  activeTrackColor: const Color(0xFFC49F6E),
                  value: settings.enableAmbientDimming,
                  onChanged: (val) {
                    controller.updateSettings(
                      settings.copyWith(enableAmbientDimming: val),
                    );
                  },
                ),
                if (settings.enableAmbientDimming) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Text(
                        'Tuval Mat Işık Seviyesi:',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                      ),
                      const Spacer(),
                      Text(
                        settings.matteDimmingFactor >= 0.98
                            ? 'Tam Dijital (%100)'
                            : settings.matteDimmingFactor <= 0.75
                                ? 'Loş Gece (%${(settings.matteDimmingFactor * 100).round()})'
                                : 'The Frame Galeri (%${(settings.matteDimmingFactor * 100).round()})',
                        style: const TextStyle(
                          color: Color(0xFFC49F6E),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFC49F6E),
                      inactiveTrackColor: const Color(0x33FFFFFF),
                      thumbColor: const Color(0xFFF3EFE6),
                      trackHeight: 3.0,
                    ),
                    child: Slider(
                      value: settings.matteDimmingFactor,
                      min: 0.65,
                      max: 1.0,
                      divisions: 7,
                      label: '${(settings.matteDimmingFactor * 100).round()}%',
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(matteDimmingFactor: val),
                        );
                      },
                    ),
                  ),
                ],

                const Divider(color: Color(0x22FFFFFF), height: 28.0),

                // 7. Butonlar: Yeni Tablo İndir & Tamam
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC49F6E),
                          side: const BorderSide(color: Color(0xFFC49F6E)),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_download_outlined, size: 18.0),
                        label: const Text('Yeni Online Eser İndir'),
                        onPressed: () {
                          controller.fetchNextOnlinePainting();
                          onClose();
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC49F6E),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: onClose,
                        child: const Text(
                          'Kapat',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedOption<T>({
    required List<(T, String, String)> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 6.0),
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC49F6E) : const Color(0x332C2C2E),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isSelected ? const Color(0xFFC49F6E) : Colors.white12,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    opt.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    opt.$3,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFF8E8E93),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

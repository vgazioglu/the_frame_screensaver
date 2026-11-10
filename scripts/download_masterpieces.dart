import 'dart:io';
import 'package:the_frame_screensaver/data/artwork_repository.dart';

void main(List<String> args) async {
  final targetCount = args.isNotEmpty ? int.tryParse(args[0]) ?? 20 : 20;
  print('🎨 İndirme başlatılıyor: Hedef $targetCount yeni şaheser...');
  
  final repo = ArtworkRepository();
  await repo.init();

  final initial = await repo.loadAllArtworks();
  final excludeIds = initial.map((a) => a.id).toSet();
  print('Mevcut koleksiyon boyutu: ${initial.length} eser');

  int downloaded = 0;
  int attempts = 0;
  const maxAttempts = 150;

  while (downloaded < targetCount && attempts < maxAttempts) {
    attempts++;
    stdout.write('[$attempts/$maxAttempts] Eser aranıyor... ');
    try {
      final art = await repo.fetchRandomOnlineArtwork(excludeIds: excludeIds.toList());
      if (art != null) {
        excludeIds.add(art.id);
        downloaded++;
        print('✅ [+$downloaded/$targetCount] ${art.artist} - "${art.title}" (${art.year})');
      } else {
        print('⏭️ (kriterlere uymayan eser atlandı)');
      }
    } catch (e) {
      print('❌ Hata: $e');
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  final finalArtworks = await repo.loadAllArtworks();
  print('\n🎉 Tamamlandı! Başarıyla $downloaded yeni şaheser indirildi.');
  print('Güncel toplam koleksiyon: ${finalArtworks.length} şaheser.');
}

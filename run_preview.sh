#!/usr/bin/env bash
# ==============================================================================
# Samsung The Frame Art Screensaver - Önizleme & Test Başlatıcı
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="${SCRIPT_DIR}/build/linux/x64/release/bundle/the_frame_screensaver"

if [[ ! -x "${BIN_PATH}" ]]; then
  echo "[-] Hata: Derlenmiş ikili dosya bulunamadı: ${BIN_PATH}" >&2
  echo "[*] Lütfen önce 'flutter build linux --release' çalıştırın." >&2
  exit 1
fi

MODE="${1:---fullscreen}"

echo "=========================================================="
echo "🖼️  Samsung The Frame Art Screensaver Başlatılıyor..."
echo "=========================================================="
echo "Kısayollar:"
echo "  [Sağ Tık] / [S] : Ayarlar Menüsünü Aç/Kapat (Zamanlayıcı, Çerçeve, Boyut)"
echo "  [→] / [←]       : Sonraki / Önceki tablo (Rastgele akış)"
echo "  [C]             : Müze Paspartusu / Tam Ekran (Cover) geçişi"
echo "  [B]             : The Frame Arka Işık Kısma (%85 Galeri / %72 Gece / %100 Dijital)"
echo "  [T]             : Yağlı Boya Tuval Dokusunu Aç/Kapat"
echo "  [N]             : Yeni Online 4K Şaheser İndir"
echo "  [F]             : Çerçeve rengini değiştir (Meşe / Ceviz / Siyah / Beyaz)"
echo "  [M]             : Paspartu stilini değiştir (Krem / Beyaz / Gri / Yok)"
echo "  [I]             : Antika pirinç bilgi plakasını aç/kapat"
echo "  [Esc]           : Menüyü kapat / Ekran koruyucudan çıkış"
echo "=========================================================="

if [[ "${MODE}" == "--windowed" || "${MODE}" == "-w" || "${MODE}" == "--preview" || "${MODE}" == "-p" ]]; then
  echo "[+] Pencere modu aktif (1600x900)."
  "${BIN_PATH}" --windowed
else
  echo "[+] 2K Kenarsız Tam Ekran modu aktif."
  "${BIN_PATH}" --fullscreen
fi

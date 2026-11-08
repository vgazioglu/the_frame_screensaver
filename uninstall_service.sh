#!/usr/bin/env bash
# ==============================================================================
# Samsung The Frame Art Screensaver - Servis Kaldırma Betiği
# ==============================================================================
set -euo pipefail

SERVICE_FILE="${HOME}/.config/systemd/user/the-frame-screensaver.service"

echo "=========================================================="
echo "🛑 The Frame Screensaver Servisi Durduruluyor & Kaldırılıyor..."
echo "=========================================================="

if systemctl --user is-active --quiet the-frame-screensaver.service 2>/dev/null; then
  systemctl --user stop the-frame-screensaver.service
  echo "[+] Servis durduruldu."
fi

if systemctl --user is-enabled --quiet the-frame-screensaver.service 2>/dev/null; then
  systemctl --user disable the-frame-screensaver.service
  echo "[+] Servis devre dışı bırakıldı."
fi

if [[ -f "${SERVICE_FILE}" ]]; then
  rm -f "${SERVICE_FILE}"
  echo "[+] Servis dosyası silindi."
fi

systemctl --user daemon-reload
echo "[+] İşlem tamamlandı."
echo "=========================================================="

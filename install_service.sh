#!/usr/bin/env bash
# ==============================================================================
# Samsung The Frame Art Screensaver - Systemd User Servisi Kurulum Betiği
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/the-frame-screensaver.service"
DAEMON_PATH="${SCRIPT_DIR}/the_frame_daemon.py"

echo "=========================================================="
echo "🛠️  The Frame Screensaver Servisi Kuruluyor..."
echo "=========================================================="

if [[ ! -f "${DAEMON_PATH}" ]]; then
  echo "[-] Hata: Daemon betiği bulunamadı: ${DAEMON_PATH}" >&2
  exit 1
fi

mkdir -p "${SERVICE_DIR}"

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Samsung The Frame Art Screensaver Daemon
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=IDLE_TIMEOUT_SECONDS=180
Environment=MATTE_BRIGHTNESS=0.65
ExecStart=/usr/bin/python3 ${DAEMON_PATH}
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "[+] Servis dosyası oluşturuldu: ${SERVICE_FILE}"

systemctl --user daemon-reload
systemctl --user enable the-frame-screensaver.service
systemctl --user restart the-frame-screensaver.service

echo "[+] Servis başarıyla aktifleştirildi ve başlatıldı!"
echo "    Durumu kontrol etmek için: systemctl --user status the-frame-screensaver.service"
echo "    Logları incelemek için   : journalctl --user -u the-frame-screensaver.service -f"
echo "=========================================================="

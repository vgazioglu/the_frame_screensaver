#!/usr/bin/env bash
# ==============================================================================
# Samsung The Frame Screensaver - Systemd Kullanıcı Servisi Yönetim Aracı
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DAEMON_SCRIPT="${PROJECT_DIR}/scripts/the_frame_idle_daemon.py"
SERVICE_NAME="the-frame-screensaver.service"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SYSTEMD_USER_DIR}/${SERVICE_NAME}"

# Gerekli komutları doğrula
command -v systemctl >/dev/null 2>&1 || {
  echo "[-] Hata: 'systemctl' komutu bulunamadı." >&2
  exit 1
}

command -v python3 >/dev/null 2>&1 || {
  echo "[-] Hata: 'python3' komutu bulunamadı." >&2
  exit 1
}

function show_usage() {
  echo "Kullanım: $0 {enable|disable|start|stop|restart|status|test}"
  echo ""
  echo "Komutlar:"
  echo "  enable  : 5 dk inaktiflik servisini kurar, otomatik başlatmayı açar ve servisi çalıştırır."
  echo "  disable : Otomatik başlatmayı kapatır ve servisi durdurur."
  echo "  start   : Servisi hemen başlatır."
  echo "  stop    : Servisi durdurur."
  echo "  restart : Servisi yeniden başlatır."
  echo "  status  : Servisin çalışma durumunu gösterir."
  echo "  test    : Servisi arka plana atmadan terminalde ön planda test eder."
}

function install_and_enable() {
  echo "[*] Servis dizini hazırlanıyor: ${SYSTEMD_USER_DIR}"
  mkdir -p "${SYSTEMD_USER_DIR}"

  echo "[*] Servis dosyası oluşturuluyor: ${SERVICE_FILE}"
  cat <<EOF > "${SERVICE_FILE}"
[Unit]
Description=Samsung The Frame Screensaver (5 Min Inactivity Watcher)
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=XAUTHORITY=${HOME}/.Xauthority
ExecStart=/usr/bin/python3 ${DAEMON_SCRIPT}
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

  echo "[*] Systemd yapılandırması yeniden taranıyor..."
  systemctl --user daemon-reload

  echo "[*] Servis etkinleştiriliyor ve başlatılıyor..."
  systemctl --user enable "${SERVICE_NAME}"
  systemctl --user restart "${SERVICE_NAME}"

  echo ""
  echo "=========================================================="
  echo "✅ The Frame Ekran Koruyucu Servisi Başarıyla Kuruldu!"
  echo "=========================================================="
  echo "• Bilgisayarınız 5 dakika (300 sn) inaktif kalınca otomatik devreye girecektir."
  echo "• Biri fareyi oynatır veya [Esc] tuşuna basarsa ekran koruyucu kapanır"
  echo "  ve hemen Cinnamon gerçek kilit ekranı devreye girer."
  echo "• Durumu kontrol etmek için: $0 status"
  echo "• Günlük loglarını görmek için: journalctl --user -u ${SERVICE_NAME} -f"
  echo "=========================================================="
}

function disable_service() {
  echo "[*] Servis durduruluyor ve otomatik başlatma kapatılıyor..."
  systemctl --user stop "${SERVICE_NAME}" 2>/dev/null || true
  systemctl --user disable "${SERVICE_NAME}" 2>/dev/null || true
  if [[ -f "${SERVICE_FILE}" ]]; then
    rm -f "${SERVICE_FILE}"
    systemctl --user daemon-reload
  fi
  echo "[+] The Frame Ekran Koruyucu servisi başarıyla kaldırıldı."
}

ACTION="${1:-status}"

case "${ACTION}" in
  enable|install)
    install_and_enable
    ;;
  disable|uninstall)
    disable_service
    ;;
  start)
    systemctl --user start "${SERVICE_NAME}"
    echo "[+] Servis başlatıldı."
    ;;
  stop)
    systemctl --user stop "${SERVICE_NAME}"
    echo "[+] Servis durduruldu."
    ;;
  restart)
    systemctl --user restart "${SERVICE_NAME}"
    echo "[+] Servis yeniden başlatıldı."
    ;;
  status)
    systemctl --user status "${SERVICE_NAME}" --no-pager || true
    ;;
  test)
    echo "[*] Servis ön planda (Ctrl+C ile durdurun) çalıştırılıyor..."
    python3 "${DAEMON_SCRIPT}"
    ;;
  *)
    show_usage
    exit 1
    ;;
esac

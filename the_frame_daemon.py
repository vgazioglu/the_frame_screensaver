#!/usr/bin/env python3
"""
Samsung The Frame Art Screensaver - X11 Boşta Kalma (Idle) ve Parlaklık Yönetim Daemon'ı
Linux Mint / Cinnamon ortamında boşta kalma süresini takip eder.
Belirlenen süre (varsayılan: 5 dakika / 300 sn) aşıldığında:
  1. Monitör parlaklığını mat tablo hissi için %65 seviyesine çeker (xrandr).
  2. Ekran koruyucuyu tam ekran başlatır.
  3. Fare/klavye ile çıkıldığında parlaklığı anında %100'e (1.0) geri yükler.
"""

import sys
import os
import time
import signal
import ctypes
import subprocess
import argparse

# X11 XScreenSaver Structure
class XScreenSaverInfo(ctypes.Structure):
    _fields_ = [
        ('window', ctypes.c_ulong),
        ('state', ctypes.c_int),
        ('kind', ctypes.c_int),
        ('til_or_since', ctypes.c_ulong),
        ('idle', ctypes.c_ulong),
        ('eventMask', ctypes.c_ulong)
    ]

class X11IdleTracker:
    def __init__(self):
        self.x11 = ctypes.cdll.LoadLibrary('libX11.so.6')
        self.xss = ctypes.cdll.LoadLibrary('libXss.so.1')
        self.display = self.x11.XOpenDisplay(None)
        if not self.display:
            raise RuntimeError("X11 Display açılamadı. DISPLAY değişkenini kontrol edin.")
        self.root = self.x11.XDefaultRootWindow(self.display)
        self.info = XScreenSaverInfo()

    def get_idle_seconds(self) -> float:
        self.xss.XScreenSaverQueryInfo(self.display, self.root, ctypes.byref(self.info))
        return self.info.idle / 1000.0

    def close(self):
        if self.display:
            self.x11.XCloseDisplay(self.display)
            self.display = None

def get_active_monitors():
    monitors = []
    try:
        out = subprocess.check_output(['xrandr', '--listmonitors'], text=True)
        for line in out.splitlines():
            parts = line.strip().split()
            if len(parts) >= 4 and parts[0].endswith(':'):
                monitors.append(parts[-1])
    except Exception as e:
        print(f"[-] Monitör listesi alınamadı: {e}", file=sys.stderr)
    return monitors or ['DisplayPort-1']

def set_brightness(monitors, level: float):
    level_str = f"{level:.2f}"
    for mon in monitors:
        try:
            subprocess.run(
                ['xrandr', '--output', mon, '--brightness', level_str],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            pass

def main():
    parser = argparse.ArgumentParser(description="The Frame Screensaver Daemon")
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(os.environ.get("IDLE_TIMEOUT_SECONDS", 300)),
        help="Boşta kalma süresi (saniye). Varsayılan: 300 sn (5 dk)"
    )
    parser.add_argument(
        "--dim-brightness",
        type=float,
        default=float(os.environ.get("MATTE_BRIGHTNESS", 0.65)),
        help="Ekran koruyucu açıkken mat parlaklık seviyesi (0.1 - 1.0). Varsayılan: 0.65"
    )
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    binary_path = os.path.join(
        script_dir, "build/linux/x64/release/bundle/the_frame_screensaver"
    )

    if not os.path.isfile(binary_path):
        print(f"[-] Hata: Uygulama bulunamadı: {binary_path}", file=sys.stderr)
        sys.exit(1)

    monitors = get_active_monitors()
    print(f"[+] The Frame Daemon Başlatıldı.")
    print(f"[*] İzlenen Monitörler: {', '.join(monitors)}")
    print(f"[*] Boşta Kalma Süresi: {args.timeout} saniye ({args.timeout // 60} dakika)")
    print(f"[*] Mat Tablo Parlaklığı: {args.dim_brightness}")

    def cleanup(signum=None, frame=None):
        print("\n[+] Daemon sonlandırılıyor. Parlaklık %100'e geri yükleniyor...")
        set_brightness(monitors, 1.0)
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    tracker = X11IdleTracker()
    is_screensaver_active = False

    try:
        while True:
            idle_seconds = tracker.get_idle_seconds()

            if idle_seconds >= args.timeout and not is_screensaver_active:
                print(f"[+] {int(idle_seconds)} saniye boşta kalındı. The Frame devreye giriyor...")
                is_screensaver_active = True

                # Tam ekran koruyucuyu çalıştır
                try:
                    subprocess.run([binary_path, "--fullscreen"], check=False)
                finally:
                    print("[+] Kullanıcı faaliyeti algılandı.")
                    is_screensaver_active = False
                    time.sleep(2)

            time.sleep(2)

    except KeyboardInterrupt:
        cleanup()
    finally:
        set_brightness(monitors, 1.0)
        tracker.close()

if __name__ == "__main__":
    main()

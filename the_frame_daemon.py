#!/usr/bin/env python3
"""
Samsung The Frame Art Screensaver - X11 Boşta Kalma (Idle) ve Parlaklık Yönetim Daemon'ı
Linux Mint / Cinnamon ortamında boşta kalma süresini takip eder.
Belirlenen süre (varsayılan: 180 sn / 3 dk) aşıldığında:
  1. Monitör parlaklığını mat tablo hissi için %65 seviyesine çeker (xrandr).
  2. Ekran koruyucuyu tam ekran başlatır.
  3. Cinnamon kilit ekranı araya girdiğinde The Frame'i sonlandırarak çift şifre sorununu önler.
  4. Çıkıldığında parlaklığı anında %100'e (1.0) geri yükler.
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

def is_cinnamon_screensaver_active() -> bool:
    try:
        out = subprocess.check_output(
            ["cinnamon-screensaver-command", "-q"],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=2,
        )
        return "is active" in out.lower()
    except Exception:
        return False

MEDIA_APP_KEYWORDS = (
    "firefox", "chrome", "chromium", "brave", "opera", "vivaldi",
    "zen", "librewolf", "floorp", "vlc", "mpv", "celluloid", "totem",
    "spotify", "rhythmbox", "clementine", "audacious", "deadbeef",
    "plex", "kodi", "smplayer", "strawberry", "youtube-music",
)

def is_audio_playing() -> bool:
    """Yalnızca bilinen medya ve tarayıcı uygulamalarının aktif ses çalma durumunu denetler."""
    try:
        out = subprocess.check_output(
            ['pactl', 'list', 'sink-inputs'],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=1
        )
        blocks = out.split('Sink Input #')
        for block in blocks[1:]:
            lines = [l.strip() for l in block.splitlines()]
            corked = False
            muted = False
            app_name = ""
            app_binary = ""
            for line in lines:
                if line.startswith('Corked:'):
                    corked = 'yes' in line.lower()
                elif line.startswith('Mute:'):
                    muted = 'yes' in line.lower()
                elif line.startswith('application.name ='):
                    app_name = line.split('=', 1)[1].strip().strip('"').lower()
                elif line.startswith('application.process.binary ='):
                    app_binary = line.split('=', 1)[1].strip().strip('"').lower()

            if not corked and not muted:
                if any(kw in app_name or kw in app_binary for kw in MEDIA_APP_KEYWORDS):
                    return True
    except Exception:
        pass
    return False

def is_fullscreen_active() -> bool:
    """Aktif pencerenin tam ekranda (YouTube, film veya oyun) olup olmadığını denetler."""
    try:
        out = subprocess.check_output(
            ['xprop', '-root', '_NET_ACTIVE_WINDOW'],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=1
        )
        if 'window id #' not in out:
            return False
        win_id = out.split('window id #')[1].strip().split()[0]
        if win_id in ('0x0', '0'):
            return False
        state_out = subprocess.check_output(
            ['xprop', '-id', win_id, '_NET_WM_STATE'],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=1
        )
        return '_NET_WM_STATE_FULLSCREEN' in state_out
    except Exception:
        return False

def is_session_inhibited() -> bool:
    """Firefox veya medya oynatıcıların DBus inhibit (ekranı açık tut) kilidini denetler."""
    for dest, path, iface in [
        ('org.gnome.SessionManager', '/org/gnome/SessionManager', 'org.gnome.SessionManager'),
        ('org.cinnamon.SessionManager', '/org/cinnamon/SessionManager', 'org.cinnamon.SessionManager'),
    ]:
        try:
            out = subprocess.check_output([
                'dbus-send', '--session', f'--dest={dest}',
                '--type=method_call', '--print-reply',
                path, f'{iface}.IsInhibited', 'uint32:8'
            ], text=True, stderr=subprocess.DEVNULL, timeout=1)
            if 'boolean true' in out.lower():
                return True
        except Exception:
            pass
    return False

def get_active_media_reason() -> str:
    """Video veya medya oynatılıyorsa sebebini döner, yoksa boş döner."""
    if is_fullscreen_active():
        return "Tam ekran pencere / video aktif"
    if is_audio_playing():
        return "Aktif ses akışı (video / müzik) çalınıyor"
    if is_session_inhibited():
        return "Masaüstü Inhibit kilidi (tarayıcı video kilidi) aktif"
    return ""

def main():
    parser = argparse.ArgumentParser(description="The Frame Screensaver Daemon")
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(os.environ.get("IDLE_TIMEOUT_SECONDS", 180)),
        help="Boşta kalma süresi (saniye). Varsayılan: 180 sn (3 dk)"
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
    last_unlock_time = 0.0
    last_busy_time = time.time()
    was_cinnamon_active = is_cinnamon_screensaver_active()

    try:
        while True:
            is_cinnamon_active = is_cinnamon_screensaver_active()

            if is_cinnamon_active:
                was_cinnamon_active = True
                set_brightness(monitors, 1.0)
                time.sleep(3)
                continue

            if was_cinnamon_active:
                was_cinnamon_active = False
                last_unlock_time = time.time()
                last_busy_time = time.time()
                set_brightness(monitors, 1.0)
                time.sleep(3)
                continue

            now = time.time()
            if now - last_unlock_time < args.timeout:
                time.sleep(3)
                continue

            # Tarayıcıda (Firefox vb.) veya medya oynatıcıda video/müzik izleniyorsa ekran koruyucuyu engelle
            media_reason = get_active_media_reason()
            if media_reason:
                last_busy_time = now
                time.sleep(3)
                continue

            # Medya/video bittikten sonra da tam args.timeout süresi kadar beklenmesini sağla
            if now - last_busy_time < args.timeout:
                time.sleep(3)
                continue

            idle_seconds = tracker.get_idle_seconds()

            if idle_seconds >= args.timeout:
                print(f"[+] {int(idle_seconds)} saniye boşta kalındı. The Frame devreye giriyor...")
                set_brightness(monitors, args.dim_brightness)

                # Ekran koruyucuyu Popen ile başlat ve Cinnamon kilit ekranını izle
                proc = subprocess.Popen([binary_path, "--fullscreen", "--screensaver", "--lock-on-exit"])

                while proc.poll() is None:
                    if is_cinnamon_screensaver_active():
                        print("[*] Cinnamon kilit ekranı araya girdi. The Frame kapatılıyor...")
                        proc.terminate()
                        try:
                            proc.wait(timeout=2)
                        except subprocess.TimeoutExpired:
                            proc.kill()
                        was_cinnamon_active = True
                        break
                    time.sleep(1)

                set_brightness(monitors, 1.0)
                last_unlock_time = time.time()
                last_busy_time = time.time()
                time.sleep(2)

            time.sleep(2)

    except KeyboardInterrupt:
        cleanup()
    finally:
        set_brightness(monitors, 1.0)
        tracker.close()

if __name__ == "__main__":
    main()

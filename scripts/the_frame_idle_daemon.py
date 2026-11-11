#!/usr/bin/env python3
"""
The Frame Screensaver - Linux X11 Idle Watcher Daemon
Monitors user inactivity (3 minutes / 180s default) on Linux (X11 / Cinnamon).
When idle, launches the Samsung The Frame art screensaver.
When user presses ESC or interacts with keyboard/mouse, exits and locks the screen.
Smart Cinnamon Lock Integration:
  - If Cinnamon screensaver/lock activates while The Frame is running, The Frame terminates
    immediately so it does not stay hidden beneath the lock screen.
  - After unlocking Cinnamon, a grace period prevents The Frame from immediately re-triggering.
"""

import ctypes
import os
import signal
import subprocess
import sys
import time

# Configuration
IDLE_THRESHOLD_SECONDS = int(os.environ.get("IDLE_TIMEOUT_SECONDS", 180))  # 3 minutes default (180s)
CHECK_INTERVAL_SECONDS = 5
BINARY_PATH = os.path.expanduser("~/Projects/the_frame_screensaver/build/linux/x64/release/bundle/the_frame_screensaver")

# Load X11 and XScreenSaver libraries via ctypes
try:
    x11 = ctypes.cdll.LoadLibrary("libX11.so.6")
    xss = ctypes.cdll.LoadLibrary("libXss.so.1")
except Exception as e:
    sys.stderr.write(f"[-] Error loading X11 / XScreenSaver libraries: {e}\n")
    sys.exit(1)


class XScreenSaverInfo(ctypes.Structure):
    _fields_ = [
        ("window", ctypes.c_ulong),
        ("state", ctypes.c_int),
        ("kind", ctypes.c_int),
        ("til_or_since", ctypes.c_ulong),
        ("idle", ctypes.c_ulong),
    ]


def get_idle_seconds() -> float:
    display = x11.XOpenDisplay(None)
    if not display:
        return 0.0
    try:
        root = x11.XDefaultRootWindow(display)
        info = xss.XScreenSaverAllocInfo()
        xss.XScreenSaverQueryInfo(display, root, info)
        idle_ms = ctypes.cast(info, ctypes.POINTER(XScreenSaverInfo)).contents.idle
        return idle_ms / 1000.0
    finally:
        x11.XCloseDisplay(display)


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


def is_screensaver_binary_running() -> bool:
    try:
        out = subprocess.check_output(
            ["pidof", "the_frame_screensaver"],
            stderr=subprocess.DEVNULL,
            text=True,
        )
        pids = [int(p) for p in out.strip().split() if int(p) != os.getpid()]
        return len(pids) > 0
    except subprocess.CalledProcessError:
        return False


def kill_existing_screensavers():
    try:
        subprocess.run(["pkill", "-TERM", "-f", "the_frame_screensaver"], stderr=subprocess.DEVNULL)
    except Exception:
        pass


def main():
    if not os.path.isfile(BINARY_PATH) or not os.access(BINARY_PATH, os.X_OK):
        sys.stderr.write(f"[-] Error: Screensaver binary not found: {BINARY_PATH}\n")
        sys.exit(1)

    running = True

    def handle_signal(sig, frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"[+] The Frame Idle Watcher started. Monitoring inactivity (threshold: {IDLE_THRESHOLD_SECONDS}s / {IDLE_THRESHOLD_SECONDS // 60}m)...")
    sys.stdout.flush()

    last_log_time = 0.0
    last_unlock_time = 0.0
    was_cinnamon_active = is_cinnamon_screensaver_active()

    while running:
        try:
            is_cinnamon_active = is_cinnamon_screensaver_active()

            # Durum 1: Sistem (Cinnamon) şu anda kilitli
            if is_cinnamon_active:
                if not was_cinnamon_active:
                    print("[*] Cinnamon sistem kilit ekranı aktif hale geldi.")
                    sys.stdout.flush()
                was_cinnamon_active = True

                # Kilit ekranı aktifken arkada The Frame kalmışsa hemen temizle
                if is_screensaver_binary_running():
                    print("[*] Kilit ekranı altında The Frame tespit edildi, sonlandırılıyor...")
                    sys.stdout.flush()
                    kill_existing_screensavers()

                time.sleep(CHECK_INTERVAL_SECONDS)
                continue

            # Durum 2: Kullanıcı kilit ekranını şifre girip henüz açtı
            if was_cinnamon_active:
                print("[+] Sistem kilit ekranı açıldı. Kullanıcı aktif, The Frame için bekleme süresi başlatıldı.")
                sys.stdout.flush()
                was_cinnamon_active = False
                last_unlock_time = time.time()
                kill_existing_screensavers()
                time.sleep(CHECK_INTERVAL_SECONDS)
                continue

            # Durum 3: Kilit açıldıktan sonra koruma süresi (en az IDLE_THRESHOLD_SECONDS geçmeli)
            now = time.time()
            time_since_unlock = now - last_unlock_time
            if time_since_unlock < IDLE_THRESHOLD_SECONDS:
                time.sleep(CHECK_INTERVAL_SECONDS)
                continue

            idle_sec = get_idle_seconds()

            # Periyodik durum bilgisi (Her 60 saniyede bir log yaz)
            if now - last_log_time >= 60.0 and idle_sec >= 30.0:
                print(f"[*] Sistem inaktiflik süresi: {idle_sec:.0f}s / {IDLE_THRESHOLD_SECONDS}s")
                sys.stdout.flush()
                last_log_time = now

            # 3 dakika (180 saniye) inaktiflik tamamlandığında:
            if idle_sec >= IDLE_THRESHOLD_SECONDS:
                if not is_cinnamon_screensaver_active() and not is_screensaver_binary_running():
                    print(f"[*] İnaktiflik eşiği aşıldı ({idle_sec:.0f}s >= {IDLE_THRESHOLD_SECONDS}s). The Frame Ekran Koruyucu başlatılıyor...")
                    sys.stdout.flush()

                    # Ekran koruyucuyu Popen ile başlat ve Cinnamon kilit ekranını dinamik olarak izle:
                    proc = subprocess.Popen([
                        BINARY_PATH,
                        "--fullscreen",
                        "--screensaver",
                        "--lock-on-exit",
                    ])

                    # Ekran koruyucu açıkken döngüde kontrol et:
                    while proc.poll() is None:
                        # Eğer sistemin kendi kilit ekranı (Cinnamon zaman aşımı vb.) araya girdiyse:
                        if is_cinnamon_screensaver_active():
                            print("[*] Cinnamon sistem kilit ekranı araya girdi. The Frame altta kalmasın diye sonlandırılıyor...")
                            sys.stdout.flush()
                            proc.terminate()
                            try:
                                proc.wait(timeout=2)
                            except subprocess.TimeoutExpired:
                                proc.kill()
                            was_cinnamon_active = True
                            break
                        time.sleep(1)

                    print("[*] The Frame oturumu tamamlandı.")
                    sys.stdout.flush()
                    last_log_time = time.time()
                    last_unlock_time = time.time()
                    time.sleep(3)

            time.sleep(CHECK_INTERVAL_SECONDS)
        except Exception as e:
            time.sleep(CHECK_INTERVAL_SECONDS)

    kill_existing_screensavers()
    print("[+] The Frame Idle Watcher stopped cleanly.")


if __name__ == "__main__":
    main()

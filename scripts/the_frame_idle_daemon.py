#!/usr/bin/env python3
"""
The Frame Screensaver - Linux X11 Idle Watcher Daemon
Monitors user inactivity (5 minutes / 300s) on Linux (X11 / Cinnamon).
When idle, launches the Samsung The Frame art screensaver.
When user presses ESC or interacts with keyboard/mouse, exits and locks the screen.
"""

import ctypes
import os
import signal
import subprocess
import sys
import time

# Configuration
IDLE_THRESHOLD_SECONDS = 300  # 5 minutes
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


def main():
    if not os.path.isfile(BINARY_PATH) or not os.access(BINARY_PATH, os.X_OK):
        sys.stderr.write(f"[-] Error: Screensaver binary not found: {BINARY_PATH}\n")
        sys.exit(1)

    # Handle graceful termination
    running = True

    def handle_signal(sig, frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"[+] The Frame Idle Watcher started. Monitoring inactivity (threshold: {IDLE_THRESHOLD_SECONDS}s / {IDLE_THRESHOLD_SECONDS // 60}m)...")
    sys.stdout.flush()

    last_log_time = 0.0

    while running:
        try:
            idle_sec = get_idle_seconds()

            # Periyodik durum bilgisi (Her 60 saniyede bir log yaz)
            now = time.time()
            if now - last_log_time >= 60.0 and idle_sec >= 30.0:
                print(f"[*] Sistem inaktiflik süresi: {idle_sec:.0f}s / {IDLE_THRESHOLD_SECONDS}s")
                sys.stdout.flush()
                last_log_time = now

            # 5 dakika (300 saniye) inaktiflik tamamlandığında:
            if idle_sec >= IDLE_THRESHOLD_SECONDS:
                if not is_cinnamon_screensaver_active() and not is_screensaver_binary_running():
                    print(f"[*] İnaktiflik eşiği aşıldı ({idle_sec:.0f}s >= {IDLE_THRESHOLD_SECONDS}s). The Frame Ekran Koruyucu başlatılıyor...")
                    sys.stdout.flush()

                    # Ekran koruyucuyu tam ekran başlat ve kullanıcı müdahalesine kadar bekle
                    subprocess.run([
                        BINARY_PATH,
                        "--fullscreen",
                        "--screensaver",
                        "--lock-on-exit",
                    ])

                    print("[*] The Frame Ekran Koruyucudan çıkıldı (kullanıcı müdahalesi). Sistem kilitlendi.")
                    sys.stdout.flush()
                    last_log_time = time.time()
                    time.sleep(3)

            time.sleep(CHECK_INTERVAL_SECONDS)
        except Exception as e:
            time.sleep(CHECK_INTERVAL_SECONDS)

    print("[+] The Frame Idle Watcher stopped cleanly.")


if __name__ == "__main__":
    main()

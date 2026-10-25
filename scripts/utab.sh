#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab daily launcher: kill stale X server, start session with tablet-friendly DPI.
# GPL-3.0-or-later. Usage: bash ~/utab.sh   (или добавить alias utab)
set -euo pipefail
pkill -f "termux-x11 :1" 2>/dev/null || true
sleep 1
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
DPI="${UTAB_DPI:-168}"
termux-x11 :1 -dpi "$DPI" >/dev/null 2>&1 &
sleep 3
echo "[utab] X-сервер :1 (dpi=$DPI) — стартую XFCE..."
exec proot-distro login ubuntu --shared-tmp -- \
    env DISPLAY=:1 PULSE_SERVER=127.0.0.1 dbus-launch --exit-with-session startxfce4

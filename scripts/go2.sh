#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab go2: session launch WITHOUT any container-side script. GPL-3.0-or-later
set -euo pipefail
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
termux-x11 :1 -dpi 168 >/dev/null 2>&1 &
sleep 3
echo "[go2] X server pid=$! — стартую XFCE в контейнере..."
exec proot-distro login ubuntu --shared-tmp -- \
    env DISPLAY=:1 PULSE_SERVER=127.0.0.1 dbus-launch --exit-with-session startxfce4

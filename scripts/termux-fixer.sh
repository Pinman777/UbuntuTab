#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab fixer: official mirror + fresh proot-distro + rerun installer
set -euo pipefail
P="${PREFIX:-/data/data/com.termux/files/usr}"

echo "[fix] официальный зеркало termux-main..."
cp "$P/etc/apt/sources.list" "$P/etc/apt/sources.list.bak" 2>/dev/null || true
echo 'deb https://packages.termux.dev/apt/termux-main/ stable main' > "$P/etc/apt/sources.list"
rm -f "$P"/etc/apt/sources.list.d/*.list 2>/dev/null || true

echo "[fix] apt update..."
apt update -y

echo "[fix] свежие proot-distro и python..."
apt install -y proot-distro python pulseaudio x11-repo

echo "[fix] termux-x11-nightly..."
apt install -y termux-x11-nightly || echo "[fix] termux-x11-nightly недоступен — продолжаю"

echo "[fix] чистка битого rootfs..."
rm -rf "$P/var/lib/proot-distro/installed-rootfs/ubuntu-24.04" 2>/dev/null || true

echo "[fix] версия proot-distro: $(proot-distro --version 2>/dev/null || echo '?')"

echo "[fix] запускаю установитель UbuntuTab..."
exec bash "$HOME/ut.sh"

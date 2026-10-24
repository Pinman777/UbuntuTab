#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab installer for REAL Termux (standard prefix, no custom bootstrap).
# Fork of orailnoor/DroidDesk scripts (GPL-3.0). SPDX-License-Identifier: GPL-3.0-or-later
# Usage (in Termux):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts/termux-ubuntutab.sh)"
set -euo pipefail

REPO="https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts"
DISTRO="ubuntu:24.04"
PREFIX_STD="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="$PREFIX_STD/var/lib/proot-distro/installed-rootfs/ubuntu"

c_ok()  { printf '\033[32m[OK]\033[0m %s\n' "$*"; }
c_msg() { printf '\033[36m[*]\033[0m %s\n' "$*"; }
c_err() { printf '\033[31m[ОШИБКА]\033[0m %s\n' "$*"; }

c_msg "UbuntuTab: установка в настоящий Termux (проверенный путь)..."
c_msg "1/5: пакеты Termux (proot-distro, pulseaudio, termux-x11-nightly)..."
pkg install -y proot-distro pulseaudio
pkg install -y x11-repo
pkg install -y termux-x11-nightly

if [ -d "$ROOTFS" ]; then
    c_ok "Контейнер $DISTRO уже установлен — пропускаю загрузку rootfs."
else
    c_msg "2/5: загрузка rootfs $DISTRO (потребуется время)..."
    proot-distro install "$DISTRO"
fi

c_msg "3/5: копирование postinstall.sh и start-desktop.sh в контейнер..."
curl -fsSL "$REPO/postinstall.sh"   -o "$ROOTFS/root/postinstall.sh"
curl -fsSL "$REPO/start-desktop.sh" -o "$ROOTFS/root/start-desktop.sh"

c_msg "4/5: постинсталл Ubuntu (XFCE, firefox-esr, локали, QwenPaw; идемпотентен)..."
proot-distro login ubuntu -- /bin/bash /root/postinstall.sh

c_msg "5/5: создание стартового скрипта ~/start-ubuntutab.sh ..."
mkdir -p "$PREFIX_STD/tmp/.X11-unix" 2>/dev/null || true
cat > "$HOME/start-ubuntutab.sh" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab session starter (real Termux + Termux:X11, канонический рецепт termux-x11)
set -euo pipefail
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
termux-x11 :1 >/dev/null 2>&1 &
sleep 2
exec proot-distro login ubuntu --shared-tmp -- \
    env DISPLAY=:1 PULSE_SERVER=127.0.0.1 /usr/local/bin/start-desktop.sh
EOS
chmod 0755 "$HOME/start-ubuntutab.sh"

echo
c_ok "Готово! Порядок запуска:"
echo "  bash ~/start-ubuntutab.sh   (запустит X-сервер, приложение Termux:X11 и XFCE)"

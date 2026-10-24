#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab installer for REAL Termux (standard prefix, no custom bootstrap).
# Fork of orailnoor/DroidDesk scripts (GPL-3.0). SPDX-License-Identifier: GPL-3.0-or-later
# Usage (in Termux):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts/termux-ubuntutab.sh)"
set -euo pipefail

REPO="https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts"
DISTRO="ubuntu-24.04"
PREFIX_STD="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="$PREFIX_STD/var/lib/proot-distro/installed-rootfs/$DISTRO"

c_ok()  { printf '\033[32m[OK]\033[0m %s\n' "$*"; }
c_msg() { printf '\033[36m[*]\033[0m %s\n' "$*"; }
c_err() { printf '\033[31m[ОШИБКА]\033[0m %s\n' "$*"; }

c_msg "UbuntuTab: установка в настоящий Termux (проверенный путь)..."
c_msg "1/5: пакеты Termux (proot-distro, pulseaudio)..."
pkg install -y proot-distro pulseaudio

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
proot-distro login "$DISTRO" -- /bin/bash /root/postinstall.sh

c_msg "5/5: создание стартового скрипта ~/start-ubuntutab.sh ..."
mkdir -p "$PREFIX_STD/tmp/.X11-unix" 2>/dev/null || true
cat > "$HOME/start-ubuntutab.sh" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab session starter (real Termux + Termux:X11 app)
set -euo pipefail
P="${PREFIX:-/data/data/com.termux/files/usr}"
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
mkdir -p "$P/tmp/.X11-unix" 2>/dev/null || true
if [ ! -S "$P/tmp/.X11-unix/X0" ] && [ ! -e "$P/tmp/.X11-unix/X0" ]; then
    echo ">>> Открой приложение Termux:X11 (один раз), затем запусти снова — оно поднимет X-сервер."
fi
exec proot-distro login ubuntu-24.04 \
    --bind "$P/tmp/.X11-unix":/tmp/.X11-unix \
    -- /usr/local/bin/start-desktop.sh
EOS
chmod 0755 "$HOME/start-ubuntutab.sh"

echo
c_ok "Готово! Порядок запуска:"
echo "  1. Открой приложение Termux:X11 (чёрный экран = норм, X-сервер работает)"
echo "  2. Вернись в Termux: bash ~/start-ubuntutab.sh"
echo "  3. Вернись в Termux:X11 — там рабочий стол XFCE"

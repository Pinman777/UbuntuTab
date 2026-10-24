#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# UbuntuTab — start-ubuntu.sh
#
# Сессионный скрипт Termux (устанавливается в $HOME скриптом ubuntu-setup.sh):
#   1) запускает PulseAudio (если ещё не запущен) и открывает TCP-доступ
#      на 127.0.0.1 для контейнера;
#   2) монтирует (bind) сокет Termux:X11 и GPU-устройства в контейнер
#      (паттерн start-proot.sh из DroidDesk);
#   3) логинится в ubuntu-24.04 и запускает /usr/local/bin/start-desktop.sh
#      (XFCE на DISPLAY=:0).
#
# Окно Termux:X11 при этом открывает Flutter-оболочка UbuntuTab.
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 UbuntuTab contributors
# На основе DroidDesk, Copyright (C) 2026 orailnoor and DroidDesk
# contributors — https://github.com/orailnoor/DroidDesk (GPL-3.0)
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version. Полный текст: LICENSES/GPL-3.0.txt.
###############################################################################
set -euo pipefail

DISTRO="ubuntu-24.04"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"
TERMUX_TMP="${TMPDIR:-$PREFIX/tmp}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
msg()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[ОШИБКА]${NC} $*" >&2; exit 1; }
trap 'echo -e "${RED}[ОШИБКА]${NC} start-ubuntu.sh прерван (см. вывод выше)" >&2' ERR

[ -d "$ROOTFS" ] || die "Контейнер $DISTRO не установлен. Сначала выполните: bash scripts/ubuntu-setup.sh"

# --- 1. Аудио: PulseAudio + TCP-доступ для контейнера ---
if pgrep -x pulseaudio > /dev/null 2>&1; then
    ok "PulseAudio уже запущен."
else
    msg "Запуск PulseAudio..."
    pulseaudio --start --exit-idle-time=-1
    sleep 1
    pgrep -x pulseaudio > /dev/null 2>&1 \
        || warn "PulseAudio не запустился — сессия без звука."
fi
# Повторная загрузка модуля не страшна (ошибки подавлены)
pactl load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 > /dev/null 2>&1 || true
PULSE_SERVER=127.0.0.1

# --- 2. Bind'ы: сокет Termux:X11 + GPU-устройства (паттерн DroidDesk) ---
X11_DIR="$TERMUX_TMP/.X11-unix"
BINDS=()
if [ -d "$X11_DIR" ]; then
    BINDS+=(--bind "$X11_DIR:/tmp/.X11-unix")
    [ -S "$X11_DIR/X0" ] || warn "В $X11_DIR нет сокета X0 — Termux:X11 ещё не запущен."
else
    warn "Каталог $X11_DIR не найден — сначала запустите Termux:X11 из приложения."
fi
if [ -d /dev/dri ]; then
    BINDS+=(--bind /dev/dri:/dev/dri)
fi
if [ -e /dev/kgsl-3d0 ]; then
    BINDS+=(--bind /dev/kgsl-3d0:/dev/kgsl-3d0)
fi

# --- 3. Сессия: XFCE внутри контейнера на DISPLAY=:0 ---
msg "Запуск XFCE-сессии Ubuntu 24.04 (DISPLAY=:0). Для выхода наберите exit."
exec proot-distro login "$DISTRO" "${BINDS[@]}" -- \
    env DISPLAY=:0 PULSE_SERVER="$PULSE_SERVER" LANG=ru_RU.UTF-8 \
    /usr/local/bin/start-desktop.sh

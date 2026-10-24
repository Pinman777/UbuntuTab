#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# UbuntuTab — Ubuntu-first Android desktop (форк DroidDesk)
#
# ubuntu-setup.sh — установка фундамента в Termux (идемпотентно):
#   1) pkg update + proot-distro + pulseaudio
#   2) proot-distro install ubuntu-24.04
#   3) копирование postinstall.sh и start-desktop.sh внутрь контейнера
#   4) запуск postinstall.sh в контейнере (root)
#   5) сессионные хуки start-ubuntu.sh / ubuntu-menu-sync.sh → $HOME
#
# Нативные TUR-десктопы, VNC и DE-меню Termux НЕ ставятся — весь десктоп
# живёт в контейнере Ubuntu 24.04 (см. docs/FORK-ARCHITECTURE.md).
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
msg()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[ОШИБКА]${NC} $*" >&2; exit 1; }
trap 'echo -e "${RED}[ОШИБКА]${NC} ubuntu-setup.sh прерван (см. вывод выше)" >&2' ERR

# --- 0. Проверки окружения ---
[ -d "$PREFIX" ] || die "Скрипт должен запускаться в Termux (PREFIX «$PREFIX» не найден)."
for f in postinstall.sh start-desktop.sh start-ubuntu.sh ubuntu-menu-sync.sh; do
    [ -f "$SCRIPT_DIR/$f" ] || \
        die "Рядом с ubuntu-setup.sh нет $f — скрипты должны лежать вместе (scripts/)."
done

# --- 1. Фундамент Termux: только proot-distro и pulseaudio ---
msg "Обновление пакетов Termux..."
pkg update -y
pkg install -y proot-distro pulseaudio

# --- 2. Контейнер Ubuntu 24.04 ---
if [ -d "$ROOTFS" ]; then
    ok "Контейнер $DISTRO уже установлен — пропускаю загрузку rootfs."
else
    msg "Установка $DISTRO (загрузка rootfs, это может занять время)..."
    proot-distro install "$DISTRO"
fi

# --- 3. Копируем скрипты внутрь контейнера ---
msg "Копирование postinstall.sh и start-desktop.sh в контейнер..."
cp "$SCRIPT_DIR/postinstall.sh"   "$ROOTFS/root/postinstall.sh"
cp "$SCRIPT_DIR/start-desktop.sh" "$ROOTFS/root/start-desktop.sh"

# --- 4. Постинсталл внутри контейнера (root, идемпотентен) ---
msg "Настройка Ubuntu: XFCE, firefox-esr, шрифты/локали, QwenPaw, тёмная тема..."
proot-distro login "$DISTRO" -- /bin/bash /root/postinstall.sh

# --- 5. Сессионные хуки в $HOME (Termux) ---
msg "Установка сессионных хуков в \$HOME..."
install -m 0755 "$SCRIPT_DIR/start-ubuntu.sh"     "$HOME/start-ubuntu.sh"
install -m 0755 "$SCRIPT_DIR/ubuntu-menu-sync.sh" "$HOME/ubuntu-menu-sync.sh"

# --- 6. Первичная синхронизация меню (не критична) ---
msg "Первичная синхронизация меню приложений..."
bash "$HOME/ubuntu-menu-sync.sh" \
    || warn "menu-sync не удался — повторите позже: bash ~/ubuntu-menu-sync.sh"

echo
ok "Установка UbuntuTab завершена."
echo "    Запуск десктопа:    bash ~/start-ubuntu.sh"
echo "    Синхронизация меню: bash ~/ubuntu-menu-sync.sh"

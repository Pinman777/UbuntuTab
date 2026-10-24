#!/bin/bash
###############################################################################
# UbuntuTab — postinstall.sh
#
# Запускается ВНУТРИ контейнера Ubuntu 24.04 от root (вызывается из
# ubuntu-setup.sh). Идемпотентен: безопасен при повторном запуске.
#
#   1) apt update/upgrade (noninteractive)
#   2) XFCE: xfce4, xfce4-terminal, xfce4-goodies, dbus-x11,
#      x11-xserver-utils, mesa-utils
#   3) firefox-esr из PPA mozillateam (deb; snap-заглушка ubuntu в proot
#      не работает) + apt-пин приоритета PPA
#   4) Шрифты Noto и локали ru_RU.UTF-8 + en_US.UTF-8
#   5) QwenPaw по умолчанию: venv /opt/qwenpaw + pip install qwenpaw
#      (браузеры playwright НЕ скачиваются)
#   6) Тёмная тема XFCE (порт механизмов DroidDesk: xsettings/xfwm4/терминал)
#   7) Установка start-desktop.sh в /usr/local/bin
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
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Версия QwenPaw, проверенная для aarch64/glibc (docs/FORK-ARCHITECTURE.md)
QWENPAW_VERSION="2.2.2.post1"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
msg()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[ОШИБКА]${NC} $*" >&2; exit 1; }
trap 'echo -e "${RED}[ОШИБКА]${NC} postinstall.sh прерван (см. вывод выше)" >&2' ERR

# --- 0. Проверки окружения ---
[ "$(id -u)" -eq 0 ] || die "postinstall.sh должен выполняться от root."
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release 2>/dev/null; then
    warn "Ожидался Ubuntu 24.04 — продолжаю, но конфигурация не проверялась здесь."
fi

# --- 1. apt update / upgrade ---
msg "Обновление пакетов Ubuntu..."
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# --- 2. XFCE + утилиты + шрифты + темы + python ---
msg "Установка XFCE, шрифтов Noto, тем и python3.12..."
apt-get install -y \
    xfce4 xfce4-terminal xfce4-goodies dbus-x11 x11-xserver-utils mesa-utils \
    fonts-noto-core fonts-noto-ui-core locales \
    greybird-gtk-theme gnome-themes-extra adwaita-icon-theme \
    software-properties-common \
    python3.12 python3.12-venv

# --- 3. firefox-esr из PPA mozillateam ---
# Обычный пакет firefox в Ubuntu — snap-заглушка, в proot не работает.
msg "Подключение PPA mozillateam и установка firefox-esr..."
add-apt-repository -y ppa:mozillateam/ppa
cat > /etc/apt/preferences.d/mozillateam-pin << 'PIN'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
PIN
apt-get update -y
apt-get install -y firefox-esr

# --- 4. Локали: ru_RU.UTF-8 + en_US.UTF-8 ---
msg "Генерация локалей ru_RU.UTF-8 и en_US.UTF-8..."
grep -q '^ru_RU.UTF-8 UTF-8' /etc/locale.gen || echo 'ru_RU.UTF-8 UTF-8' >> /etc/locale.gen
grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
update-locale LANG=ru_RU.UTF-8

# --- 5. QwenPaw (venv /opt/qwenpaw) ---
msg "Установка QwenPaw в venv /opt/qwenpaw..."
python3.12 -m venv /opt/qwenpaw
/opt/qwenpaw/bin/pip install --upgrade pip
/opt/qwenpaw/bin/pip install --no-cache-dir "qwenpaw==${QWENPAW_VERSION}"
# Внимание: `playwright install` сознательно НЕ запускаем — браузеры
# не скачиваем (см. задачу T1 / docs/FORK-ARCHITECTURE.md).

msg "Ярлык «QwenPaw Console»..."
cat > /usr/share/applications/qwenpaw-console.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=QwenPaw Console
Comment=QwenPaw AI-консоль (venv /opt/qwenpaw)
Exec=xfce4-terminal --title="QwenPaw Console" -x /opt/qwenpaw/bin/qwenpaw
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=false
DESKTOP
chmod 0644 /usr/share/applications/qwenpaw-console.desktop

# --- 6. Тёмная тема XFCE (порт из termux-linux-setup.sh DroidDesk) ---
# Темы адаптированы под пакеты Ubuntu 24.04: GTK — Greybird-dark
# (greybird-gtk-theme), иконки — Adwaita; xfce4-terminal 1.1+ читает
# terminalrc, а не xfconf.
msg "Настройка тёмной темы XFCE (Greybird-dark)..."
XFCONF_DIR="/root/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$XFCONF_DIR" /root/.config/xfce4/terminal

cat > "$XFCONF_DIR/xsettings.xml" << 'XSEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="96"/>
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 11"/>
    <property name="MonospaceFontName" type="string" value="Monospace 10"/>
    <property name="DecorationLayout" type="string" value="menu:minimize,maximize,close"/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="ButtonImages" type="bool" value="true"/>
  </property>
</channel>
XSEOF

# Композитинг выключен: целевые GPU — llvmpipe (Kirin/Mali без драйверов),
# см. митигации в docs/FORK-ARCHITECTURE.md.
cat > "$XFCONF_DIR/xfwm4.xml" << 'XWEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Greybird-dark"/>
    <property name="title_font" type="string" value="Sans Bold 10"/>
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XWEOF

cat > /root/.config/xfce4/terminal/terminalrc << 'TERMEOF'
[Configuration]
ColorForeground=#f8f8f2
ColorBackground=#282a36
ColorCursor=#f8f8f2
ColorPalette=#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff
FontName=Monospace 11
MiscCursorBlinks=TRUE
TERMEOF

# --- 7. start-desktop.sh → /usr/local/bin ---
msg "Установка /usr/local/bin/start-desktop.sh..."
[ -f /root/start-desktop.sh ] || die "Не найден /root/start-desktop.sh (должен скопировать ubuntu-setup.sh)."
install -m 0755 /root/start-desktop.sh /usr/local/bin/start-desktop.sh

echo
ok "postinstall завершён. Доступно:"
echo "    - XFCE (тёмная тема Greybird-dark), firefox-esr, локали ru/en"
echo "    - QwenPaw: /opt/qwenpaw/bin/qwenpaw + ярлык «QwenPaw Console»"

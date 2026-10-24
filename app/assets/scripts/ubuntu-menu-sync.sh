#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# UbuntuTab — ubuntu-menu-sync.sh
#
# Синхронизация приложений контейнера Ubuntu с лаунчером Flutter-оболочки
# (App Bridge, паттерн proot-menu-sync.sh из DroidDesk — но потребитель не
# XFCE-меню Termux, а общий каталог для приложения):
#
#   скан  $ROOTFS/usr/share/applications/*.desktop
#   →     $HOME/.local/share/ubuntutab/apps/apps.json   (манифест)
#   →     $HOME/.local/share/ubuntutab/apps/icons/<id>.(png|svg|xpm)
#
# Манифест apps.json: {"id","name","exec","terminal","icon"} — контракт для
# T2 (Flutter-лаунчер). Полная пересборка при каждом запуске (идемпотентно).
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
shopt -s nullglob

DISTRO="${1:-ubuntu-24.04}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"
APPS_DIR="$ROOTFS/usr/share/applications"
ICONS_ROOT="$ROOTFS/usr/share/icons"
PIXMAPS="$ROOTFS/usr/share/pixmaps"
OUT_DIR="$HOME/.local/share/ubuntutab/apps"
ICONS_OUT="$OUT_DIR/icons"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
msg()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[ОШИБКА]${NC} $*" >&2; exit 1; }
trap 'echo -e "${RED}[ОШИБКА]${NC} ubuntu-menu-sync.sh прерван (см. вывод выше)" >&2' ERR

[ -d "$PREFIX" ]        || die "Скрипт должен запускаться в Termux."
[ -d "$ROOTFS" ]        || die "Контейнер $DISTRO не установлен. Сначала: bash scripts/ubuntu-setup.sh"
if [ ! -d "$APPS_DIR" ]; then
    warn "В контейнере нет /usr/share/applications — синхронизировать нечего."
    exit 0
fi

mkdir -p "$OUT_DIR"
rm -rf "$ICONS_OUT"
mkdir -p "$ICONS_OUT"
ENTRIES="$(mktemp "${TMPDIR:-$PREFIX/tmp}/ubuntutab-menu.XXXXXX")"
trap 'rm -f "$ENTRIES"' EXIT

# Разрешение иконки: абсолютный путь контейнера (реальный файл лежит в
# $ROOTFS) | тема (PNG по убыванию размера, затем SVG) | /usr/share/pixmaps.
# Печатает путь или пусто.
resolve_icon() {
    local icon="$1" size cand
    if [[ "$icon" = /* ]]; then
        for cand in "$ROOTFS$icon" "$icon"; do
            if [ -f "$cand" ]; then
                printf '%s\n' "$cand"
                return 0
            fi
        done
        return 0
    fi
    for size in 256x256 512x512 128x128 96x96 64x64 48x48 32x32; do
        for cand in "$ICONS_ROOT"/*/"$size"/apps/"$icon".png; do
            printf '%s\n' "$cand"
            return 0
        done
    done
    for size in scalable 256x256 128x128 48x48; do
        for cand in "$ICONS_ROOT"/*/"$size"/apps/"$icon".svg; do
            printf '%s\n' "$cand"
            return 0
        done
    done
    for cand in "$PIXMAPS/$icon".png "$PIXMAPS/$icon".svg "$PIXMAPS/$icon".xpm; do
        if [ -f "$cand" ]; then
            printf '%s\n' "$cand"
            return 0
        fi
    done
    return 0
}

# Экранирование строковых значений для JSON
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g'
}

SYNCED=0
NO_ICON=0

for desktop_file in "$APPS_DIR"/*.desktop; do
    # Пропускаем скрытые записи
    grep -q '^NoDisplay=true' "$desktop_file" 2>/dev/null && continue
    grep -q '^Hidden=true'    "$desktop_file" 2>/dev/null && continue

    EXEC_RAW="$(grep -m1 '^Exec=' "$desktop_file" | sed 's/^Exec=//' || true)"
    [ -n "$EXEC_RAW" ] || continue
    # Убираем %-коды полей (%u, %f, ...) — лаунчеру нужна чистая команда
    EXEC_CLEAN="$(printf '%s' "$EXEC_RAW" | sed 's/ %[a-zA-Z]//g; s/%[a-zA-Z]//g')"

    ID="$(basename "$desktop_file" .desktop)"

    # Имя: предпочитаем локализованное русское, иначе дефолтное
    NAME="$(grep -m1 '^Name\[ru\]=' "$desktop_file" | sed 's/^Name\[ru\]=//' || true)"
    if [ -z "$NAME" ]; then
        NAME="$(grep -m1 '^Name=' "$desktop_file" | sed 's/^Name=//' || true)"
    fi
    [ -n "$NAME" ] || NAME="$ID"

    TERMINAL_FLAG=false
    grep -q '^Terminal=true' "$desktop_file" 2>/dev/null && TERMINAL_FLAG=true

    ICON_KEY="$(grep -m1 '^Icon=' "$desktop_file" | sed 's/^Icon=//' || true)"
    ICON_JSON="null"
    if [ -n "$ICON_KEY" ]; then
        ICON_SRC="$(resolve_icon "$ICON_KEY")"
        if [ -n "$ICON_SRC" ]; then
            ICON_EXT="${ICON_SRC##*.}"
            cp "$ICON_SRC" "$ICONS_OUT/$ID.$ICON_EXT"
            ICON_JSON="\"$(json_escape "$ID.$ICON_EXT")\""
        fi
    fi
    [ "$ICON_JSON" != "null" ] || NO_ICON=$((NO_ICON + 1))

    printf '{"id":"%s","name":"%s","exec":"%s","terminal":%s,"icon":%s}\n' \
        "$(json_escape "$ID")" \
        "$(json_escape "$NAME")" \
        "$(json_escape "$EXEC_CLEAN")" \
        "$TERMINAL_FLAG" \
        "$ICON_JSON" \
        >> "$ENTRIES"
    SYNCED=$((SYNCED + 1))
done

# Сборка apps.json (записи через запятую)
{
    printf '{\n  "generated": "%s",\n  "distro": "%s",\n  "apps": [\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        "$(json_escape "$DISTRO")"
    awk 'NR > 1 { printf ",\n" } { printf "    %s", $0 }' "$ENTRIES"
    printf '\n  ]\n}\n'
} > "$OUT_DIR/apps.json"

ok "Синхронизировано приложений: $SYNCED (без иконки: $NO_ICON)."
echo "    Манифест: $OUT_DIR/apps.json"
echo "    Иконки:   $ICONS_OUT"
echo "    Повторяйте после установки новых пакетов: bash ~/ubuntu-menu-sync.sh"
